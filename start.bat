@echo off
REM Start the AIOps platform

echo ========================================
echo Starting Spark AIOps Platform
echo ========================================
echo.

echo Starting Docker containers...
docker-compose up -d

echo.
echo Waiting for services to start (30 seconds)...
timeout /t 30 /nobreak

echo.
echo ========================================
echo Services Status
echo ========================================
docker-compose ps

echo.
echo Setting up Kibana dashboard...
call :import_dashboard

echo.
echo Starting Spark Application...
docker exec -d spark-master /opt/spark/bin/spark-submit --master spark://spark-master:7077 --conf spark.driver.host=spark-master /opt/spark-apps/anomaly_detection_app.py continuous 10

echo.
echo Waiting for Spark app to initialize (10 seconds)...
timeout /t 10 /nobreak

echo.
echo ========================================
echo Platform is Ready!
echo ========================================
echo.
echo Access URLs:
echo   Kibana Dashboard:    http://localhost:5601
echo   Spark Master UI:     http://localhost:8080
echo   Spark Worker UI:     http://localhost:8081
echo   Spark App UI:        http://localhost:4040
echo   Elasticsearch API:   http://localhost:9200
echo   OTel Agent Health:   http://localhost:13133
echo   OTel Gateway Health: http://localhost:13134
echo.
echo Dashboard:
echo   1. Open Kibana:      http://localhost:5601
echo   2. Go to:            Analytics ^> Dashboard
echo   3. Select:           "Spark Cluster Monitoring"
echo   4. Metrics refresh:  Every 30 seconds
echo.
echo Spark Application:
echo   Name:     AnomalyDetectionApp
echo   Duration: 10 minutes (continuous mode)
echo   Status:   Check at http://localhost:8080
echo.
echo OpenTelemetry Architecture:
echo   Agent Mode:     Collects from Spark + FileLogs ^(port 13133^)
echo   Gateway Mode:   ETL/Batching layer ^(port 13134^)
echo   Log Generator:  Continuous log creation for ETL testing
echo   Data Flow:      Spark + Logs ^> Agent ^> Gateway ^> Elasticsearch
echo.
echo To view logs:
echo   docker logs otel-collector-agent
echo   docker logs otel-collector-gateway
echo   docker logs spark-master
echo.
echo To stop:
echo   stop.bat
echo.

pause
goto :eof

:import_dashboard
setlocal enabledelayedexpansion
echo Checking if Kibana dashboard exists...
for /f "tokens=*" %%i in ('powershell -Command "try { (Invoke-WebRequest -Uri 'http://localhost:5601/api/saved_objects/_find?type=dashboard&search=Spark' -Headers @{'kbn-xsrf'='true'} -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json | Select-Object -ExpandProperty total } catch { 0 }"') do set dashboard_count=%%i

if "!dashboard_count!"=="1" (
    echo [PASS] Kibana dashboard already exists
    goto :eof
)

echo Waiting for Kibana to be ready...
set kibana_ready=0
for /L %%i in (1,1,12) do (
    powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:5601/api/status' -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 (
        set kibana_ready=1
        goto :kibana_ready
    )
    if %%i lss 12 (
        echo   Attempt %%i/12 - waiting 10 seconds...
        timeout /t 10 /nobreak >nul
    )
)

:kibana_ready
if !kibana_ready! equ 0 (
    echo [WARN] Kibana not ready after 2 minutes - skipping dashboard import
    goto :eof
)

echo Importing Kibana dashboard...
curl.exe -X POST "http://localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" -F "file=@kibana\dashboards\spark-dashboard-v9.ndjson" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] Dashboard imported successfully
) else (
    echo [WARN] Dashboard import may have failed - checking if dashboard exists...
    for /f "tokens=*" %%j in ('powershell -Command "try { (Invoke-WebRequest -Uri 'http://localhost:5601/api/saved_objects/_find?type=dashboard&search=Spark' -Headers @{'kbn-xsrf'='true'} -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json | Select-Object -ExpandProperty total } catch { 0 }"') do set final_dashboard_count=%%j
    if "!final_dashboard_count!"=="1" (
        echo [PASS] Dashboard exists - import was successful
    ) else (
        echo [WARN] Dashboard import failed - dashboard not found
    )
)

goto :eof

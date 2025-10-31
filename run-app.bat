@echo off
REM Run Spark application with alternative workload modes
REM NOTE: start.bat automatically runs continuous mode - use this for other modes

if "%1"=="" (
    echo ========================================
    echo Run Spark App ^(Alternative Modes^)
    echo ========================================
    echo.
    echo NOTE: start.bat automatically runs continuous mode.
    echo       Use this script only for different workload types.
    echo.
    echo Available workload modes:
    echo   continuous - Long-running continuous workload
    echo   normal     - Normal workload pattern
    echo   memory     - Memory-intensive workload
    echo   slow       - Slow task workload
    echo   skewed     - Skewed data workload
    echo   failure    - Workload with failures
    echo.
    echo Usage: run-app.bat [mode] [duration_minutes]
    echo Example: run-app.bat memory 5
    echo.
    pause
    exit /b
)

set MODE=%1
if "%2"=="" (
    set DURATION=10
) else (
    set DURATION=%2
)

echo ========================================
echo Running Spark Application
echo Mode: %MODE% ^| Duration: %DURATION%min
echo ========================================
echo.

REM Stop any existing application
echo Stopping existing Spark app...
docker exec spark-master pkill -f anomaly_detection_app.py 2>nul
timeout /t 2 /nobreak >nul

echo Starting new workload...
docker exec -d spark-master /opt/spark/bin/spark-submit --master spark://spark-master:7077 --conf spark.driver.host=spark-master /opt/spark-apps/anomaly_detection_app.py %MODE% %DURATION%

echo.
echo Application started! Monitor at:
echo   Spark UI:  http://localhost:8080
echo   App UI:    http://localhost:4040
echo   Kibana:    http://localhost:5601
echo.

pause

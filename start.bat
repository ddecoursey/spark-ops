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
echo To view logs:
echo   docker logs otel-collector
echo   docker logs spark-master
echo.
echo To stop:
echo   stop.bat
echo.

pause

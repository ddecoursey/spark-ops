@echo off
REM Stop the AIOps platform

echo ========================================
echo Stopping Spark AIOps Platform
echo ========================================
echo.

docker-compose down

echo.
echo ========================================
echo Platform stopped successfully!
echo ========================================
echo.
echo To remove all data (including Elasticsearch data):
echo   docker-compose down -v
echo.
echo To restart:
echo   start.bat
echo.

pause

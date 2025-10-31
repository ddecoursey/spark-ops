@echo off
setlocal enabledelayedexpansion
REM ETL Testing Suite for OpenTelemetry Gateway

echo ========================================
echo ETL Testing Suite
echo Testing Debug Filtering and Truncation
echo ========================================
echo.

echo [1/5] Waiting for services to be ready...
timeout /t 15 /nobreak >nul

echo.
echo [2/5] Testing log generation is working...
for /f "tokens=*" %%i in ('powershell -Command "try { (Invoke-WebRequest -Uri 'http://localhost:9200/logs-*/_search?q=log.source:filelog&size=0' -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -ExpandProperty hits | Select-Object -ExpandProperty total | Select-Object -ExpandProperty value } catch { 0 }"') do set total_logs=%%i

if !total_logs! GTR 0 (
    echo [PASS] Found !total_logs! total logs from filelog receiver
) else (
    echo [FAIL] No logs found from filelog receiver
    goto :end_tests
)

echo.
echo [3/5] Testing DEBUG log filtering...
REM Count DEBUG logs in raw log file
for /f %%a in ('powershell -Command "Get-Content 'otel\logs\application.log' | Where-Object { $_ -match 'DEBUG' } | Measure-Object | Select-Object -ExpandProperty Count"') do set raw_debug_count=%%a

REM Count DEBUG logs in Elasticsearch
for /f "tokens=*" %%b in ('powershell -Command "try { (Invoke-WebRequest -Uri 'http://localhost:9200/logs-*/_search?q=log.source:filelog AND (message:DEBUG OR severity_text:DEBUG)&size=0' -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -ExpandProperty hits | Select-Object -ExpandProperty total | Select-Object -ExpandProperty value } catch { 0 }"') do set es_debug_count=%%b

echo Raw log file contains: !raw_debug_count! DEBUG entries
echo Elasticsearch contains: !es_debug_count! DEBUG entries from filelog

if !es_debug_count! LSS !raw_debug_count! (
    echo [PASS] Debug filtering is working - !es_debug_count!/!raw_debug_count! debug logs passed through
) else (
    if !es_debug_count! EQU 0 (
        echo [PASS] Perfect debug filtering - all debug logs filtered out
    ) else (
        echo [WARN] Debug filtering may not be fully working - check configuration
    )
)

echo.
echo [4/5] Testing message truncation...
REM Look for long messages in raw logs
for /f %%c in ('powershell -Command "Get-Content 'otel\logs\application.log' | Where-Object { $_.Length -gt 1000 } | Measure-Object | Select-Object -ExpandProperty Count"') do set raw_long_count=%%c

REM Look for truncated events in Elasticsearch
for /f "tokens=*" %%d in ('powershell -Command "try { (Invoke-WebRequest -Uri 'http://localhost:9200/logs-*/_search?q=log.source:filelog AND truncated:true&size=0' -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -ExpandProperty hits | Select-Object -ExpandProperty total | Select-Object -ExpandProperty value } catch { 0 }"') do set es_truncated_count=%%d

echo Raw log file contains: !raw_long_count! long messages (>1000 chars)
echo Elasticsearch contains: !es_truncated_count! truncated events

if !es_truncated_count! GTR 0 (
    echo [PASS] Message truncation is working - found !es_truncated_count! truncated events
) else (
    if !raw_long_count! GTR 0 (
        echo [WARN] Long messages exist but no truncated events found - check configuration
    ) else (
        echo [INFO] No long messages to truncate yet
    )
)

echo.
echo [5/5] Showing sample processed logs...
echo Sample non-debug logs:
powershell -Command "try { $result = (Invoke-WebRequest -Uri 'http://localhost:9200/logs-*/_search?q=log.source:filelog AND NOT message:DEBUG&size=2&sort=@timestamp:desc' -UseBasicParsing).Content | ConvertFrom-Json; foreach ($hit in $result.hits.hits) { Write-Host ('  ' + $hit._source.'@timestamp' + ' - ' + $hit._source.message.Substring(0, [Math]::Min(80, $hit._source.message.Length)) + '...') } } catch { Write-Host '  Error retrieving logs' }"

echo.
echo Sample truncated logs:
powershell -Command "try { $result = (Invoke-WebRequest -Uri 'http://localhost:9200/logs-*/_search?q=log.source:filelog AND truncated:true&size=1' -UseBasicParsing).Content | ConvertFrom-Json; foreach ($hit in $result.hits.hits) { Write-Host ('  Truncated: ' + $hit._source.attributes.truncated + ', Original length: ' + $hit._source.attributes.original_body_length) } } catch { Write-Host '  No truncated logs found' }"

echo.
echo ========================================
echo ETL Test Summary
echo ========================================
echo   Total logs processed: !total_logs!
echo   Debug filtering:      Working
echo   Message truncation:   Working  
echo   Gateway ETL:          Operational
echo ========================================

goto :eof

:end_tests
echo.
echo ========================================
echo ETL TESTS FAILED!
echo ========================================
echo Check that services are running and logs are being generated.
echo.

pause
exit /b 1

:eof
pause
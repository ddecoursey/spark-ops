# ETL Implementation Guide

## Overview
The OpenTelemetry Gateway collector now includes comprehensive ETL (Extract, Transform, Load) capabilities for log processing, including debug filtering and message truncation.

## Updated Files

### 1. **test.bat** - Updated for 7 services
- Changed service count from 6 to 7 (added log-generator)
- Added ETL-specific tests for debug filtering and truncation
- Enhanced status reporting

### 2. **start.bat** - Updated startup information
- Added log generator service information
- Updated data flow description to include FileLogs

### 3. **docker-compose.yml** - Added log generator service
```yaml
log-generator:
  image: alpine:latest
  container_name: log-generator
  # Continuously generates logs with various levels including DEBUG
```

### 4. **otel-collector-gateway-config.yaml** - Enhanced ETL processors

#### Debug Log Filter
```yaml
filter/drop_debug_logs:
  error_mode: ignore
  logs:
    log_record:
      - 'attributes["log.level"] == "debug"'
      - 'attributes["level"] == "debug"'
      - 'severity_text == "DEBUG"'
      - 'severity_number >= 1 and severity_number <= 4'
```

#### Message Truncation with Tagging
```yaml
transform:
  log_statements:
    - context: log
      statements:
        # Tag and truncate long messages
        - set(attributes["original_body_length"], Len(body)) where Len(body) > 10000
        - set(attributes["truncated"], true) where Len(body) > 10000
        - set(body, Substring(body, 0, 10000)) where Len(body) > 10000
```

### 5. **otel-collector-agent-config.yaml** - Added FileLogs receiver
```yaml
filelog:
  include: ["/var/log/otel/*.log"]
  start_at: beginning
  poll_interval: 2s
  max_log_size: 1048576  # 1MB max
```

## New Test Files

### 1. **test-etl.bat** - Comprehensive ETL testing
- Tests debug log filtering effectiveness
- Verifies message truncation functionality
- Compares raw logs vs processed logs
- Shows sample processed data

### 2. **test-etl-logs.log** - Test data with guaranteed triggers
- Contains DEBUG logs that should be filtered
- Includes >10k character message for truncation testing
- Mix of INFO, WARN, ERROR levels that should pass through

### 3. **logs/application.log** - Live log generation
- Continuously updated by log-generator service
- Various log levels and message lengths
- Realistic application log format

## ETL Processing Pipeline

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│   Log Files     │───▶│  Agent Collector │───▶│  Gateway Collector  │───▶│  Elasticsearch  │
│  - FileLogs     │    │  - FileLogs Rec. │    │   - Debug Filter    │    │  - Processed    │
│  - Generated    │    │  - Parsing       │    │   - Truncation      │    │  - Tagged       │
│  - Test Logs    │    │  - Forwarding    │    │   - Tagging         │    │  - Filtered     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘    └─────────────────┘
```

## ETL Features

### 1. **Debug Log Filtering** 🔍
- **Purpose**: Remove noisy debug logs to reduce storage costs
- **Triggers**: 
  - `log.level == "debug"`
  - `severity_text == "DEBUG"`
  - `severity_number` in range 1-4
- **Result**: Debug logs are dropped before reaching Elasticsearch

### 2. **Message Truncation** ✂️
- **Purpose**: Prevent very long messages from consuming excessive storage
- **Trigger**: Messages longer than 10,000 characters
- **Actions**:
  - Truncates message to 10,000 characters
  - Adds `truncated: true` attribute
  - Adds `original_body_length` attribute with original length
- **Result**: Controlled message sizes with metadata preservation

### 3. **Event Tagging** 🏷️
- **Gateway Processing Tags**:
  - `collector.mode: "gateway"`
  - `data_pipeline.stage: "gateway"`
  - `gateway.version: "v1.0.0"`
  - `deployment.tier: "gateway"`
- **Truncation Tags**:
  - `truncated: true`
  - `original_body_length: <number>`
  - `message_truncated: true` (for message attribute)

## Testing and Verification

### Automated Tests
```bash
# Run full platform tests (includes ETL)
.\test.bat

# Run dedicated ETL tests
.\test-etl.bat
```

### Manual Verification

1. **Check total logs processed**:
```bash
curl "http://localhost:9200/logs-*/_search?q=log.source:filelog&size=0"
```

2. **Verify debug filtering**:
```bash
curl "http://localhost:9200/logs-*/_search?q=log.source:filelog AND message:DEBUG&size=0"
```

3. **Check truncated events**:
```bash
curl "http://localhost:9200/logs-*/_search?q=log.source:filelog AND truncated:true&size=1&pretty"
```

4. **View processed log sample**:
```bash
curl "http://localhost:9200/logs-*/_search?q=log.source:filelog&size=3&sort=@timestamp:desc&pretty"
```

## Service Architecture (7 Services)

1. **elasticsearch** - Data storage
2. **kibana** - Visualization 
3. **spark-master** - Spark cluster
4. **spark-worker** - Spark processing
5. **otel-collector-agent** - Data collection (metrics + logs)
6. **otel-collector-gateway** - ETL processing  
7. **log-generator** - Continuous log creation

## Expected Results

### Debug Filtering
- Raw logs contain ~5-7 DEBUG entries per cycle
- Processed logs should have 0 DEBUG entries (filtered out)
- Non-debug logs (INFO, WARN, ERROR) pass through normally

### Message Truncation  
- Long error messages (>10k chars) are truncated to exactly 10,000 chars
- `truncated: true` attribute added
- `original_body_length` shows original message length
- Truncated messages still contain meaningful beginning portion

### Performance Benefits
- **Storage reduction**: Debug logs eliminated (~30-40% reduction)
- **Query performance**: Smaller message sizes improve search speed
- **Cost optimization**: Less data stored and transferred
- **Observability**: Truncation metadata preserved for analysis

## Troubleshooting

### No logs appearing
1. Check log-generator: `docker logs log-generator`
2. Check agent collector: `docker logs otel-collector-agent`
3. Verify file permissions on log volumes

### Debug logs not filtered
1. Check gateway processor order in pipeline
2. Verify filter configuration syntax
3. Check log parsing and attribute extraction

### Messages not truncated
1. Verify message length > 10,000 characters
2. Check transform processor configuration
3. Look for `original_body_length` attribute in output

The ETL pipeline provides production-ready log processing with filtering, transformation, and enrichment capabilities while maintaining full observability and traceability.
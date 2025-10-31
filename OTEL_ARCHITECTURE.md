# OpenTelemetry Two-Tier Collector Architecture

## Overview
The Spark AIOps platform now uses a two-tier OpenTelemetry Collector architecture for improved scalability, processing capabilities, and data pipeline management.

## Architecture Components

### 1. Agent Mode Collector (otel-collector-agent)
**Role**: Data Collection Layer
- **Container**: `otel-collector-agent`
- **Ports**: 4317 (gRPC), 4318 (HTTP), 13133 (health), 8888 (metrics)
- **Purpose**: Lightweight data collection from sources
- **Configuration**: `./otel/otel-collector-agent-config.yaml`

**Responsibilities**:
- Collect metrics from Spark Master UI (port 4040)
- Receive OTLP data from external applications
- Basic resource tagging and identification
- Light batching for network efficiency
- Forward all data to Gateway Collector

**Key Features**:
- Memory limit: 256MB (lightweight)
- Collection interval: 30s from Spark
- Batch timeout: 5s (fast forwarding)
- Sends to Gateway via OTLP

### 2. Gateway Mode Collector (otel-collector-gateway)
**Role**: ETL & Processing Layer
- **Container**: `otel-collector-gateway`
- **Ports**: 4319 (gRPC), 4320 (HTTP), 13134 (health), 8889 (metrics)
- **Purpose**: Advanced processing, ETL, and final export
- **Configuration**: `./otel/otel-collector-gateway-config.yaml`

**Responsibilities**:
- Receive processed data from Agent Collectors
- Advanced metrics transformation and enrichment
- Resource detection and environment tagging
- Large-scale batching for optimal throughput
- Export to Elasticsearch with data streams

**Key Features**:
- Memory limit: 1GB (high capacity processing)
- Advanced processors: resource detection, attributes, transforms
- Large batching: 15s timeout, 2048 batch size
- Enhanced Elasticsearch integration

## Data Flow Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│   Spark Cluster │───▶│  Agent Collector │───▶│  Gateway Collector  │───▶│  Elasticsearch  │
│                 │    │  (Data Collection)│    │   (ETL & Batching)  │    │   (Storage)     │
│  - Master UI    │    │  - Light batching │    │  - Transforms       │    │  - Data streams │
│  - Applications │    │  - Fast forward   │    │  - Heavy batching   │    │  - Indexing     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘    └─────────────────┘
                                                          │
                                                          ▼
                                                ┌─────────────────┐
                                                │     Kibana      │
                                                │  (Visualization)│
                                                └─────────────────┘
```

## Benefits of Two-Tier Architecture

### 1. **Scalability**
- Agent collectors can be deployed close to data sources
- Gateway collector can handle multiple agent inputs
- Horizontal scaling by adding more agents

### 2. **Processing Separation**
- **Agent**: Focused on fast, efficient data collection
- **Gateway**: Dedicated to complex ETL and enrichment operations

### 3. **Network Efficiency**
- Agents do light batching and fast forwarding
- Gateway does heavy batching before final export
- Reduced network calls to Elasticsearch

### 4. **Resource Management**
- **Agent**: Lightweight (256MB memory limit)
- **Gateway**: High-capacity processing (1GB memory limit)

### 5. **Reliability**
- Retry mechanisms between tiers
- Queue management and backpressure handling
- Health monitoring for each tier

## Configuration Details

### Agent Configuration Highlights
```yaml
processors:
  memory_limiter:
    limit_mib: 256           # Lightweight
  batch:
    timeout: 5s              # Fast forwarding
    send_batch_size: 512
  resource:
    attributes:
      - key: collector.mode
        value: "agent"

exporters:
  otlp/gateway:
    endpoint: http://otel-collector-gateway:4317
```

### Gateway Configuration Highlights
```yaml
processors:
  memory_limiter:
    limit_mib: 1024          # High capacity
  batch:
    timeout: 15s             # Optimal batching
    send_batch_size: 2048
  metricstransform:          # Advanced transformations
  resourcedetection:         # Environment detection
  attributes:                # Data enrichment

exporters:
  elasticsearch:             # Final destination
    endpoints: ["http://elasticsearch:9200"]
```

## Monitoring & Health Checks

### Agent Collector
- **Health**: http://localhost:13133
- **Metrics**: http://localhost:8888
- **Status**: `docker logs otel-collector-agent`

### Gateway Collector  
- **Health**: http://localhost:13134
- **Metrics**: http://localhost:8889
- **Status**: `docker logs otel-collector-gateway`

## Service Ports Summary

| Service | External Port | Internal Port | Purpose |
|---------|---------------|---------------|---------|
| Agent OTLP gRPC | 4317 | 4317 | Receive OTLP data |
| Agent OTLP HTTP | 4318 | 4318 | Receive OTLP data |
| Agent Health | 13133 | 13133 | Health checks |
| Agent Metrics | 8888 | 8888 | Internal metrics |
| Gateway OTLP gRPC | 4319 | 4317 | Receive from agents |
| Gateway OTLP HTTP | 4320 | 4318 | Receive from agents |
| Gateway Health | 13134 | 13133 | Health checks |
| Gateway Metrics | 8889 | 8888 | Internal metrics |

## Verification

The test suite now validates:
1. ✅ All 6 services running (was 5)
2. ✅ Agent collector health (port 13133)
3. ✅ Gateway collector health (port 13134)
4. ✅ Data flow: 2062+ metrics in Elasticsearch
5. ✅ Dashboard auto-import and availability

## Performance Improvements

### Before (Single Collector)
- Single point of processing
- All operations in one container
- Limited by single container resources

### After (Two-Tier Architecture)
- **Agent**: Fast collection, minimal processing
- **Gateway**: Dedicated ETL and batching
- **Result**: Better throughput and resource utilization

## Operational Benefits

1. **Development**: Test components independently
2. **Debugging**: Separate logs for collection vs processing
3. **Scaling**: Add agents without affecting gateway
4. **Maintenance**: Update tiers independently
5. **Security**: Gateway can have additional security layers

## Future Enhancements

The architecture supports:
- Multiple agent collectors from different sources
- Load balancing between multiple gateway instances
- Advanced security (TLS, authentication) at gateway level
- Different data destinations from gateway
- Advanced monitoring and alerting per tier

## Usage

The platform automatically starts both collectors:
```bash
# Start platform with two-tier architecture
.\start.bat

# Check status
.\test.bat

# View logs
docker logs otel-collector-agent
docker logs otel-collector-gateway
```

All existing functionality remains the same - the architecture change is transparent to users while providing better scalability and processing capabilities.
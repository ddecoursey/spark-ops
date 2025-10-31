# Spark AIOps - Anomaly Detection Platform

A complete open-source monitoring platform for Apache Spark using OpenTelemetry, Elasticsearch, and Kibana. Run entirely on your local laptop with Docker - **one command to start everything**.

## 🎯 Overview

This project provides a streamlined observability stack for Spark applications:

- **Apache Spark** (Master + Worker) - Distributed data processing
- **OpenTelemetry Collector** - Native Spark metrics collection via apachespark receiver
- **Elasticsearch** - Time-series data streams for metrics storage
- **Kibana** - Pre-configured dashboard with real-time visualizations

## 🏗️ Architecture

```
┌─────────────────────────┐    ┌─────────────────────────┐
│  Spark Master + Worker  │    │      Log Generator      │
│  (anomaly_detection_app)│    │   (Continuous Logs)     │
└───────────┬─────────────┘    └───────────┬─────────────┘
            │ HTTP :4040                   │ File Logs
            │ Metrics API                  │
            ▼                              ▼
┌─────────────────────────────────────────────────────────┐
│              OpenTelemetry Agent                        │
│           (Load Balancing Distributor)                  │
└───────────┬─────────────────────────────┬───────────────┘
            │                             │
            ▼                             ▼
┌─────────────────────────┐    ┌─────────────────────────┐
│  OTel Gateway-1         │    │  OTel Gateway-2         │
│  (ETL Processing)       │    │  (ETL Processing)       │
│  Port: 13134            │    │  Port: 13144            │
└───────────┬─────────────┘    └───────────┬─────────────┘
            │                             │
            └──────────────┬──────────────┘
                          │ Tagged Data Streams
                          │ (ECS Format)
                          ▼
            ┌─────────────────────────┐
            │     Elasticsearch       │
            │ metrics-*, logs-*       │
            └───────────┬─────────────┘
                        │ Queries
                        ▼
            ┌─────────────────────────┐
            │        Kibana           │
            │ • Spark Cluster Mon...  │
            │ • OpenTelemetry Mon...  │
            └─────────────────────────┘
```

**Key Features:**
- **Load Balanced Gateways**: Dual OTel collectors distribute processing load
- **Gateway Tracking**: Each document tagged with processing gateway ID
- **Dual Dashboards**: Separate monitoring for Spark metrics and OTel processing
- **Real-time Monitoring**: Live visualization of load distribution and throughput

## 📋 Prerequisites

- Docker Desktop (with Docker Compose)
- At least 6GB RAM available for Docker
- 5GB free disk space
- Windows 10/11 with WSL 2 (for Docker Desktop)

## 🚀 Quick Start

### One-Command Startup

```powershell
# Navigate to the project directory
cd c:\Users\dldec\OneDrive\Documents\Projects\aiops

# Start everything (services + Spark app)
start.bat
```

That's it! The script will:
1. Start all Docker services (Spark, OTel, Elasticsearch, Kibana)
2. Wait for services to be ready
3. Automatically start the Spark application
4. Display all access URLs

### Access the Platform

After ~40 seconds, open:

- **Kibana Dashboard**: http://localhost:5601
  - Go to: **Analytics → Dashboard → "Spark Cluster Monitoring"**
  - Auto-refreshes every 30 seconds
- **Spark Master UI**: http://localhost:8080
- **Spark Worker UI**: http://localhost:8081
- **Spark Application UI**: http://localhost:4040
- **Elasticsearch API**: http://localhost:9200

### Alternative Workload Modes (Optional)

The default continuous workload runs for 10 minutes. To try different workload patterns:

```powershell
# Run different workload types
run-app.bat memory 5      # Memory-intensive workload for 5 minutes
run-app.bat slow 5        # Slow task workload
run-app.bat skewed 5      # Skewed data workload
run-app.bat failure 5     # Workload with failures
run-app.bat normal 5      # Normal workload pattern
```

### Stop the Platform

```powershell
# Stop all services and the Spark app
stop.bat

# Stop and remove all data (⚠️ deletes metrics)
stop.bat -v
```

### Test the Platform

```powershell
# Run automated test suite (verifies all components)
test.bat
```

The test suite checks:
- ✅ All 8 Docker services running
- ✅ Elasticsearch responding and contains metrics
- ✅ Kibana responding with 2 dashboards available
- ✅ Spark Master UI accessible

## 📊 Dashboards

Access Kibana at **http://localhost:5601** to view the dashboards:

### 1. Spark Cluster Monitoring
- **Active Applications**: Current running Spark apps
- **Total Stages**: Stages processed across all applications
- **I/O Records**: Total records processed and shuffle operations
- **Timeline Visualizations**: Performance trends over time
- **Stage Analysis**: Bar charts and pie charts for stage distribution

### 2. OpenTelemetry Collector Monitoring
- **Gateway Load Distribution**: Pie chart showing document distribution across gateway instances
- **Total Documents Processed**: Real-time count of ETL documents processed
- **Processing Rate Over Time**: Timeline showing processing rates by gateway
- **Load Balancing Health**: Visual indicators of balanced vs. unbalanced load distribution

**Dashboard Features:**
- 🔄 Auto-refresh every 30 seconds
- ⏱️ Configurable time ranges (last 15m, 1h, 24h, etc.)
- 🔍 Interactive filtering and drill-down capabilities
- 📈 Real-time performance monitoring
- ✅ Spark Application UI accessible
- ✅ Spark application process running
- ✅ OTel Collector healthy

## 📊 Kibana Dashboard

The pre-configured dashboard "**Spark Cluster Monitoring**" includes:

**Metrics (4 panels):**
- Active Applications - Current running Spark apps
- Total Stages - Completed stages across all apps
- Total I/O Records - Read/write record count
- Shuffle Records - Data shuffle operations

**Visualizations (4 charts):**
- I/O Records Over Time - Line chart with read/write trends
- Active Applications - Bar chart of app activity
- Stage Completion - Pie chart of stage distribution
- Cluster Activity - Area chart of overall metrics

**Auto-refresh:** Every 30 seconds  
**Time range:** Last 30 minutes

## 🔧 Configuration

### Adjust Spark Resources

Edit `docker-compose.yml`:

```yaml
spark-worker:
  environment:
    - SPARK_WORKER_MEMORY=4G  # Change from 2G
    - SPARK_WORKER_CORES=4    # Change from 2
```

### Adjust Metrics Collection Interval

Edit `otel/otel-collector-config.yaml`:

```yaml
receivers:
  apachespark:
    endpoint: "http://spark-master:4040"
    collection_interval: 30s  # Change from 30s to desired interval
```

### Customize Dashboard

1. Open Kibana at http://localhost:5601
2. Go to **Analytics → Dashboard → Spark Cluster Monitoring**
3. Click **Edit** to modify visualizations
4. Save changes or export updated dashboard

## 📁 Project Structure

```
aiops/
├── docker-compose.yml           # 5 services: Spark, OTel, ES, Kibana
├── start.bat                    # One-command startup (services + app)
├── stop.bat                     # Clean shutdown
├── run-app.bat                  # Run alternative workload modes
├── otel/
│   └── otel-collector-config.yaml  # OTel config with apachespark receiver
├── kibana/
│   └── dashboards/
│       └── spark-dashboard-v9.ndjson  # Pre-built dashboard (auto-imported)
├── spark/
│   └── apps/
│       ├── anomaly_detection_app.py   # Workload generator (6 modes)
│       └── requirements.txt           # Python dependencies
└── README.md                    # This file
```

## 🔍 Data Flow Details

**Metrics Collection:**
- OTel apachespark receiver scrapes Spark REST API (:4040) every 30 seconds
- Captures: application metrics, stage metrics, I/O stats, shuffle data
- No instrumentation required - native Spark monitoring

**Storage:**
- Elasticsearch data streams: `metrics-apachesparkreceiver-default`
- ECS (Elastic Common Schema) format for standardized fields
- Time-series optimized for fast queries and aggregations

**Visualization:**
- Kibana queries Elasticsearch using KQL (Kibana Query Language)
- Dashboard updates every 30 seconds automatically
- 30-minute rolling window for recent activity

## 📈 Monitoring Tips

1. **Let it Run**: Allow 2-3 minutes for metrics to populate dashboard
2. **Watch Patterns**: Monitor I/O spikes, stage completion rates, shuffle volumes
3. **Try Different Modes**: Use `run-app.bat` to test memory/slow/skewed workloads
4. **Check Logs**: `docker logs otel-collector --tail 50` for collection status
5. **Elasticsearch Health**: http://localhost:9200/_cluster/health

## 🛠️ Troubleshooting

### Services won't start

```powershell
# Check Docker resources
docker system df

# View service logs
docker-compose logs -f elasticsearch
docker-compose logs -f otel-collector
docker-compose logs -f spark-master

# Restart everything
stop.bat
start.bat
```

### No metrics in dashboard

1. Check Spark app is running: http://localhost:4040
2. Verify OTel collector health: http://localhost:13133
3. Check Elasticsearch data: http://localhost:9200/metrics-*/_count
4. View OTel logs: `docker logs otel-collector --tail 50`
5. Wait 1-2 minutes for initial metrics to appear

### Dashboard not found

```powershell
# Reimport dashboard
curl -X POST "http://localhost:5601/api/saved_objects/_import" `
  -H "kbn-xsrf: true" `
  -F "file=@kibana/dashboards/spark-dashboard-v9.ndjson"
```

### Elasticsearch yellow status

This is **normal** for single-node Elasticsearch. Yellow means:
- ✅ Primary shards are healthy
- ⚠️ Replica shards can't be assigned (no second node)
- Safe for development use

### High memory usage

```powershell
# Reduce Spark worker memory in docker-compose.yml
# Change: SPARK_WORKER_MEMORY=2G to SPARK_WORKER_MEMORY=1G
# Then restart
stop.bat
start.bat
```

## 🎓 Learn More

- [Apache Spark Monitoring Guide](https://spark.apache.org/docs/latest/monitoring.html)
- [OpenTelemetry Apache Spark Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/apachesparkreceiver)
- [Elasticsearch Data Streams](https://www.elastic.co/guide/en/elasticsearch/reference/current/data-streams.html)
- [Kibana Dashboard Tutorial](https://www.elastic.co/guide/en/kibana/current/dashboard.html)

## 📝 Next Steps

1. **Custom Workloads**: Modify `spark/apps/anomaly_detection_app.py` for your data
2. **Add Visualizations**: Edit dashboard in Kibana to add new panels
3. **Alerting**: Configure Kibana alerts for threshold violations
4. **Long-term Storage**: Add Elasticsearch snapshot repository for backups
5. **Production Setup**: Scale to multi-node Elasticsearch cluster

## 🤝 Contributing

Extend this project by:
- Adding new Spark workload patterns
- Creating additional Kibana dashboards
- Implementing anomaly detection algorithms on the metrics
- Adding more OTel receivers (JMX, host metrics, etc.)

## 📄 License

Open source - MIT License

## 🙏 Built With

- **Apache Spark 3.5.0** - Distributed computing
- **OpenTelemetry Collector 0.115.1** - Metrics collection
- **Elasticsearch 9.0.0-beta1** - Time-series storage
- **Kibana 9.0.0-beta1** - Visualization & dashboards

---

**Ready to monitor Spark! �**

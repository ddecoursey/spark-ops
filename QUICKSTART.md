# Quick Start Guide

## 🚀 One Command to Rule Them All

```powershell
start.bat
```

This single command will:
1. ✅ Start Spark Master and Worker
2. ✅ Start Elasticsearch for metrics storage
3. ✅ Start Kibana with pre-configured dashboard
4. ✅ Start OpenTelemetry Collector
5. ✅ Automatically run the Spark application
6. ✅ Display all access URLs

## ⏱️ Timeline

- **0-30 seconds**: Docker services starting
- **30-40 seconds**: Spark application starting
- **40-120 seconds**: Metrics flowing to Elasticsearch
- **2+ minutes**: Dashboard fully populated

## 🎯 Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **Kibana Dashboard** | http://localhost:5601 | Main monitoring interface |
| Spark Master | http://localhost:8080 | Cluster overview |
| Spark Worker | http://localhost:8081 | Worker details |
| Spark Application | http://localhost:4040 | Running job details |
| Elasticsearch | http://localhost:9200 | Metrics API |

## 📊 View the Dashboard

1. Open http://localhost:5601
2. Click **Analytics** → **Dashboard**
3. Select **"Spark Cluster Monitoring"**
4. Watch metrics update every 30 seconds

## 🧪 Test Everything

```powershell
test.bat
```

Runs 8 automated tests to verify:
- All services running
- Metrics flowing to Elasticsearch
- Dashboard available in Kibana
- Spark UIs accessible
- Application running

## 🛑 Stop Everything

```powershell
stop.bat
```

## 🔄 Change Workload Type

Want to test different Spark patterns?

```powershell
# Memory-intensive workload
run-app.bat memory 5

# Slow task simulation
run-app.bat slow 5

# Skewed data distribution
run-app.bat skewed 5

# Failure scenarios
run-app.bat failure 5
```

## 📁 Project Files

```
Essential files:
├── start.bat              ← Start everything
├── stop.bat               ← Stop everything
├── run-app.bat            ← Alternative workloads
├── docker-compose.yml     ← Service definitions
├── README.md              ← Full documentation
├── otel/
│   └── otel-collector-config.yaml
├── kibana/dashboards/
│   └── spark-dashboard-v9.ndjson
└── spark/apps/
    └── anomaly_detection_app.py
```

## ❓ Quick Troubleshooting

**No metrics showing?**
- Wait 2 minutes
- Check http://localhost:4040 is accessible
- Run: `docker logs otel-collector --tail 50`

**Services won't start?**
- Ensure Docker Desktop is running
- Run: `stop.bat` then `start.bat`

**Dashboard not found?**
- Check http://localhost:5601/app/dashboards
- Look for "Spark Cluster Monitoring"

## 🎯 What You're Monitoring

The dashboard shows:
- ✅ Active Spark applications
- ✅ Stage completion statistics
- ✅ I/O operations (read/write records)
- ✅ Shuffle operations
- ✅ Real-time activity trends

## 📖 Need More Details?

See `README.md` for:
- Architecture details
- Configuration options
- Advanced troubleshooting
- Customization guide

---

**That's it! You're now monitoring Spark with one command! 🎉**

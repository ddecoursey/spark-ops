# Kibana Dashboard Setup Guide

Complete guide for setting up and using Kibana to visualize Apache Spark metrics collected via OpenTelemetry.

## Quick Start

### 1. Access Kibana
Open your browser and navigate to: **http://localhost:5601**

### 2. Create Data View

On first use, you need to create a data view to access the metrics:

1. Click the menu icon (☰) → **Management** → **Stack Management**
2. Under **Kibana**, click **Data Views**
3. Click **Create data view** button
4. Fill in the details:
   - **Name**: `Spark Metrics`
   - **Index pattern**: `metrics-*`
   - **Timestamp field**: Select `@timestamp` from dropdown
5. Click **Save data view to Kibana**

### 3. Import Pre-built Dashboard

Import the ready-to-use dashboard:

1. Click menu (☰) → **Management** → **Stack Management**
2. Under **Kibana**, click **Saved Objects**
3. Click **Import** button (top right)
4. Click **Import** and select: `kibana/dashboards/spark-metrics-dashboard.ndjson`
5. Click **Import** button
6. If asked to resolve conflicts, select the "Spark Metrics" data view created above
7. Click **Confirm all changes**

### 4. View the Dashboard

1. Click menu (☰) → **Analytics** → **Dashboard**
2. Find and click **Spark Cluster Monitoring - OpenTelemetry**
3. Set time range to **Last 30 minutes** (top right corner)
4. Click the refresh icon or enable **Auto-refresh: 30s**

## Dashboard Overview

The imported dashboard contains:

### Top Metrics (4 Panels)
- **Active Applications**: Unique count of running Spark apps
- **Total Stages**: Number of Spark stages being executed
- **Total I/O Records**: Sum of all records processed
- **Shuffle Records**: Total records shuffled between executors

### Visualizations
1. **Stage I/O Records Over Time**: Line chart showing I/O vs shuffle operations
2. **Applications by Stage Activity**: Bar chart ranking applications
3. **Stage I/O Distribution**: Donut chart showing I/O by stage
4. **Application Activity Timeline**: Area chart of activity over time
5. **Shuffle vs Direct I/O**: Stacked comparison chart
6. **Recent Stage Metrics**: Table with detailed metrics

## Using Discover to Explore Data

### View Raw Metrics

1. Click menu (☰) → **Analytics** → **Discover**
2. Select **Spark Metrics** data view (top left)
3. You'll see all metrics events

### Add Useful Columns

Click the **+** icon next to these fields to add them as columns:
- `spark.application.name`
- `spark.application.id`
- `spark.stage.id`
- `spark.stage.io.records`
- `spark.stage.shuffle.io.records`
- `spark.stage.io.size`

### Search with KQL

Use the search bar at the top with these example queries:

**Filter by application name:**
```
spark.application.name: "AnomalyDetectionApp"
```

**Find high I/O stages:**
```
spark.stage.io.records > 1000
```

**Specific data stream:**
```
data_stream.dataset: "apachesparkreceiver"
```

**Combine multiple conditions:**
```
spark.application.name: "AnomalyDetectionApp" AND spark.stage.io.records > 500
```

## Verifying Metrics Flow

### Check if Data is Coming In

1. **In Kibana Discover**:
   - Go to Discover
   - Select "Spark Metrics" data view
   - Set time range to "Last 15 minutes"
   - You should see documents appearing

2. **Via Command Line**:
   ```powershell
   # Count total metrics
   Invoke-WebRequest -Uri "http://localhost:9200/metrics-*/_count?pretty" -UseBasicParsing
   
   # View latest metrics
   Invoke-WebRequest -Uri "http://localhost:9200/metrics-apachesparkreceiver-default/_search?size=5&sort=@timestamp:desc&pretty" -UseBasicParsing
   ```

3. **Check OTel Collector Logs**:
   ```powershell
   docker logs otel-collector --tail 50
   ```
   Look for messages about scraping metrics from `apachespark` receiver

## Available Metrics Fields

Key metrics fields you can visualize:

### Application Info
- `spark.application.id` - Unique app ID
- `spark.application.name` - Application name (e.g., "AnomalyDetectionApp")

### Stage Metrics
- `spark.stage.id` - Stage identifier
- `spark.stage.io.records` - Number of records read/written
- `spark.stage.io.size` - Total data size in bytes
- `spark.stage.shuffle.io.records` - Records shuffled

### Metadata
- `@timestamp` - Event timestamp
- `service.environment` - Environment (local)
- `service.namespace` - Namespace (aiops)
- `data_stream.dataset` - Data source (apachesparkreceiver)
- `direction` - Direction of data flow (in/out)

## Creating Custom Visualizations

### Example 1: Gauge for Average I/O Records

1. Go to **Analytics** → **Visualize Library**
2. Click **Create visualization**
3. Select **Lens**
4. Configuration:
   - Click **Select a field** → choose `spark.stage.io.records`
   - Click **Average** to change aggregation if needed
   - Change visualization type to **Metric** (icon on right side)
5. Click **Save and return** and add to a dashboard

### Example 2: Time Series by Application

1. Create new **Lens** visualization
2. Drag `@timestamp` to X-axis (horizontal)
3. Drag `spark.stage.io.records` to Y-axis (vertical)
4. Drag `spark.application.name` to **Break down by**
5. Change visualization type to **Line** or **Area**
6. Save and add to dashboard

### Example 3: Top Stages Table

1. Create new **Lens** visualization
2. Change to **Table** visualization type
3. Configuration:
   - **Rows**: `spark.stage.id` (Terms, Top 10)
   - **Metrics**: 
     - Count of records
     - Sum of `spark.stage.io.records`
     - Sum of `spark.stage.shuffle.io.records`
4. Save and add to dashboard

## Dashboard Features

### Time Range Controls

- **Quick Select**: Click time picker (top right) → choose preset (Last 15m, 1h, 24h, etc.)
- **Custom Range**: Click time picker → **Absolute** or **Relative** → set dates
- **Auto-refresh**: Click refresh icon → **Auto refresh** → select interval (10s, 30s, 1m, etc.)

### Filtering

- **Click on chart**: Click any bar/slice/point to filter by that value
- **Search bar**: Use KQL queries at the top
- **Filter pills**: Click **+ Add filter** to create structured filters
- **Remove filters**: Click **x** on filter pills to remove them

### Sharing and Exporting

- **Share link**: Click **Share** → copy link
- **Download CSV**: On tables, click icon → **Download CSV**
- **PDF report**: Click **Share** → **PDF Reports** (requires setup)
- **Copy embed code**: Click **Share** → **Embed code**

## Troubleshooting

### "No results found" in Dashboard

**Solution 1 - Check Time Range**:
- Expand time range to "Last 1 hour" or "Last 24 hours"
- Metrics only appear when Spark apps are running

**Solution 2 - Verify Spark App is Running**:
```powershell
# Check if application is active
curl http://localhost:8080/api/v1/applications
```

**Solution 3 - Run Sample Application**:
```powershell
run-app.bat continuous 10
```

### Data View Shows No Fields

1. Go to **Management** → **Data Views**
2. Click **Spark Metrics**
3. Click the refresh icon (🔄) to reload fields
4. If still no fields, check if data exists:
   ```powershell
   curl http://localhost:9200/metrics-*/_count
   ```

### OTel Collector Not Collecting Metrics

**Check Collector Logs**:
```powershell
docker logs otel-collector --tail 100
```

**Look for these indicators**:
- ✅ Good: Lines showing metrics being exported to Elasticsearch
- ❌ Bad: "Error scraping metrics" or "connection refused"

**Fix connection issues**:
```powershell
# Restart OTel Collector
docker restart otel-collector

# Check Spark Master is accessible
docker exec otel-collector curl http://spark-master:4040/api/v1/applications
```

### Elasticsearch Not Storing Data

**Check Elasticsearch**:
```powershell
# Check ES health
curl http://localhost:9200/_cluster/health?pretty

# List data streams
curl http://localhost:9200/_data_stream/?pretty

# Count documents
curl http://localhost:9200/metrics-*/_count?pretty
```

**Check disk space**:
```powershell
docker exec elasticsearch df -h /usr/share/elasticsearch/data
```

## Advanced Usage

### Creating Alerts

Set up alerts for critical conditions:

1. Go to **Management** → **Stack Management** → **Rules**
2. Click **Create rule**
3. Choose rule type (e.g., **Elasticsearch query**)
4. Configure:
   - **Index**: `metrics-*`
   - **Query**: e.g., `spark.stage.io.records > 10000`
   - **Check every**: 1 minute
   - **Alert**: When query returns results
5. Add action (email, webhook, etc.)
6. Save

### Saved Searches

Save frequently used queries:

1. In **Discover**, configure your search and filters
2. Click **Save** (top right)
3. Give it a name: "High I/O Stages"
4. Access later from **Analytics** → **Discover** → **Open**

### Export/Import Dashboards

**Export**:
1. **Management** → **Saved Objects**
2. Select dashboard checkbox
3. Click **Export** → download NDJSON file

**Import**:
1. **Management** → **Saved Objects**
2. Click **Import**
3. Select NDJSON file
4. Click **Import**

## Data Retention

By default, Elasticsearch keeps all data. To manage storage:

### Check Data Stream Size
```powershell
curl "http://localhost:9200/_cat/indices/metrics-*?v&h=index,store.size,docs.count&s=index"
```

### Delete Old Data (if needed)
```powershell
# Delete data older than 7 days (example)
curl -X POST "http://localhost:9200/metrics-*/_delete_by_query?pretty" `
  -H 'Content-Type: application/json' `
  -d '{"query":{"range":{"@timestamp":{"lt":"now-7d"}}}}'
```

### Set up ILM Policy (Index Lifecycle Management)
Configure automatic deletion after X days through Kibana:
1. **Management** → **Data** → **Index Lifecycle Policies**
2. Create policy with delete phase
3. Apply to data streams

## Tips and Best Practices

### Performance

- **Use filters** instead of large time ranges when possible
- **Limit table rows** to 10-50 for better performance
- **Use sampled data** for very large datasets
- **Close unused tabs** - each dashboard makes queries

### Visualization

- **Use line charts** for time series data
- **Use bar charts** for comparing categories
- **Use pie charts** sparingly (hard to compare slices)
- **Color consistently** across dashboards
- **Add titles and descriptions** to panels

### Querying

- **Use field filters** instead of text search when possible
- **Leverage autocomplete** in KQL search bar
- **Save complex queries** as saved searches
- **Use NOT carefully** - can be slow on large datasets

## Resources

- **Kibana Documentation**: https://www.elastic.co/guide/en/kibana/current/index.html
- **KQL Reference**: https://www.elastic.co/guide/en/kibana/current/kuery-query.html
- **Lens Tutorial**: https://www.elastic.co/guide/en/kibana/current/lens.html
- **Data Streams**: https://www.elastic.co/guide/en/elasticsearch/reference/current/data-streams.html
- **OpenTelemetry Spark Receiver**: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/apachesparkreceiver

## Need Help?

Check these first:
1. OTel Collector logs: `docker logs otel-collector --tail 50`
2. Elasticsearch health: `curl http://localhost:9200/_cluster/health?pretty`
3. Data count: `curl http://localhost:9200/metrics-*/_count?pretty`
4. Spark Master UI: http://localhost:8080
5. Application UI (when running): http://localhost:4040

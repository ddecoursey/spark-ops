"""
Spark Anomaly Detection Sample Application

This application generates sample data and metrics for anomaly detection.
It simulates various workload patterns and intentionally creates anomalies.
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, rand, when, lit, current_timestamp
import time
import random
import sys

def create_spark_session():
    """Create and configure Spark session with metrics enabled"""
    return SparkSession.builder \
        .appName("AnomalyDetectionApp") \
        .config("spark.metrics.conf", "/opt/bitnami/spark/conf/metrics.properties") \
        .config("spark.sql.shuffle.partitions", "4") \
        .config("spark.executor.memory", "1g") \
        .config("spark.driver.memory", "1g") \
        .getOrCreate()

def generate_normal_workload(spark, num_records=10000):
    """Generate a normal workload with predictable patterns"""
    print(f"Generating normal workload with {num_records} records...")
    
    df = spark.range(num_records) \
        .withColumn("value", (rand() * 100).cast("double")) \
        .withColumn("category", (rand() * 10).cast("int")) \
        .withColumn("timestamp", current_timestamp())
    
    # Perform some transformations
    result = df.groupBy("category").agg({"value": "sum", "value": "avg", "value": "max"})
    result.show()
    
    return result

def generate_memory_intensive_workload(spark, size_multiplier=5):
    """Generate workload that consumes significant memory"""
    print(f"Generating memory-intensive workload (multiplier: {size_multiplier})...")
    
    num_records = 100000 * size_multiplier
    df = spark.range(num_records) \
        .withColumn("data", (rand() * 1000000).cast("string")) \
        .withColumn("value", rand() * 1000) \
        .cache()  # Cache to consume memory
    
    df.count()  # Force materialization
    result = df.agg({"value": "sum", "value": "avg"})
    result.show()
    
    df.unpersist()
    return result

def generate_slow_task_workload(spark):
    """Generate workload with artificially slow tasks"""
    print("Generating slow task workload...")
    
    def slow_udf_func(x):
        time.sleep(random.uniform(0.1, 0.5))  # Simulate slow processing
        return x * 2
    
    from pyspark.sql.functions import udf
    from pyspark.sql.types import DoubleType
    
    slow_udf = udf(slow_udf_func, DoubleType())
    
    df = spark.range(1000) \
        .withColumn("value", rand() * 100) \
        .withColumn("slow_value", slow_udf(col("value")))
    
    result = df.agg({"slow_value": "sum"})
    result.show()
    
    return result

def generate_skewed_data_workload(spark):
    """Generate workload with data skew to create uneven task distribution"""
    print("Generating skewed data workload...")
    
    # Create highly skewed data
    df = spark.range(50000) \
        .withColumn("key", when(rand() < 0.8, lit(1)).otherwise((rand() * 100).cast("int"))) \
        .withColumn("value", rand() * 1000)
    
    # This will cause skew as most records have key=1
    result = df.groupBy("key").agg({"value": "sum", "value": "count"})
    result.show()
    
    return result

def generate_failure_prone_workload(spark):
    """Generate workload that may cause task failures"""
    print("Generating failure-prone workload...")
    
    try:
        df = spark.range(10000) \
            .withColumn("value", rand() * 100) \
            .withColumn("risky_calc", col("value") / when(rand() < 0.01, lit(0)).otherwise(lit(1)))
        
        result = df.agg({"risky_calc": "sum"})
        result.show()
        return result
    except Exception as e:
        print(f"Expected error in failure-prone workload: {e}")
        return None

def run_continuous_workload(spark, duration_minutes=5):
    """Run a continuous workload that cycles through different patterns"""
    print(f"Running continuous workload for {duration_minutes} minutes...")
    
    start_time = time.time()
    end_time = start_time + (duration_minutes * 60)
    iteration = 0
    
    while time.time() < end_time:
        iteration += 1
        print(f"\n{'='*60}")
        print(f"Iteration {iteration} - {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*60}")
        
        # Randomly choose workload type
        workload_type = random.choice([
            "normal", "normal", "normal",  # 60% normal
            "memory_intensive",             # 20% memory intensive
            "slow_task",                    # 10% slow tasks
            "skewed_data",                  # 5% skewed
            "failure_prone"                 # 5% failure-prone
        ])
        
        try:
            if workload_type == "normal":
                generate_normal_workload(spark, num_records=random.randint(5000, 15000))
            elif workload_type == "memory_intensive":
                generate_memory_intensive_workload(spark, size_multiplier=random.randint(2, 5))
            elif workload_type == "slow_task":
                generate_slow_task_workload(spark)
            elif workload_type == "skewed_data":
                generate_skewed_data_workload(spark)
            elif workload_type == "failure_prone":
                generate_failure_prone_workload(spark)
            
            # Wait between iterations
            wait_time = random.uniform(10, 30)
            print(f"\nWaiting {wait_time:.1f} seconds before next iteration...")
            time.sleep(wait_time)
            
        except Exception as e:
            print(f"Error in iteration {iteration}: {e}")
            continue
    
    print(f"\nCompleted continuous workload after {iteration} iterations")

def main():
    """Main function to run the anomaly detection workload"""
    print("="*60)
    print("Spark Anomaly Detection Sample Application")
    print("="*60)
    
    spark = create_spark_session()
    
    try:
        # Set log level
        spark.sparkContext.setLogLevel("WARN")
        
        # Check command line arguments
        if len(sys.argv) > 1:
            mode = sys.argv[1]
            
            if mode == "continuous":
                duration = int(sys.argv[2]) if len(sys.argv) > 2 else 5
                run_continuous_workload(spark, duration_minutes=duration)
            elif mode == "normal":
                generate_normal_workload(spark)
            elif mode == "memory":
                generate_memory_intensive_workload(spark)
            elif mode == "slow":
                generate_slow_task_workload(spark)
            elif mode == "skewed":
                generate_skewed_data_workload(spark)
            elif mode == "failure":
                generate_failure_prone_workload(spark)
            else:
                print(f"Unknown mode: {mode}")
                print("Available modes: continuous, normal, memory, slow, skewed, failure")
        else:
            # Default: run continuous workload for 5 minutes
            run_continuous_workload(spark, duration_minutes=5)
        
    finally:
        spark.stop()
        print("\nSpark session stopped. Metrics should be visible in Grafana.")

if __name__ == "__main__":
    main()

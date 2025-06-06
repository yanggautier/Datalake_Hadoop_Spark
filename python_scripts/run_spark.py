from pyspark.sql import SparkSession
import os # Import os for SPARK_HOME


if __name__ =="__main__":

    # Get SPARK_HOME from environment variable (assuming it's set in your Dockerfile)
    spark_home = os.environ.get("SPARK_HOME")
    if not spark_home:
        print("Error: SPARK_HOME environment variable not set.")
        exit(1)

    # Construct the HDFS path for Spark JARs
    # This assumes you will upload Spark's jars to /spark-jars/ in HDFS
    spark_jars_path = "hdfs://namenode:9000/spark-jars/*"

    spark = SparkSession \
                .builder \
                .appName("PySpark Wordcount") \
                .master("yarn") \
                .config("spark.executor.memory", "1g")  \
                .config("spark.executor.cores", "1") \
                .config("spark.num.executors", "2")  \
                .config("spark.default.parallelism", "2")  \
                .config("spark.yarn.jars", spark_jars_path) \
                .getOrCreate()

    sc = spark.sparkContext

    # ... rest of your WordCount logic ...
    raw_data = sc.textFile("hdfs://namenode:9000/data/raw/wordcount.txt")
    counts = raw_data.flatMap(lambda line: line.split(" ")) \
                                .map(lambda word: (word, 1)) \
                            .reduceByKey(lambda x, y: x + y)

    counts.coalesce(1).saveAsTextFile("hdfs://namenode:9000/data/processed/spark_output") # Ensure output path is unique

    spark.stop() # Important: stop the SparkSession cleanly
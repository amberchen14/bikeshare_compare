

#!/usr/bin/python3

import json, os, sys, time
#import dateutil.parser as dup
import boto3
from pyspark.sql import SparkSession
from pyspark.sql.types import StringType, DateType
from pyspark.sql.functions import udf

# Create Spark Session
spark = SparkSession \
	.builder \
	.appName("Ingesting raw json files into Spark DF for processing") \
	.config('spark.executor.memory', '24g') \
	.config('spark.executor.cores', '6') \
	.config('spark.driver.cores','12') \
	.config('spark.default.parallelism', '100') \
	.getOrCreate()

# Create Spark Context
sc = spark.sparkContext

# This is the S3 URL that I want to read json file(s) directly from
# Notably, "s3a" is a way to get very large files.
# "s3n" is an older version of this that can also get large files but not as large (up to a few GBs)
s3_url = "s3a://de-club-2020/bluebike/201501-hubway-tripdata.csv"

# This assumes that your access id/key are stored in your environmental variables
# We are pulling them into our python job here.
access_id = os.getenv('AWS_ACCESS_KEY_ID')
access_key = os.getenv('AWS_SECRET_ACCESS_KEY')

# This sets the config with appropriate security credentials for s3 access
hadoop_conf=sc._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
hadoop_conf.set("fs.s3a.awsAccessKeyId", access_id)
hadoop_conf.set("fs.s3a.awsSecretAccessKey", access_key)
hadoop_conf.set("spark.hadoop.fs.s3a.endpoint", "s3-us-west-2.amazonaws.com")
hadoop_conf.set("com.amazonaws.services.s3a.enableV4", "true")

# Now I can bring in my JSON file directly from s3 into Spark DF
#df = spark.read.json(s3_url)
df = spark.read.csv(s3_url)

df.show(5)

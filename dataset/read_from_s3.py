

#!/usr/bin/python3
import json, os, sys, time
#import dateutil.parser as dup
import boto3
import configparser
from pyspark.sql import SparkSession
from pyspark.sql.types import StringType, DateType
from pyspark.sql.functions import udf



#Add AWS confidential
config = configparser.ConfigParser()
config.read(os.path.expanduser("~/.aws/credentials"))
aws_profile="default"
access_id = config.get(aws_profile, "aws_access_key_id")
access_key = config.get(aws_profile, "aws_secret_access_key")


# Create Spark Session
spark = SparkSession \
	.builder \
	.appName("Ingesting raw json files into Spark DF for processing") \
	.config('spark.executor.memory', '2g') \
	.config('spark.executor.cores', '2') \
	.config('spark.driver.cores','4') \
	.config('spark.default.parallelism', '10') \
        .getOrCreate()

# Create Spark Context
sc = spark.sparkContext

# This is the S3 URL that I want to read json file(s) directly from
# Notably, "s3a" is a way to get very large files.
# "s3n" is an older version of this that can also get large files but not as large (up to a few GBs)
s3_url = "s3a://de-club-2020/bluebike/201501-hubway-tripdata.csv"

# This sets the config with appropriate security credentials for s3 access
hadoop_conf=sc._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3n.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
hadoop_conf.set("fs.s3n.awsAccessKeyId", access_id)
hadoop_conf.set("fs.s3n.awsSecretAccessKey", access_key)


# Now I can bring in my JSON file directly from s3 into Spark DF
#df = spark.read.json(s3_url)
df = spark.read.csv(s3_url)

df.show()


spark.stop()


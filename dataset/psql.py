
#!/usr/bin/python3
import json, os, sys, time
#import dateutil.parser as dup
import boto3
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import StringType, DateType
from pyspark.sql.functions import udf, col
import configparser
from functools import reduce 

#s.environ['PYSPARK_SUBMIT_ARGS']='--jars /home/amber/spark/jars/aws-java-sdk-1.11.30.jar,/home/amber/spark/jars/hadoop-aws-2.7.7.jar,/home/amber/spark/jars/jets3t-0.9.4.jar pyspark-shell'i
os.environ['PYSPARK_SUBMIT_ARGS']='--jars spark/jars/aws-java-sdk-1.11.30.jar,spark/jars/hadoop-aws-2.7.7.jar,spark/jars/jets3t-0.9.4.jar pyspark-shell'
os.environ['PYTHONHASHSEED']='0'
config = configparser.ConfigParser()
aws_profile='default'
config.read(os.path.expanduser("~/.aws/credentials"))
access_id = config.get(aws_profile, "aws_access_key_id")
access_key = config.get(aws_profile, "aws_secret_access_key")
config.read(os.path.expanduser("~/.aws/config"))
access_region = config.get(aws_profile, "region")
#access_output = config.get(aws_profile, "output")

# Create Spark Session
spark = SparkSession \
.builder \
.appName("Ingesting raw json files into Spark DF for processing") \
.config("spark.cleaner.referenceTracking", "false")\
.config("spark.cleaner.referenceTracking.blocking", "false")\
.config("spark.cleaner.referenceTracking.blocking.shuffle", "false")\
.config("spark.cleaner.referenceTracking.cleanCheckpoints", "false")\
.config('spark.executor.memory', '6g') \
.config('spark.executor.cores', '2') \
.config('spark.default.parallelism', '100') \
.getOrCreate()
#.config("spark.master", "spark://ip-10-0-0-13.us-west-2.compute.internal:7077")\
#.config('spark.driver.cores','2') \
#.config('spark.driver.memory', '3g') \



# Create Spark Context
sc = spark.sparkContext

# This sets the config with appropriate security credentials for s3 access
hadoop_conf=sc._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
hadoop_conf.set("fs.s3a.awsAccessKeyId", access_id)
hadoop_conf.set("fs.s3a.awsSecretAccessKey", access_key)
hadoop_conf.set("spark.hadoop.fs.s3a.endpoint", "s3."+access_region+".amazonaws.com")
hadoop_conf.set("com.amazonaws.services.s3a.enableV4", "true")

# This is the S3 URL that I want to read json file(s) directly from
# Notably, "s3a" is a way to get very large files.
# "s3n" is an older version of this that can also get large files but not as large (up to a few GBs)
df=None
s3_url = "s3://de-club-2020/citibike/"
s3_dwd =  "s3a://de-club-2020/citibike/"

s3_url = "s3://de-club-2020/bluebike/"
s3_dwd =  "s3a://de-club-2020/bluebike/"

fnames=os.popen('aws s3 ls '+s3_url+" | awk '{print $4}'").readlines()
df.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://10.0.0.7:5432/my_db") \
    .option("dbtable", "abc") \
    .option("user", "ubuntu") \
    .option( "driver", "org.postgresql.Driver")\
    .save()
    
    
    #.option("password", "ernie0214") \
    


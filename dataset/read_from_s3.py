#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  3 20:39:15 2020

@author: amberchen
"""


#!/usr/bin/python3

import json, os, sys, time
#import dateutil.parser as dup
import boto3
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import StringType, DateType
from pyspark.sql.functions import udf
import configparser

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
s3_url = "s3://de-club-2020/citibike/"
s3_dwd =  "s3a://de-club-2020/citibike/"

fnames=os.popen('aws s3 ls '+s3_url+" | awk '{print $4}'")
df=None
for f in fnames:
    if '.zip' in f or '.csv' not in f :
        continue
    f=s3_dwd+f.replace("\n", "")
    print(f)
    if df is None:
        df=spark.read.load(f, format='csv', header='true')
    else:
        right=spark.read.load(f, format='csv', header='true')
        df=df.union(right)



# This assumes that your access id/key are stored in your environmental variables
# We are pulling them into our python job here.
#access_id = os.getenv('AWS_ACCESS_KEY_ID')
#access_key = os.getenv('AWS_SECRET_ACCESS_KEY')

# This sets the config with appropriate security credentials for s3 access
hadoop_conf=sc._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
hadoop_conf.set("fs.s3a.awsAccessKeyId", access_id)
hadoop_conf.set("fs.s3a.awsSecretAccessKey", access_key)
hadoop_conf.set("spark.hadoop.fs.s3a.endpoint", "s3."+access_region+".amazonaws.com")
hadoop_conf.set("com.amazonaws.services.s3a.enableV4", "true")

# Now I can bring in my JSON file directly from s3 into Spark DF
#df = spark.read.json(s3_url)
#df = spark.read.load(s3_url, format='csv', header='true')
df.printSchema()

df.show()
df.orderBy(df['end station id'].desc()).show()

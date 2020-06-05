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

#num_table = 0
for f in fnames:
    if '.zip' in f or '.csv' not in f :
        continue
    f=s3_dwd+f.replace("\n", "")
    print(f)
    if df is None:
        df=spark.read.load(f, format='csv', header='true')
        df=df.orderBy(df['starttime'].desc())
    else:
        right=spark.read.load(f, format='csv', header='true')
        right=right.orderBy(right['starttime'].desc())
        df=df.union(right)
    #change column name
    df = reduce(lambda df, idx: df.withColumnRenamed(df.columns[idx], df.columns[idx].replace(" ", "_")), range(len(df.columns)), df)
    
   # num_table +=1
    #if num_table ==10:
    #    break

df_citibike
df_bluebike

#df_citibike.cache()
df_citibike.createOrReplaceTempView("df_citibike")
spark.sql('CACHE LAZY TABLE df_citibike')
citi_start_station=df_citibike.select(['start_station_id', 
                                  'start_station_name',
                                  'start_station_latitude',
                                  'start_station_longitude']).distinct()

citi_start_station.createOrReplaceTempView("citi_start_station")
spark.sql('CACHE LAZY TABLE citi_start_station')




citi_station=df_citibike.groupby(['start_station_id', 
                                  'start_station_name',
                                  'start_station_latitude',
                                  'start_station_longitude'])

df_sub=df_citibike.groupby(['start_station_id', 'start_station_name']).count()
df_sub.groupBy("start_station_id").count().filter("'count'>1").sort(col('count').desc()).show()

DataFrame=df_sub.groupby(['start_station_id']).count().filter("`count` >= 1").sort(col('count').desc())


  df.filter((df.d<5)&((df.col1 != df.col3) |
                    (df.col2 != df.col4) & 
                    (df.col1 ==df.col3)))\
    .show()
    
#spark.sql("CACHE TABLE df_citibike")
spark.sql("create table df_sub USING HIVE select distinct start_station_id, \
          start_station_name, \
          count(*) from df_citibike \
          group by start_station_id, start_station_name\
          order by start_station_id")


# Now I can bring in my JSON file directly from s3 into Spark DF
#df = spark.read.json(s3_url)
#df = spark.read.load(s3_url, format='csv', header='true')
df.printSchema()
df.show()
df.count()
df.orderBy(df['end station id'].desc()).show()
sc.stop()
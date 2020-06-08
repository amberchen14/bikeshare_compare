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
from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import StringType, DateType
#from pyspark.sql.functions import udf, col, unix_timestamp, from_unixtime
import configparser
from functools import reduce 
from pyspark.sql.window import Window
import pyspark.sql.functions as func
import pandas as pd
import requests

#s.environ['PYSPARK_SUBMIT_ARGS']='--jars /home/amber/spark/jars/aws-java-sdk-1.11.30.jar,/home/amber/spark/jars/hadoop-aws-2.7.7.jar,/home/amber/spark/jars/jets3t-0.9.4.jar pyspark-shell'i
os.environ['PYSPARK_SUBMIT_ARGS']='--jars spark/jars/aws-java-sdk-1.11.30.jar,spark/jars/hadoop-aws-2.7.7.jar,spark/jars/jets3t-0.9.4.jar pyspark-shell'
os.environ['PYTHONHASHSEED']='0'

s3_bucket='de-club-2020'
#Get AWS key
config = configparser.ConfigParser()
aws_profile='default'
config.read(os.path.expanduser("~/.aws/credentials"))
access_id = config.get(aws_profile, "aws_access_key_id")
access_key = config.get(aws_profile, "aws_secret_access_key")
config.read(os.path.expanduser("~/.aws/config"))
access_region = config.get(aws_profile, "region")



# Create Spark Session
spark = SparkSession \
.builder \
.appName("Ingesting raw json files into Spark DF for processing") \
.config("spark.cleaner.referenceTracking", "false")\
.config("spark.cleaner.referenceTracking.blocking", "false")\
.config("spark.cleaner.referenceTracking.blocking.shuffle", "false")\
.config("spark.cleaner.referenceTracking.cleanCheckpoints", "false")\
.config('spark.driver.memory', '14g') \
.config('spark.driver.cores', '20') \
.config('spark.executor.memory', '14g') \
.config('spark.executor.cores', '8') \
.config('spark.default.parallelism', '16')\
.config('spark.dynamicAllocation.enabled', 'true')\
.getOrCreate()

#spark.executor.cores = number of CPUs on a worker node
#spark.executor.instances = number of worker nodes on a cluster
#spark.executor.memory = max memory available on a worker node - overheads
#spark.default.parallelism = 2 * number of CPUs in total on worker nodes



#.config('spark.executor.memory', '14g') \
#.config('spark.executor.cores', '8') \
#.config("spark.master", "spark://ip-10-0-0-13.us-west-2.compute.internal:7077")\
#.config('spark.driver.cores','2') \
#.config('spark.driver.memory', '3g') \
#.config('spark.default.parallelism', '100') \

# Create Spark Context
sc = spark.sparkContext

# Create configuration
hadoop_conf=sc._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
hadoop_conf.set("fs.s3a.awsAccessKeyId", access_id)
hadoop_conf.set("fs.s3a.awsSecretAccessKey", access_key)
hadoop_conf.set("spark.hadoop.fs.s3a.endpoint", "s3."+access_region+".amazonaws.com")
hadoop_conf.set("com.amazonaws.services.s3a.enableV4", "true")

# This is the S3 URL that I want to read json file(s) directly from
# Notably, "s3a" is a way to get very large files.
# "s3n" is an older version of this that can also get large files but not as large (up to a few GBs)

trip_db=None
station_db=None

data = json.loads(bikeshare)
for file in data:
		s3_url="s3://"+s3_bucket+"/"+file['company']+"/"
		s3_dwd="s3a://"+s3_bucket+"/"+file['company']+"/"
		fnames=os.popen('aws s3 ls '+s3_url+" | awk '{print $4}'").readlines()
		trip_df=None
		station_df=None
		for f in fnames:
				if '.zip' in f or '.csv' not in f :
						continue
				url=s3_dwd+f.replace("\n", "")
				#Trip file
				if file['trip_file']['keyword'] in f:
						if trip_df is None:
								trip_df=spark.read.load(url, format='csv', header='true')
								break
						else:
								right=spark.read.load(url, format='csv', header='true')
								trip_df=trip_df.union(right)
				#Station file
				if file['station_file']['keyword'] in f:
						while (file['station_file']):
							if f in file['station_file']['file_name']:
								if station_df is None:
									station_df=spark.read.load(url, format='csv', header='true')
								else:
									right=spark.read.load(url, format='csv', header='true')
									right.createOrReplaceTempView('right')

									query = 
									query="insert " + file['station_file']['id'] + " as id, " +
																	+ file['station_file']['lon'] + 
									station_df=trip_df.union(right).distinct()


		#replace column name from " " to "_"
		trip_df = reduce(lambda trip_df, idx: trip_df.withColumnRenamed(trip_df.columns[idx], trip_df.columns[idx].replace(" ", "_")), range(len(trip_df.columns)), trip_df)
		#No station file
		if file['station_file']=='None':
				station_df=trip_df.select(func.col(file["trip_file"]["start_station_id"]).alias("id"), 
						func.col(file["trip_file"]["start_station_name"]).alias("name"),
						func.col(file["trip_file"]["start_station_lat"]).alias("lat"),
						func.col(file["trip_file"]["start_station_lon"]).alias("lon")
						).distinct()
				end_df=trip_df.select(func.col(file["trip_file"]["end_station_id"]).alias("id"), 
						func.col(file["trip_file"]["end_station_name"]).alias("name"),
						func.col(file["trip_file"]["end_station_lat"]).alias("lat"),
						func.col(file["trip_file"]["end_station_lon"]).alias("lon")
						).distinct()
				station_df=station_df.union(end_df).distinct()
				#station_rdd=station_df.rdd
		
		trip_df=trip_df.select(
				func.to_timestamp(func.col(file['trip_file']['start_time']), "yyyy-MM-dd HH:mm:ss").alias('start_time'), #
				func.to_timestamp(func.col(file['trip_file']['end_time']), "yyyy-MM-dd HH:mm:ss").alias('end_time'), #
				#func.from_unixtime(func.unix_timestamp(func.col(file['trip_file']['start_time']), "yyyy-MM-dd HH:mm:ss")).alias('start_time'), #
				#func.from_unixtime(func.unix_timestamp(func.col(file['trip_file']["end_time"]), "yyyy-MM-dd HH:mm:ss")).alias('end_time'),  # 
				func.col(file['trip_file']['start_station_id']).alias('start_station_id'),
				func.col(file['trip_file']['end_station_id']).alias('end_station_id')
				)

		station_bike_usage= trip_df.select(func.col('start_station_id').alias('station_id'), func.col('start_time').alias('time'), func.lit(1).alias('action'))\
				.union(trip_df.select(func.col('end_station_id').alias('station_id'), func.col('end_time').alias('time'), func.lit(-1).alias('action')))
		window = Window.partitionBy("station_id").orderBy("time")  
		station_bike_usage=station_bike_usage.select('station_id', 'time', 'action', func.sum('action').over(window).alias('usage'))



#rentBike= trip_df.select(func.col('start_station_id').alias('station_id'), func.col('starttime').alias('time')).withColumn('action', lit(0))






sc.stop()









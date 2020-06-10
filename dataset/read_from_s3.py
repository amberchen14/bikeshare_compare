#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  3 20:39:15 2020

@author: amberchen
"""


#!/usr/bin/python3
import os, sys, time
#import dateutil.parser as dup
import boto3
from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import StringType, DateType
from pyspark.sql.utils import AnalysisException
#from pyspark.sql.functions import udf, col, unix_timestamp, from_unixtime
import configparser
from functools import reduce 
from pyspark.sql.window import Window
import pyspark.sql.functions as func
import pandas as pd
import requests

from bikeshare.py import bikeshare
import json


bluebike={"company": "bluebike",
           # "state": "MA",
            "city": "Boston",
            "trip_file":{
            	"keyword": "trip",
            	"version":[{
	                "start_time":"Start_Date",
	                "end_time": "End_Date",
	                "start_station_id": "Start_station_number",
	                "start_station_name":"Start_station_name",
	                "end_station_id": "End_station_number",
	                "end_station_name":"End_station_name",
	                "end_station_lon": "End_station_longitude",
	                "end_station_lat":"End_station_latitude",	                
	                "start_station_lon": "Start_station_longitude",
	                "start_station_lat":"Start_station_latitude"
            	},{
	                "start_time":"starttime",
	                "end_time": "stoptime",
	                "start_station_id": "start_station_id",
	                "start_station_name":"start_station_name",
	                "start_station_lon": "start_station_longitude",
	                "start_station_lat":"start_station_latitude",
	                "end_station_id": "end_station_id",
	                "end_station_name":"end_station_name",
	                "end_station_lon": "end_station_longitude",
	                "end_station_lat":"end_station_latitude"
            	},
            	]
            },
            "station_file": {
                "keyword": "station",
                "version":[{
	                "id": "Number",
	                "name": "Name",
	                "lon":"Longitude",
	                "lat":"Latitude"                 	
	                },{
		            "id": "Station_ID",
		            "name": "Station",
		            "lon":"Longitude",
		            "lat":"Latitude"                        
	            }
              ]

            }
}
bikeshare=json.dumps([bluebike])

#s.environ['PYSPARK_SUBMIT_ARGS']='--jars /home/amber/spark/jars/aws-java-sdk-1.11.30.jar,/home/amber/spark/jars/hadoop-aws-2.7.7.jar,/home/amber/spark/jars/jets3t-0.9.4.jar pyspark-shell'i
#os.environ['PYSPARK_SUBMIT_ARGS']='--jars spark/jars/aws-java-sdk-1.11.30.jar,spark/jars/hadoop-aws-2.7.7.jar,spark/jars/jets3t-0.9.4.jar pyspark-shell'
#os.environ['PYTHONHASHSEED']='0'

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
.config('spark.driver.memory', '8g') \
.config('spark.driver.cores', '2') \
.config('spark.driver.maxResultSize', '5g')\
.config('spark.executor.memory', '8g') \
.config('spark.executor.cores', '6') \
.config('spark.default.parallelism', '16')\
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
#.config('spark.dynamicAllocation.enabled', 'true')\
# Create Spark Context
sc = spark.sparkContext

# Create configuration
hadoop_conf=sc._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
hadoop_conf.set("fs.s3a.awsAccessKeyId", access_id)
hadoop_conf.set("fs.s3a.awsSecretAccessKey", access_key)
hadoop_conf.set("spark.hadoop.fs.s3a.endpoint", "s3."+access_region+".amazonaws.com")
hadoop_conf.set("com.amazonaws.services.s3a.enableV4", "true")


def write_to_psql(df, table_name, action):
	df.write \
    .format("jdbc") \
    .mode(action)\
    .option("url", "jdbc:postgresql://10.0.0.9:5432/abc") \
    .option("dbtable", table_name) \
    .option("user", "test") \
    .option("driver", "org.postgresql.Driver")\
    .option("password","test00")\
    .save()

def get_value_from_psql(value, table_name):
	query = "select "+ value + " from " + table_name
	out= spark.read \
	.format("jdbc") \
	.option("url", "jdbc:postgresql://10.0.0.9:5432/abc") \
    .option("user", "test") \
    .option("driver", "org.postgresql.Driver")\
    .option("password","test00")\
    .option("query", query)\
    .load()
	return out


def check_station_from_trip_data(file, sub, df):
	print("station geometry : {}".format(file['start_station_lon'] in sub.columns))	
	if file['start_station_lon'] not in sub.columns:
		return df
	sub=sub.select(func.col(file["start_station_id"]).alias("id"), 
		func.col(file["start_station_name"]).alias("name"),
		func.col(file["start_station_lat"]).alias("lat"),
		func.col(file["start_station_lon"]).alias("lon")
		).union(
		sub.select(func.col(file["end_station_id"]).alias("id"), 
		func.col(file["end_station_name"]).alias("name"),
		func.col(file["end_station_lat"]).alias("lat"),
		func.col(file["end_station_lon"]).alias("lon")
		)).distinct()
	if df is not None:
		df=df.union(sub)
	else:
		df=sub
	return df

def clean_trip_file(file, sub, df):
	sub = sub.select(
			func.to_timestamp(func.col(file['start_time']), "yyyy-MM-dd HH:mm:ss").alias('start_time'), #
			func.to_timestamp(func.col(file['end_time']), "yyyy-MM-dd HH:mm:ss").alias('end_time'), #
			func.col(file['start_station_id']).alias('start_station_id'),
			func.col(file['end_station_id']).alias('end_station_id')
			).dropna()
	if df is None:
		df=sub
	else:
		df=df.union(sub)
	return df

def union_station_file(file, sub, df):
	sub=sub.select(
		func.col(file['id']).alias('id'),
		func.col(file['name']).alias('name'),
		func.col(file['lon']).alias('lon'),
		func.col(file['lat']).alias('lat')
		).distinct()
	print("sub: {}, df:{}".format(sub, df))
	if df is None:
		df = sub
	else:
		df=df.union(sub)
	return df

def get_unique_station_table(station_df, station_from_trip_df):
	if station_df is not None and station_from_trip_df is not None:
		station_df=station_df.distinct()
		station_from_trip_df=station_from_trip_df.distinct()
		station_df.createOrReplaceTempView("station_df")
		station_from_trip_df.createOrReplaceTempView("station_from_trip_df")
		spark.sql('CACHE LAZY TABLE station_df')
		spark.sql('CACHE LAZY TABLE station_from_trip_df')
		query='select * from station_from_trip_df where id not in (select id from station_df)'
		distinct_df=spark.sql(query)
		station_df=station_df.union(distinct_df)
		spark.sql('CLEAR CACHE')
	elif station_df is None and station_from_trip_df is not None:
		station_df=station_from_trip_df.distinct()
	else:
		station_df=station_df.distinct()
	return station_df

def	get_station_and_trip_with_station_uid(station_df, trip_df, station_pre_row):
	trip_df=trip_df.select(
		func.to_timestamp(func.col("start_time"), "yyyy-MM-dd HH:mm:ss").alias('start_time'), #
		func.to_timestamp(func.col("end_time"), "yyyy-MM-dd HH:mm:ss").alias('end_time'), #
		func.col("start_station_id"),
		func.col("end_station_id")
		)
	print("join trip from station geometry")
	trip_df=trip_df.join(station_df.select(func.col('id').alias('start_station_id'),
						 func.col('lon').alias('start_station_lon'), func.col('lat').alias('start_station_lat')), on=['start_station_id'], how='left')\
					.join(station_df.select(func.col('id').alias('end_station_id'),
						 func.col('lon').alias('end_station_lon'), func.col('lat').alias('end_station_lat')), on=['end_station_id'], how='left')\
					.drop('start_station_id', 'end_station_id')
	w = Window.orderBy("lon")
	station_df=station_df.select('lon', 'lat').dropna().distinct().withColumn('id',func.row_number().over(w)+station_pre_row)
	print("calculation number of station")
	station_pre_row=station_df.select('id').cache().count() #rdd.max(lambda x:x)['count']
	station_df.unpersist()
	trip_df=trip_df.join(station_df.select(func.col('id').alias('start_station_id'),
						 func.col('lon').alias('start_station_lon'), 
						 func.col('lat').alias('start_station_lat')), 
						on=['start_station_lon', 'start_station_lat'], how='inner')\
					.join(station_df.select(func.col('id').alias('end_station_id'),
						 func.col('lon').alias('end_station_lon'), func.col('lat').alias('end_station_lat')), on=['end_station_lon', 'end_station_lat'], how='inner')\
					.drop('start_station_lon', 'start_station_lat', 'end_station_lon', 'end_station_lat')
	return station_df, trip_df, station_pre_row

station_max_row=0
trip_max_row=0

data = json.loads(bikeshare)
for file in data:
	s3_url="s3://"+s3_bucket+"/"+file['company']+"/"
	s3_dwd="s3a://"+s3_bucket+"/"+file['company']+"/"
	fnames=os.popen('aws s3 ls '+s3_url+" | awk '{print $4}'").readlines()
	trip_df=None
	station_df=None
	station_from_trip_df = None
	station_bike_usage=None
	for f in fnames:
		if '.zip' in f or ".html" in f:
			continue
		url=s3_dwd+f.replace("\n", "")
		df = spark.read.load(url, format='csv', header='true')
		df = reduce(lambda df, idx: df.withColumnRenamed(df.columns[idx], df.columns[idx].replace(" ", "_")), range(len(df.columns)), df)
		print("file: {}\ncolumn:{} \n".format(f, df))
		if (file['trip_file']['keyword'].lower() in f.lower()):
			for s in file['trip_file']['version']:
				if s['start_station_id'] in df.columns:
					break 
			station_from_trip_df=check_station_from_trip_data(s, df, station_from_trip_df)
			trip_df=clean_trip_file(s, df, trip_df)
			continue			
		if file['station_file']['keyword'].lower() in f.lower():
			for s in file['station_file']['version']:
				if s['id'] in df.columns:
					break
			print(s)
			station_df=union_station_file(s, df, station_df)
	print("station_df:{}, station_from_trip_df:{}".format(station_df, station_from_trip_df))
	station_df=get_unique_station_table(station_df, station_from_trip_df)
	station_df, trip_df, station_max_row=get_station_and_trip_with_station_uid(station_df, trip_df, station_max_row)
	station_bike_usage= trip_df.select(func.col('start_station_id').alias('station_id'), func.col('start_time').alias('time'), func.lit(1).alias('action'))\
				.union(trip_df.select(func.col('end_station_id').alias('station_id'), func.col('end_time').alias('time'), func.lit(-1).alias('action')))
	window = Window.partitionBy("station_id").orderBy("time")  
	station_bike_usage=station_bike_usage.select('station_id', 'time', 'action', func.sum('action').over(window).alias('usage'))
	write_to_psql(station_df, 'station', 'append')
	write_to_psql(trip_df, 'trip', 'append')
	wirte_to_psql('station_bike_usage', 'append')


sc.stop()

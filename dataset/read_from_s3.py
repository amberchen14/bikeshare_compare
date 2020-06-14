#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  3 20:39:15 2020

@author: amberchen
"""


#!/usr/bin/python3
import os, sys, time, boto3, requests, json, glob, shutil, zipfile, configparser
import s3fs
from bs4 import BeautifulSoup
from functools import reduce 
import urllib.request
import pandas as pd
from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.dataframe import DataFrame
from pyspark.sql.types import StringType, DateType, DoubleType
from pyspark.sql.utils import AnalysisException
from pyspark.sql.window import Window
import pyspark.sql.functions as func
from bikeshare.py import bikeshare

citibike={"company": "citibike",
            "city": "NYC",
            "trip_file":{
                "keyword": "trip",
                "version":[
                    {
                    "start_time": "starttime",
                    "end_time": "stoptime",
                    "start_station_id": "start_station_id",
                    #"start_station_name":"start_station_name",
                    "start_station_lon": "start_station_longitude",
                    "start_station_lat":"start_station_latitude",
                    "end_station_id": "end_station_id",
                    #"end_station_name":"end_station_name",
                    "end_station_lon": "end_station_longitude",
                    "end_station_lat":"end_station_latitude"
                    },
                    {
                    "start_time": "start_time",
                    "end_time": "stop_Time",
                    "start_station_id": "start_station_id",
                    #"start_station_name":"start_station_name",
                    "start_station_lon": "start_station_longitude",
                    "start_station_lat":"start_station_latitude",
                    "end_station_id": "end_station_id",
                    #"end_station_name":"end_station_name",
                    "end_station_lon": "end_station_longitude",
                    "end_station_lat":"end_station_latitude"
                    }                   
                ]
        },
        "station_file": {
                 "keyword": "none"
                 }  
}

bikeshare=json.dumps([citibike])
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
.config('spark.driver.cores', '2') \
.config('spark.driver.maxResultSize', '5g')\
.config('spark.executor.cores', '6') \
.config('spark.default.parallelism', '16')\
.config('spark.default.partition', '16')\
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
    .option("url", "jdbc:postgresql://10.0.0.9:5432/"+os.environ['PSQL_DB']) \
    .option("dbtable", table_name) \
    .option("user", os.environ['PSQL_UNAME']) \
    .option("driver", "org.postgresql.Driver")\
    .option("password",os.environ['PSQL_PWD'])\
    .save()

def get_value_from_psql(value, table_name):
	query = "select "+ value + " from " + table_name
	out= spark.read \
	.format("jdbc") \
	.option("url", "jdbc:postgresql://10.0.0.9:5432/"+os.environ['PSQL_DB']) \
    .option("user", os.environ['PSQL_UNAME']) \
    .option("driver", "org.postgresql.Driver")\
    .option("password",os.environ['PSQL_PWD'])\
    .option("query", query)\
    .load()
	return out

def get_unique_station_table(station_from_trip_df, station_df, station_pre_row):
	if station_df is None and station_from_trip_df is None:
		return None, station_pre_row
	elif station_df is None and station_from_trip_df is not None:
		df=station_from_trip_df
	elif station_df is not None and station_from_trip_df is None:
		df=station_df
	else:
		df=station_df.append(station_from_trip_df)
	df['lon']=df['lon'].astype(float).round(8)
	df['lat']=df['lat'].astype(float).round(8)
	uid=station_pre_row
	df['uid']=uid
	id_dict, geo_dict=dict(), dict()
	for index, row in df.iterrows():
		if row['id'] not in id_dict and (row['lon'], row['lat']) not in geo_dict:
			uid+=1
			id_dict[row['id']]=uid
			geo_dict[row['lon'], row['lat']]=uid
		elif row['id'] in id_dict and (row['lon'], row['lat']) not in geo_dict:
			df['uid'][index]=id_dict[row['id']]
			geo_dict[row['lon'], row['lat']]=id_dict[row['id']]
		elif row['id'] not in id_dict and (row['lon'], row['lat']) in geo_dict:
			df['uid'][index]=geo_dict[row['lon'], row['lat']]
			id_dict[row['id']]=geo_dict[row['lon'], row['lat']]
		else:
			id_dict[row['id']]=geo_dict[row['lon'], row['lat']]
			continue
	for index, row in df.iterrows():
		df['uid'][index]=id_dict[row['id']]
	return spark.createDataFrame(df), max(df['uid'])

def station_from_trip_table(file, sub, df):
	if file['start_station_lon'] not in sub.columns:
		return df
	sub=sub[[file['start_station_id'], file['start_station_lon'], file['start_station_lat']]]\
			.rename(columns={
				file['start_station_id']: 'id',
				file['start_station_lon']: 'lon',
				file['start_station_lat']: 'lat'
				})\
			.append( sub[[file['end_station_id'], file['end_station_lon'], file['end_station_lat']]]\
			.rename(columns={
				file['end_station_id']: 'id',
				file['end_station_lon']: 'lon',
				file['end_station_lat']: 'lat'
				})
			)
	sub=sub[(sub[['lon', 'lat']]!=0).all(axis=1)].drop_duplicates().dropna()
	if df is None:
		df=sub
	else:
		df=df.append(sub).drop_duplicates()
	return df

def union_station_table(file, sub, df):
	sub=sub[[file['id'], file['lon'], file['lat']]]\
			.rename(columns={
				file['id']: 'id',
				file['lon']: 'lon',
				file['lat']: 'lat'
				})
	sub=sub[(sub[['lon', 'lat']]!=0).all(axis=1)].drop_duplicates().dropna()		
	sub=sub.select(
		func.col(file['id']).alias('id'),
		func.round(func.col(file['lon']).cast(DoubleType()), 8).alias('lon'),
		func.round(func.col(file['lat']).cast(DoubleType()), 8).alias('lat')
		).toPandas().filter(func.col('lon')!=0).filter(func.col('lat')!=0 )
	if df is None:
		df=sub
	else:
		df=df.append(sub).drop_duplicates()	
	return df

def clean_trip_table(file, sub, df):
	sub = sub.select(
			func.to_timestamp(func.col(file['start_time']), "yyyy-MM-dd HH:mm:ss").alias('start_time'), #
			func.to_timestamp(func.col(file['end_time']), "yyyy-MM-dd HH:mm:ss").alias('end_time'), #
			func.col(file['start_station_id']).alias('start_station_id'),
			func.col(file['end_station_id']).alias('end_station_id')
			)
	if df is None:
		df=sub
	else:
		df=df.union(sub)
	return df

def	get_trip_with_station_uid(file, station_df, trip_df):
	df=station_df.select('id', 'uid').distinct()
	trip_df=trip_df.join(func.broadcast(df.select(func.col('id').alias('start_station_id'), func.col("uid").alias('start_uid'))), on=['start_station_id'])\
					.join(func.broadcast(df.select(func.col('id').alias('end_station_id'), func.col("uid").alias('end_uid'))), on=['end_station_id'])\
					.drop('start_station_id', 'end_station_id')\
					.select(func.col('start_uid').alias('start_station_id'), func.col('end_uid').alias('end_station_id'), 'start_time', 'end_time')
	w = Window.partitionBy('uid').orderBy("uid")
	station_df=station_df.groupby('uid').avg('lon', 'lat')\
						.withColumnRenamed('avg(lon)', 'lon').withColumnRenamed('avg(lat)', 'lat')\
						.withColumn('city', func.lit(file['city']))\
						.withColumn('company', func.lit(file['company']))						
	return station_df, trip_df

def get_station_bike_usage(station_df, trip_df):
	w=Window.partitionBy('station_id').orderBy('time')
	station_bike_usage_df= trip_df.select(func.col('start_station_id').alias('station_id'), func.col('start_time').alias('time'), func.lit(1).alias('action'))\
				.union(trip_df.select(func.col('end_station_id').alias('station_id'), func.col('end_time').alias('time'), func.lit(-1).alias('action')))
	window = Window.partitionBy("station_id").orderBy("time")  
	station_bike_usage_df=station_bike_usage_df.select('station_id', 'time', 'action', func.sum('action').over(window).alias('rent'))
	station_bike_usage_df=station_bike_usage_df\
				.withColumn('pre_time', func.lag(station_bike_usage_df.time).over(window))
	station_bike_usage_df=station_bike_usage_df\
				.withColumn("dur", func.when(func.isnull(station_bike_usage_df.time.cast('bigint') - station_bike_usage_df.pre_time.cast('bigint')), 0)\
				.otherwise((station_bike_usage_df.time.cast('bigint') - station_bike_usage_df.pre_time.cast('bigint'))/60).cast('bigint'))\
				.drop('pre_time')
	return station_bike_usage_df

station_max_row=get_value_from_psql("max (uid)", "station").toPandas()['max'][0]
trip_max_row=0
data = json.loads(bikeshare)
for file in data:	
	s3_url="s3://"+s3_bucket+"/"+file['company']+"/"
	s3_dwd="s3a://"+s3_bucket+"/"+file['company']+"/"
	query="aws s3 ls "+ s3_url+  "  | awk '{$1=$2=$3=\"\"; print $0}' | sed 's/^[ \t]*//'"
	fnames=os.popen(query).readlines()	
	count = 0
	station_from_trip_df = None #	station_df = None
	trip_df = None	
	for f in fnames:
		if '.zip' in f:
			continue
		if "csv" not in f and "txt" not in f:
			continue	
		count+=1
		f=f.replace("\n", "")
		url=s3_dwd+f.replace("\n", "")
		sub = spark.read.load(url, format='csv', header='true')
		sub = reduce(lambda sub, idx: sub.withColumnRenamed(sub.columns[idx], 
															sub.columns[idx].replace(" ", "_")),
															range(len(sub.columns)), sub)
		csv=pd.read_csv(s3_url+f)
		csv.columns = map(str.lower, csv.columns)
		csv.columns=csv.columns.str.replace("\n", "").str.replace(" ","_")
		print("count: {}\nfile: {}\ncolumn:{} \n".format(count, f, sub))
		if (file['trip_file']['keyword'].lower() in f.lower()):
			for s in file['trip_file']['version']:
				if s['start_station_id'] in sub.columns:
					break 
			station_from_trip_df=station_from_trip_table(s, csv, station_from_trip_df)#trip_df=clean_trip_table(s, sub, trip_df)
			continue			
		if file['station_file']['keyword'].lower() in f.lower():
			for s in file['station_file']['version']:
				if s['id'] in csv.columns:
					break
			print(s)
			station_df=union_station_table(s, csv, station_df)
	print("station_df:{}, station_from_trip_df:{}".format(station_df, station_from_trip_df))
	station_df, station_max_row=get_unique_station_table(station_df, station_from_trip_df, station_max_row)
	trip_df=trip_df.cache()
	station_df, trip_df=get_trip_with_station_uid(file, station_df, trip_df)
	station_bike_usage_df=get_station_bike_usage(station_df, trip_df)
	station_bike_usage_df=station_bike_usage_df.cache()
	write_to_psql(station_df, 'station', 'append')
	write_to_psql(trip_df, 'trip', 'append')
	write_to_psql(station_bike_usage_df, 'station_bike_usage', 'append')
	spark.catalog.clearCache()
	station_df=None
	station_from_trip=None
	trip_df=None
	station_bike_usage_df=None


sc.stop()

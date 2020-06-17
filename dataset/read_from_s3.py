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
from pyspark.sql.types import *
from pyspark.sql.utils import AnalysisException
from pyspark.sql.window import Window
import pyspark.sql.functions as func

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
	df=df[(df[['lon', 'lat']]!="\\N").all(axis=1)].drop_duplicates()	
	uid=station_pre_row
	df['uid']=uid
	id_dict, geo_dict=dict(), dict()
	df=df.sort_values(by=['lon', 'lat', 'id'])
	for index, row in df.iterrows():
		if row['id'] not in id_dict and (row['lon'], row['lat']) not in geo_dict:
			print("not in dict", row['id'])
			uid+=1
			id_dict[row['id']]=uid
			geo_dict[row['lon'], row['lat']]=uid
		elif row['id'] in id_dict and (row['lon'], row['lat']) not in geo_dict:
			print("in id dict", row['id'])
			geo_dict[row['lon'], row['lat']]=id_dict[row['id']]
		elif row['id'] not in id_dict and (row['lon'], row['lat']) in geo_dict:
			print("in geo dict", row['id'])
			id_dict[row['id']]=geo_dict[row['lon'], row['lat']]
		else:
			print("both dict ", row['id'], id_dict[row['id']], geo_dict[row['lon'], row['lat']])
			id_dict[row['id']]=geo_dict[row['lon'], row['lat']]
			continue
	for index, row in df.iterrows():
		df['uid'][index]=id_dict[row['id']]
	df=df[['uid', 'id', 'lon', 'lat']]
	station_schema= StructType([
	    StructField('uid', StringType(), True),
	    StructField('id', StringType(), True),
	    StructField('lon',  StringType(), True),
	    StructField('lat', StringType(), True)
	])
	df_spark=spark.createDataFrame(df, schema=station_schema)
	return df_spark, max(df['uid'])

def station_from_trip_table(file, sub, df):
	if file['start_station_lon'] =="":
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
	if sub['id'].dtype==float:
		sub['id'].astype(int)
	sub=sub.astype(str)			
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
	if sub['id'].dtype==float:
		sub['id'].astype(int)
	sub=sub.astype(str)
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

def	get_trip_with_station_uid(company, file, station_df, trip_df):
	df=station_df.select('id', 'uid').distinct()
	trip_df=trip_df.join(func.broadcast(df.select(func.col('id').alias('start_station_id'), func.col("uid").alias('start_uid'))), on=['start_station_id'])\
					.join(func.broadcast(df.select(func.col('id').alias('end_station_id'), func.col("uid").alias('end_uid'))), on=['end_station_id'])\
					.drop('start_station_id', 'end_station_id')\
					.select(func.col('start_uid').alias('start_station_id'), func.col('end_uid').alias('end_station_id'), 'start_time', 'end_time').dropna()
	station_df=station_df.select(func.col('uid').cast(IntegerType()), 'id', 
							func.round(func.col('lon').cast(DoubleType()), 8).alias('lon'),
							func.round(func.col('lat').cast(DoubleType()), 8).alias('lat'))\
					.groupby('uid').avg('lon', 'lat')\
						.withColumnRenamed('avg(lon)', 'lon').withColumnRenamed('avg(lat)', 'lat')\
						.withColumn('company', func.lit(company)).orderBy('uid')
	trip_df=trip_df.cache()											
	return station_df, trip_df  ##.withColumn('city', func.lit(file['city']))\

def get_station_bike_usage(trip_df):
	station_bike_usage_df= trip_df.select(func.col('start_station_id').alias('station_id'), func.col('start_time').alias('time'), func.lit(1).alias('action'))\
				.union(trip_df.select(func.col('end_station_id').alias('station_id'), func.col('end_time').alias('time'), func.lit(-1).alias('action')))
	station_bike_usage_df=station_bike_usage_df.cache()
	w=Window.partitionBy('station_id', func.to_date('time')).orderBy('time')
	station_bike_usage_df=station_bike_usage_df.groupby('station_id', 'time').agg(func.sum("action").alias("action"))
	station_bike_usage_df=station_bike_usage_df.select('station_id', 'time', 'action', func.sum('action').over(w).alias('rent'))
	w=Window.partitionBy('station_id').orderBy('time')
	station_bike_usage_df=station_bike_usage_df\
				.withColumn('next_time', func.lead(station_bike_usage_df.time).over(w))
	station_bike_usage_df=station_bike_usage_df\
				.withColumn("dur", func.when(func.isnull(station_bike_usage_df.next_time.cast('bigint') - station_bike_usage_df.time.cast('bigint')), 0)\
				.otherwise((station_bike_usage_df.next_time.cast('bigint') - station_bike_usage_df.time.cast('bigint'))/60).cast('bigint'))#.drop('next_time')	
	station_bike_usage_agg=station_bike_usage_df.select('station_id', 'rent', 'dur',
										func.date_format('time', 'u').alias('dow'), 
										#func.month('time').alias('month'),  
										func.year('time').alias('year')).groupby('station_id','rent', 'dow', 'month', 'year')\
										.agg(func.count("rent").alias('count'), func.sum("dur").alias('dur')).orderBy('station_id','year', #'month', 
											'dow',  'count', 'rent', 'dur')
	station_bike_usage_agg=station_bike_usage_agg.cache()
	return station_bike_usage_df, station_bike_usage_agg


def check_column_name(name, columns,):
	column="None"
	while column not in columns and column != "":
		column=input("Enter column name " + name+ " :")
	return column

def create_trip_schema(columns):
	print(columns)
	start_time=check_column_name('start time', columns)
	end_time=check_column_name('end time', columns)
	start_id=check_column_name('start station id', columns) 
	start_lon=check_column_name('start station longitude', columns) 
	start_lat=check_column_name('start station latitude', columns) 
	end_id=check_column_name('end station id', columns) 
	end_lon=check_column_name('end station longitude', columns) 
	end_lat=check_column_name('end station latitude', columns) 
	trip_schema={
		"columns": str(columns),
		"start_time": start_time,
    	"end_time": end_time,
    	"start_station_id": start_id,
    	"start_station_lon": start_lon,
    	"start_station_lat":start_lat,
    	"end_station_id": end_id,
    	"end_station_lon": end_lon,
   		 "end_station_lat": end_lat    			
   		}
	return trip_schema

def create_station_schema(columns):
	print(columns)
	station_id=check_column_name('station id', columns)
	lon=check_column_name('station longitude', columns)
	lat=check_column_name('station latitude', columns)
	if lon=="" or lat=="":
		return None
	station_schema={
		"columns": str(columns),
		"id": station_id,
        "lon": lon,
        "lat":lat 
	}
	return station_schema

def update_schema(fname, columns, schema):
	if schema['trip_file']['keyword'].lower() in fname.lower():
		version=schema['trip_file']['version']
		for v in version: #if len(columns.difference(v['columns']))==0:	
			if str(columns)==v['columns']:
				return "trip", v, schema
		sub=create_trip_schema(columns)
		schema['trip_file']['version'].append(sub)
		return "trip", sub, schema
	elif schema['station_file']['keyword'].lower() in fname.lower():
		version=schema['station_file']['version']
		for v in version: #if len(columns.difference(v['columns']))==0:
			if str(columns)==v['columns']:
				return "station", v, schema
		sub=create_station_schema(columns)
		if sub is not None:
			schema['station_file']['version'].append(sub)
			return "station", sub, schema		
	return None, None, schema

def initial_schema(company):
	c = input("Enter company name if not " + company+" :")
	if c !="":
		company = c
	print(fnames)
	trip_key=input("Enter keyword of trip file name:")
	station_key=input("Enter keyword of station file name:")	
	schema={
	"company": company,
	"trip_file":{
		"keyword": trip_key,
		"version":[]},
    "station_file": {
        "keyword": station_key,
            "version":[]
        }  
	}
	return schema 

def pandas_to_spark(trip_df, station_df):
	station_schema= StructType([
	    StructField('uid', StringType(), True),
	    StructField('id', StringType(), True),
	    StructField('lon',  StringType(), True),
	    StructField('lat', StringType(), True)
	])
	station_df=spark.createDataFrame(station_df, schema=station_schema)
	trip_schema= StructType([
	    StructField('start_time', StringType(), True),
	    StructField('end_time', StringType(), True),
	    StructField('start_station_id',  StringType(), True),
	    StructField('end_station_id', StringType(), True)
	])	
	trip_df=spark.createDataFrame(trip_df, schema=trip_schema)
	return trip_df, station_df
#company_schema=cpmpany_schema1
station_max_row=get_value_from_psql("max (uid)", "station").toPandas()['max'][0]
url="s3://"+s3_bucket+"/"
query="aws s3 ls "+ url+  " | awk '{print $2}' "
companies=os.popen(query).readlines()	
company_schema = []
for company in companies[2:3]:
	company=company.replace("/\n","")
	s3_url="s3://"+s3_bucket+"/"+company+"/"
	s3_dwd="s3a://"+s3_bucket+"/"+company+"/"
	query="aws s3 ls "+ s3_url+  "  | awk '{$1=$2=$3=\"\"; print $0}' | sed 's/^[ \t]*//'"
	fnames=os.popen(query).readlines()	
	count = 0
	station_df, station_from_trip_df, trip_df=None, None, None
	pre_columns, sub_schema = None, None
	schema=initial_schema(company)	
	for f in fnames[93: ]:
		if '.zip' in f:
			continue
		if "csv" not in f:
			continue	
		count+=1
		f=f.replace("\n", "")
		url=s3_dwd+f.replace("\n", "")
		sub = spark.read.load(url, format='csv', header='true')
		sub = reduce(lambda sub, idx: sub.withColumnRenamed(sub.columns[idx], 
															sub.columns[idx].replace(" ", "_").lower()),
															range(len(sub.columns)), sub)		
		csv=pd.read_csv(s3_url+f)
		csv.columns = map(str.lower, csv.columns)
		csv.columns=csv.columns.str.replace("\n", "").str.replace(" ","_")		
		if pre_columns is None or len(csv.columns.difference(pre_columns))!=0:
			key, sub_schema, schema=update_schema(f, csv.columns, schema)
			pre_columns=csv.columns 
		print("count: {}\nfile: {}\n\n".format(count, f, sub))
		if key=='trip':
			station_from_trip_df=station_from_trip_table(sub_schema, csv, station_from_trip_df)
			trip_df=clean_trip_table(sub_schema, sub, trip_df)
			continue			
		if key=='station':
			station_df=union_station_table(sub_schema, csv, station_df)
	print("station_df:{}, station_from_trip_df:{}".format(station_df, station_from_trip_df))
	#station_df, trip_df= pandas_to_spark(station_df, trip_df)
	station_df, station_max_row=get_unique_station_table(station_df, station_from_trip_df, station_max_row)
	station_df, trip_df=get_trip_with_station_uid(company,sub_schema, station_df, trip_df)
	station_bike_usage_df, station_bike_usage_agg=get_station_bike_usage(trip_df)
	write_to_psql(station_df, 'station', 'append')
	write_to_psql(station_bike_usage_agg, 'usage_agg', 'append')
	spark.catalog.clearCache()
	station_df=None
	station_from_trip=None
	trip_df=None
	station_bike_usage_df=None
	company_schema.append(schema)
sc.stop()



company_schema=json.dumps(company_schema)
data = json.loads(company_schema)
write_to_psql(trip_df, 'trip', 'append')
write_to_psql(station_bike_usage_df, 'station_bike_usage', 'append')
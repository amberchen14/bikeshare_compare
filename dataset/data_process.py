#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  3 20:39:15 2020

@author: amberchen
"""

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
from spark_func import *
from schema_func import * #initial_schema, update_schema, create_station_schema, create_trip_schema, check_column_name 
from data_process_func import * #write_to_psql, get_value_from_psql, get_unique_station_table, station_from_trip_table, union_station_table, clean_trip_table, get_trip_with_station_uid, get_station_bike_usage
from psql_func import * 

s3_bucket='de-club-2020'
def process ():
	spark=create_spark_session(s3_bucket)				
	url="s3://"+s3_bucket+"/"
	query="aws s3 ls "+ url+  " | awk '{print $2}' "
	companies=os.popen(query).readlines()	
	for company in companies:
		company=company.replace("/\n","")
		if 'lyft' in company:
			continue
		s3_url="s3://"+s3_bucket+"/"+company+"/"
		s3_dwd="s3a://"+s3_bucket+"/"+company+"/"
		query="aws s3 ls "+ s3_url+  "  | awk '{$1=$2=$3=\"\"; print $0}' | sed 's/^[ \t]*//'"
		fnames=os.popen(query).readlines()				
		station_max_row=get_value_from_psql(spark, "max (uid)", "station").toPandas()['max'][0]
		print('station max row {}'.format(station_max_row))	
		if station_max_row is None:
			station_max_row = 0	
		count = 0
		station_df, station_from_trip_df, trip_df=None, None, None
		pre_columns, sub_schema = None, None
		schema=initial_schema(company)	
		for f in fnames:
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
				key, sub_schema, schema=update_schema(csv, f,schema)
				pre_columns=csv.columns 
			print("count: {}\nfile: {}\n\n".format(count, f, sub))
			if key=='trip':
				station_from_trip_df=station_from_trip_table(sub_schema, csv, station_from_trip_df)
				trip_df=clean_trip_table(sub_schema, sub, trip_df)
				continue			
			if key=='station':
				station_df=union_station_table(sub_schema, csv, station_df)
		print("station_df:{}, station_from_trip_df:{}".format(station_df, station_from_trip_df))
		station_df, station_max_row=get_unique_station_table(station_df, station_from_trip_df, station_max_row)
		station_df, trip_df, trip_start, trip_end=get_trip_with_station_uid(company,sub_schema, station_df, trip_df)
		station_bike_usage_df, station_bike_usage_agg=get_station_bike_usage(trip_df)
		spark.catalog.clearCache()


if __name__ == '__main__':
    process()

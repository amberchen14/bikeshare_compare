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
schema_name='company_schema.json'


def process ():
	spark=create_spark_session(s3_bucket)		
	company_schema=read_schema_from_s3(s3_bucket, schema_name)	
	for schema in company_schema:
		company=schema['company']
		trip_key=schema['trip_file']['keyword']
		station_key=schema['station_file']['keyword']
		url, fnames=read_fname_from_s3(s3_bucket, company)		
		station_max_row=get_value_from_psql(spark, "max (uid)", "station").toPandas()['max'][0]
		if station_max_row is None:
			station_max_row = 0	
		count = 0
		station_df, station_from_trip_df, trip_df=None, None, None
		for f in fnames:
			if '.zip' in f:
				continue
			if "csv" not in f:
				continue	
			count+=1
			f=f.replace("\n", "")
			dwd_url="s3a://"+s3_bucket+"/raw/"+company+"/"+	f.replace("\n", "")	
			sub = spark.read.load(dwd_url, format='csv', header='true')
			sub = reduce(lambda sub, idx: sub.withColumnRenamed(sub.columns[idx], 
																sub.columns[idx].replace(" ", "_").lower()),
																range(len(sub.columns)), sub)		
			csv=pd.read_csv(dwd_url, header=0)
			csv.columns = map(str.lower, csv.columns)
			csv.columns=csv.columns.str.replace("\n", "").str.replace(" ","_")
			if trip_key in f:
				sub_schema=search_matched_schema(str(csv.columns), schema['trip_file'])
				if sub_schema != None:
					station_from_trip_df=station_from_trip_table(sub_schema, csv, station_from_trip_df)
					trip_df=clean_trip_table(sub_schema, sub, trip_df)
			elif station_key in f:
				sub_schema=search_matched_schema(str(csv.columns), schema['station_file'])
				if sub_schema!= None:
					station_df=union_station_table(sub_schema, csv, station_df)
		print("station_df:{}, station_from_trip_df:{}".format(station_df, station_from_trip_df))
		station_df, station_max_row=get_unique_station_table(station_df, station_from_trip_df, station_max_row)
		station_df, trip_df, trip_start=get_trip_with_station_uid(company,sub_schema, station_df, trip_df)
		station_bike_usage_df, station_bike_usage_agg=get_station_bike_usage(trip_df)
		write_to_psql(station_df, 'station', 'append')
		write_to_psql(trip_start, 'trip_start', 'append')
		write_to_psql(station_bike_usage_agg, 'usage_agg', 'append')
		spark.catalog.clearCache()


if __name__ == '__main__':
    process()

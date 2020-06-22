#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  3 20:39:15 2020

@author: amberchen
"""
import sys
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
from data_process_func import * 
from psql_func import * 
#Import functions from preprocess folder
PREPROCESS=os.environ['PREPROCESS']
sys.path.insert(1, PREPROCESS)
from schema_func import * 


s3_bucket='de-club-2020'
schema_name='company_schema.json'

def process ():
	'''
	This function read trip data and schema from s3, find the matched schema, 
	split trip files which include station geometry postions to trip and station tables,
	and group stations which id or geometry positions are identical.
	After read all trip files from one company, calculate the change of bike number across stations 
	using spark partition and aggregation.
	Then save the tables in PostgreSQL DB.
	'''
	#Create spark session
	spark=create_spark_session(s3_bucket)		
	#Read schema from s3.	
	company_schema=read_schema_from_s3(s3_bucket, schema_name)	
	for schema in company_schema:
		#Get company name, trip and station files' keywords.
		company=schema['company']
		trip_key=schema['trip_file']['keyword']
		station_key=schema['station_file']['keyword']
		#Get all file names under this company
		url, fnames=read_fname_from_s3(s3_bucket, company)
		#Get max uid from station table in PostgreSQL DB		
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
			#Load file using Spark (for trip aggregation)		
			sub = spark.read.load(dwd_url, format='csv', header='true')
			sub = reduce(lambda sub, idx: sub.withColumnRenamed(sub.columns[idx], 
																sub.columns[idx].replace(" ", "_").lower()),
			#Load file using Pandas	(for station aggregation)															range(len(sub.columns)), sub)		
			csv=pd.read_csv(dwd_url, header=0)
			csv.columns = map(str.lower, csv.columns)
			csv.columns=csv.columns.str.replace("\n", "").str.replace(" ","_")
			if trip_key in f.lower():
				#Find matched schema.
				sub_schema=search_matched_schema(str(csv.columns), schema['trip_file'])
				if sub_schema != None:
				        #Get station geometery information (station id, longitude, latitude)
					station_from_trip_df=station_from_trip_table(sub_schema, csv, station_from_trip_df)
					#Get trip information (start time, end time, start station id, end station id) 
				        trip_df=clean_trip_table(sub_schema, sub, trip_df)
			elif station_key in f.lower():
				#Find matched schema
				sub_schema=search_matched_schema(str(csv.columns), schema['station_file'])
				if sub_schema!= None:
				        #Get station geometry information (station id, longitude, latitude)
					station_df=union_station_table(sub_schema, csv, station_df)
		print("station_df:{}, station_from_trip_df:{}".format(station_df, station_from_trip_df))
	        #Combine station_df and station_from_trip_df and group stations whose id or geometry positions are identical.
	        #Generate new station id after grouping stations. 
		station_df, station_max_row=get_unique_station_table(station_df, station_from_trip_df, station_max_row)
	        #Join new station id to trip table and aggregate the rented count with start station id, day of week, year
		# in trip table.	     
		station_df, trip_df, trip_start=get_trip_with_station_uid(company,sub_schema, station_df, trip_df)
	        #Calculate change of bike number and duration across stations, and aggregate # rented/returned bike 
		# with station id, day of week, month, and year.
		station_bike_usage_df, station_bike_usage_agg=get_station_bike_usage(trip_df)
	        # Write station information, aggregated trip information, and aggregated # of rented/returned bikes 
		#in PostgreSQL DB
		write_to_psql(station_df, 'station', 'append')
		write_to_psql(trip_start, 'trip_start', 'append')
		write_to_psql(station_bike_usage_agg, 'usage_agg', 'append')
		spark.catalog.clearCache()


if __name__ == '__main__':
    process()

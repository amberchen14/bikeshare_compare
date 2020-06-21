#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  3 20:39:15 2020

@author: amberchen
"""

import os, sys, time, boto3, requests, json, glob, shutil, zipfile, configparser
import urllib.request
import pandas as pd
from schema_func import * #initial_schema, update_schema, create_station_schema, create_trip_schema, check_column_name 
#from spark_func import aws_credential


s3_bucket='de-club-2020'
def read_company_from_s3(bucket_name):
	url="s3://"+bucket_name+"/"
	query="aws s3 ls "+ url+  " | awk '{print $2}' "
	companies=os.popen(query).readlines()	
	return companies

def read_file_from_s3(bucket_name, company):
	s3_url="s3://"+bucket_name+"/"+company+"/"
	query="aws s3 ls "+ s3_url+  "  | awk '{$1=$2=$3=\"\"; print $0}' | sed 's/^[ \t]*//'"
	fnames=os.popen(query).readlines()	
	return fnames

def write_schema_to_s3(bucket_name, schema):
	s3 = boto3.resource('s3')
	s3object = s3.Object(bucket_name, 'company_schema.json')
	s3object.put(
		Body=(bytes(schema.encode('UTF-8')))
	)

def process ():	
	company_schemas=[]
	companies=read_company_from_s3(s3_bucket)
	for company in companies:
		company=company.replace("/\n","")
		if 'lyft' in company:
			continue
		fnames=read_file_from_s3(s3_bucket, company)			
		pre_columns, sub_schema = None, None
		schema=initial_schema(company)	
		for f in fnames:
			if '.zip' in f:
				continue
			if "csv" not in f:
				continue	
			f=f.replace("\n", "")
			url=s3_dwd+f.replace("\n", "")	
			csv=pd.read_csv(s3_url+f)
			csv.columns = map(str.lower, csv.columns)
			csv.columns=csv.columns.str.replace("\n", "").str.replace(" ","_")		
			if pre_columns is None or len(csv.columns.difference(pre_columns))!=0:
				key, sub_schema, schema=update_schema(csv, f,schema)
				pre_columns=csv.columns 
		company_schemas=company_schemas.append(schema)
	write_schema_to_s3(s3_bucket, company_schemas)

if __name__ == '__main__':
    process()

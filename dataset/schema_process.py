#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  3 20:39:15 2020

@author: amberchen
"""

import os, sys, time, boto3, requests, json, glob, shutil, zipfile, configparser
import urllib.request
import pandas as pd
from schema_func import * 

s3_bucket='de-club-2020'
schema_name='company_schema.json'

def read_company_from_s3(bucket_name):
	url="s3://"+bucket_name+"/"
	query="aws s3 ls "+ url+  " | awk '{print $2}' "
	companies=os.popen(query).readlines()	
	return companies

def read_fname_from_s3(bucket_name, company):
	url="s3://"+bucket_name+"/"+company+"/"
	query="aws s3 ls "+ url+  "  | awk '{$1=$2=$3=\"\"; print $0}' | sed 's/^[ \t]*//'"
	fnames=os.popen(query).readlines()	
	return url, fnames

def process ():	
	company_schemas=[]
	companies=read_company_from_s3(s3_bucket)
	for company in companies:
		company=company.replace("/\n","")
		if 'lyft' in company or schema_name in company:
			continue		
		pre_columns, sub_schema = None, None
		url, fnames=read_fname_from_s3(s3_bucket, company)			
		schema=initial_schema(company, fnames)	
		for f in fnames:
			if '.zip' in f:
				continue
			if "csv" not in f:
				continue	
			f=f.replace("\n", "")
			print("file name: {}".format(f))
			csv=pd.read_csv(url+f)
			csv.columns = map(str.lower, csv.columns)
			csv.columns=csv.columns.str.replace("\n", "").str.replace(" ","_")		
			if pre_columns is None or len(csv.columns.difference(pre_columns))!=0:
				key, sub_schema, schema=update_schema(csv, f, schema)
				pre_columns=csv.columns 
		try:
			company_schemas.append(schema) 
		except:
			company_schemas=[schema]
	company_schema=json.dumps(company_schema)
	write_schema_to_s3(s3_bucket, company_schemas)

if __name__ == '__main__':
    process()

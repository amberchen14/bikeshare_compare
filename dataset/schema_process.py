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


def process ():	
	company_schemas=[]
	companies=read_company_from_s3(s3_bucket)
	for company in companies[5:6]:
		company=company.replace("/\n","")	
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
			csv=pd.read_csv(url+f, nrows=2)
			csv.columns = map(str.lower, csv.columns)
			csv.columns=csv.columns.str.replace("\n", "").str.replace(" ","_")		
			if pre_columns is None or len(csv.columns.difference(pre_columns))!=0:
				key, sub_schema, schema=update_schema(csv, f, schema)
				pre_columns=csv.columns 
		try:
			company_schemas.append(schema) 
		except:
			company_schemas=[schema]
	company_schemas=json.dumps(company_schemas)
	write_schema_to_s3(s3_bucket, company_schemas)

if __name__ == '__main__':
    process()

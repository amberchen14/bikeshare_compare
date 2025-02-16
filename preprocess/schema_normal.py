from io import StringIO
import boto3
import json
import os

s3_bucket=os.environ['S3_BUCKET_Name']
schema_name='company_schema.json'

def read_company_from_s3(bucket_name):
	url="s3://"+bucket_name+"/raw/"
	query="aws s3 ls "+ url+  " | awk '{print $2}' "
	companies=os.popen(query).readlines()	
	return companies

def read_fname_from_s3(bucket_name, company):
	url="s3://"+bucket_name+"/raw/"+company+"/"
	query="aws s3 ls "+ url+  "  | awk '{$1=$2=$3=\"\"; print $0}' | sed 's/^[ \t]*//'"
	fnames=os.popen(query).readlines()	
	return url, fnames

def initial_schema(company, fnames):
	c = input("Enter company name if not " + company+" :")
	print("Company name = {}".format(c))
	if c !="":
		company = c
	print(fnames)
	trip_key=input("Enter keyword of trip file name:")
	station_key=input("Enter keyword of station file name:")
	if station_key=="":
		station_key="None"	
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

def check_column_name(name, csv):
	column="None"
	columns=csv.columns
	while column not in columns and column != "":
		column=input("Enter column name " + name+ " :")
	if 'lon' in name and column!="":
		csv[column][0]=csv[column][0].astype(float)
		if csv[column][0]>0:
			column=check_column_name(name, csv)
	if 'lat' in name and column!="":
		csv[column][0]=csv[column][0].astype(float)
		if csv[column][0]<0:
			column=check_column_name(name, csv)
	return column

def create_trip_schema(csv):
	columns=csv.columns
	print(columns)	
	start_time=check_column_name('start time', csv)
	end_time=check_column_name('end time',csv)
	start_id=check_column_name('start station id', csv) 
	start_lon=check_column_name('start station longitude', csv) 
	start_lat=check_column_name('start station latitude', csv) 
	end_id=check_column_name('end station id', csv) 
	end_lon=check_column_name('end station longitude', csv) 
	end_lat=check_column_name('end station latitude', csv) 
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

def create_station_schema(csv):
	columns=csv.columns
	print(columns)
	station_id=check_column_name('station id', csv)
	lon=check_column_name('station longitude',csv)
	lat=check_column_name('station latitude', csv)
	if lon=="" or lat=="":
		return None
	station_schema={
		"columns": str(columns),
		"id": station_id,
		"lon": lon,
		"lat":lat 
	}
	return station_schema

def update_schema(csv, fname, schema):
	columns=csv.columns
	if schema['trip_file']['keyword'].lower() in fname.lower():
		version=schema['trip_file']['version']
		for v in version: #if len(columns.difference(v['columns']))==0:	
			if str(columns)==v['columns']:
				return "trip", v, schema
		sub=create_trip_schema(csv)
		schema['trip_file']['version'].append(sub)
		return "trip", sub, schema
	elif schema['station_file']['keyword'].lower() in fname.lower():
		version=schema['station_file']['version']
		for v in version: 
			if str(columns)==v['columns']:
				return "station", v, schema
		sub=create_station_schema(csv)
		if sub is not None:
			schema['station_file']['version'].append(sub)
			return "station", sub, schema		
	return None, None, schema


def write_schema_to_s3(bucket_name, schema):
	s3 = boto3.resource('s3')
	s3object = s3.Object(bucket_name, 'company_schema.json')
	s3object.put(
		Body=(bytes(schema.encode('UTF-8')))
	)

def read_schema_from_s3(bucket_name, schema_name):
	s3 = boto3.resource('s3')
	content_object = s3.Object(bucket_name, schema_name)
	file_content = content_object.get()['Body'].read().decode('utf-8')
	json_content = json.loads(file_content)
	return json_content


def schema_normalize ():
	'''
	This function reads all files placed in s3 and 
	let user define schemas when the columns the system read does not face before.
	'''
	company_schemas=[]
	companies=read_company_from_s3(s3_bucket)
	for company in companies:
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
    schema_normalize()
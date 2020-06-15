import os
import glob
import shutil
from bs4 import BeautifulSoup
import urllib.request
import zipfile
import pandas as pd
from pathlib import Path

tmpfolder='tmp/'
dataset=os.getenv("HOME")+'/datasets/'
dwd=dataset+tmpfolder

def url_gbfs(url, filename, dwd):
	link=url+filename
	file=dwd+filename
	urllib.request.urlretrieve(link.replace(" ", "%20"), file)
	if 'zip' in file:
		unzip_file(file)

def get_gbfs(url, dwd):
	file, st="", ""
	tag = 0
	dl_file= urllib.request.urlopen(url)
	dl_file=str(dl_file.read().decode('utf-8'))
	for i in dl_file:
		if tag == 1:
			if i == "<":
				if ".zip" or '.csv'in file:
					print(file)                  
					url_gbfs(url, file, dwd)
					#unzip_file(dwd, file)
					tag = 0
				file = ""
			else:
				file += str(i)
		if st == '<Key>':
			tag = 1
			file += i
		if len(st) == 5:
			st = st[1:]
		st += i

def create_empty_folder(pwd):
	pathlib.Path(pwd).exists()
	if os.path.exists(pwd)==False:
		os.mkdir(pwd)
	files = glob.glob(pwd+'*')
	for f in files:
		shutil.rmtree(pwd+f, ignore_errors=True)

def folder_content_exist(dataset, content):
	pathlib.Path(dataset+contentfoler).exists()
	if os.path.exists(dataset+content)==False:
		os.mkdir(dataset+content)

def unzip_file(zipname):
	with zipfile.ZipFile(zipname, 'r') as zip_ref:
		zip_ref.extractall(dwd)

url = 1
url_list=[]
while url != None:
	url = input("Enter bikeshare link:")
	if url =='':
		break
	url_list.append(url)

trip_key = input("Enter keyword of trip file:")
station_key=input("Enter keyword of station file:")

create_empty_folder(dwd)

for url in url_list:
	if "s3.amazonaws" in url:
		get_gbfs(url.replace('index.html', ""), dwd)

data=None
csv = None
count=0
files = glob.glob(dwd+'*')
for f in files:
	if "zip" in f:
		continue
	if "csv" not in f or "txt" not in f:
		continue
	count +=1
	csv=pd.read_csv(f, header=0) #encoding='utf8', engine='python'
	csv.columns = map(str.lower, csv.columns)
	csv.columns=csv.columns.str.replace("\n", "")
	print(count, f, csv.columns)	
	station=csv[['start station id', 'start station longitude', 'start station latitude']]\
		.rename(columns={'start station id': 'id', 'start station longitude': 'lon', 'start station latitude': 'lat'}).dropna().drop_duplicates()\
		.append(csv[['end station id', 'end station longitude', 'end station latitude']]\
			.rename(columns={'end station id': 'id', 'end station longitude': 'lon', 'end station latitude': 'lat'}).drop_duplicates()
			)
	try:
		data=data.append(station).drop_duplicates()
	except: 
		data=station.drop_duplicates()


def create_trip_schema(columns):
	print(columns)
	start_time=input("Enter column name of start time:")
	end_time=input("Enter column name of end time:")
	start_id=input("Enter column name of start station id:")
	start_lon=input("Enter column name of start station longitude:")
	start_lat=input("Enter column name of start station latitude:")
	end_id=input("Enter column name of end station id:")
	end_lon=input("Enter column name of end station longitude:")
	end_lat=input("Enter column name of end station latitude:")
	schema={
		"columns": columns,
		"start_time": start_time,
    	"end_time": end_time,
    	"start_station_id": start_id,
    	"start_station_lon": start_lon,
    	"start_station_lat":start_lat,
    	"end_station_id": end_id,
    	"end_station_lon": end_lon,
   		 "end_station_lat": end_lat    			
   		}
	return schema

def create_station_schema(columns):
	print(columns)
	station_id=input("Enter column name of station id:")
	lon=input("Enter column name of station longitude:")
	lat=input("Enter column name of station latitude:")		
	station_schema={
		"columns": columns,
		"id": station_id,
        "lon": lon,
        "lat":lat 
	}
	return schema

def update_schema(fname, columns, schema):
	if schema['trip_file']['keyword'].lower() in fname.lower():
		version=schema['trip_file']['version']
		for v in version:
			if len(columns.difference(v['columns']))==0:	
				return v, schema
		sub=create_trip_schema(columns)
		schema['trip_file']['version'].append(sub)
		return sub, schema
	elif schema['station_file']['keyword'].lower() in fname.lower():
		version=schema['trip_file']['version']
		for v in version:
			if len(columns.difference(v['columns']))==0:
				return v, schema
		sub=create_station_schema(columns)
		schema['station_file']['version'].append(sub)
		return sub, schema		
	return None, schema

def initial_schema(company):
	c = input("Enter company name if not " + company+" :")
	if c !="":
		company = c
	print(fnames)
	city = input("Enter city name:")
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


url="s3://"+s3_bucket+"/"
query="aws s3 ls "+ url+  " | awk '{print $2}' "
companies=os.popen(query).readlines()	
schema = None
company_schema = dict()
for company in companies: 
	company=company.replace("/\n","")
	s3_url="s3://"+s3_bucket+"/"+company+"/"
	s3_dwd="s3a://"+s3_bucket+"/"+company+"/"
	query="aws s3 ls "+ s3_url+  "  | awk '{$1=$2=$3=\"\"; print $0}' | sed 's/^[ \t]*//'"
	fnames=os.popen(query).readlines()	
	schema=initial_schema(company)
	count = 0
	station_from_trip_df = None #	station_df = None
	trip_df = None	
	pre_columns = None
	sub_schema = None
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
		columns=csv.columns			
		print("count: {}\nfile: {}\ncolumn:{} \n".format(count, f, columns))
		if pre_columns is None or len(columns.difference(pre_columns))!=0:
			sub_schema, schema=update_schema(f, csv.columns, schema)
			pre_columns=columns
































def url_other(file, dwd):
	filename=file[file.find('uploads')+16:]
	if os.path.exists(dwd+tmpfolder+filename)==False and os.path.exists(dwd+filename)==False:
		query='wget '+file+" -P "+dwd+tmpfolder
		print(query)
		os.system(query)
		if 'zip' in file:
			unzip_file(dwd, filename)            



def get_other(url, dwd):
	file, st="", ""
	tag  = 0
	page=urllib.request.Request(url,headers={'User-Agent': 'Mozilla/5.0'})
	dl_file=str(urllib.request.urlopen(page).read().decode('utf-8'))
	
	for i in dl_file:
		if tag == 1:
			if i == '"':
				if ".zip" in file or '.csv' in file:
					print(file)
					url_other(file, dwd)
					tag = 0
				file = ""
			else:
				file += str(i)
		if st == 'href="':
			tag = 1
			file = i
		if len(st) == 6:
			st = st[1:]
		st += i
 

def create_folder(dwd):
	print(dwd)
	if os.path.exists(dwd)==False:
		os.mkdir(dwd)
	print(dwd+tmpfolder)
	if os.path.exists(dwd+tmpfolder)==False:
		os.mkdir(dwd+tmpfolder)

def mv_all(dwd):
	files = os.listdir(dwd+tmpfolder)
	for f in files:
		shutil.move(dwd+tmpfolder+f, dwd)

def download():
	#gbfs structure
	for fname in gbfs:
		url=gbfs[fname]
		dwd=dataset+fname+'/'
		create_folder(dwd)
		get_gbfs(url, dwd)
		mv_all(dwd)
	#other structure
	for fname in other:
		url=other[fname]
		dwd=dataset+fname+'/'
		create_folder(dwd)
		get_other(url, dwd)
		mv_all(dwd)   
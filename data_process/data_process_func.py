import pyspark.sql.functions as func
from pyspark.sql.types import *

		
def get_unique_station_table(station_from_trip_df, station_df, station_pre_row):
	'''
	This function combines station_from_trip_df (station information readed from trip file) and 
	station_df (station information readed from station file). 
	Since some station geometry positions slight changed across the years, and the id format changed sometimes 
	(ex. station id changed from A32006 to 6), we grouped the station whose geometry positions or id are identical. 
	Then, generate new station id for the grouped stations.
	'''
	# Combine station_df and station_from_trip_df
	if station_df is None and station_from_trip_df is None:
		return None, station_pre_row
	elif station_df is None and station_from_trip_df is not None:
		df=station_from_trip_df
	elif station_df is not None and station_from_trip_df is None:
		df=station_df
	else:
		df=station_df.append(station_from_trip_df)
	df=df[(df[['lon', 'lat']]!="\\N").all(axis=1)].drop_duplicates()
	df=df.sort_values(by=['lon', 'lat', 'id']).reset_index()
	df=df.drop(columns=['index'])
	uid=station_pre_row
	df['uid']=uid
	id_dict, geo_dict=dict(), dict()
	# To solve the changes of station id format and geometry positions, we created two dictionaries,
	# id_dict makes sure the station is identical no matter the changes of geometries
	# geo_dict makes sure the station is identical no matter the changes of ids.
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
	#Fulfill new station id into station table 
	for index, row in df.iterrows():
		df['uid'][index]=id_dict[row['id']]
	df=df[['uid', 'id', 'lon', 'lat']]
	#Create schema for spark reading
	station_schema= StructType([
	    StructField('uid', IntegerType(), True),
	    StructField('id', StringType(), True),
	    StructField('lon',  StringType(), True),
	    StructField('lat', StringType(), True)
	])
	#Transform station table from pandas to spark
	df_spark=spark.createDataFrame(df, schema=station_schema)
	return df_spark, max(df['uid'])

def station_from_trip_table(file, sub, df):
	'''
	This function reads station information (station id, longitude, latitude) from trip file, rename the column name,
	and append to station_from_trip_df.
	'''
	if file['start_station_lon'] =="":
		return df
	#Read station information from trip_file and rename columns
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
	print(sub.head(1))
	# Drop duplicated or NA rows. 	
	sub=sub[(sub[['lon', 'lat']]!=0).all(axis=1)].drop_duplicates().dropna()	
	# Since companies provide id in different formats (ex. float, integer, or string), to be more consistency,
	# if the column format is float, we change format from float to integer to remove ".0", and change format to string. 
	# If the column format is others, we change to string.
	if sub['id'].dtype==float:
		sub['id']=sub['id'].astype(int)
	sub=sub.astype(str)			
	if df is None:
		df=sub
	else:
		df=df.append(sub).drop_duplicates()
	return df

def union_station_table(file, sub, df):
	'''
	This function reads station information (station id, longitude, latitude) from station file, rename the column name,
	and append to station_df.
	'''	
	sub=sub[[file['id'], file['lon'], file['lat']]]\
			.rename(columns={
				file['id']: 'id',
				file['lon']: 'lon',
				file['lat']: 'lat'
				})
	sub=sub[(sub[['lon', 'lat']]!=0).all(axis=1)].drop_duplicates().dropna()
	# Since companies provide id in different formats (ex. float, integer, or string), to be more consistency,
	# if the column format is float, we change format from float to integer to remove ".0", then change format to string. 
	# If the column format is others, we change to string.
	if sub['id'].dtype==float:
		sub['id']=sub['id'].astype(int)
	sub=sub.astype(str)
	if df is None:
		df=sub
	else:
		df=df.append(sub).drop_duplicates()	
	return df

def clean_trip_table(file, sub, df):
	'''
	This function reads station information (start time, end time, start station id, end station id) from trip file, 
	rename the column name, and append to trip_df.
	'''		
	sub = sub.select(
			func.to_timestamp(func.col(file['start_time'])).alias('start_time'), #
			func.to_timestamp(func.col(file['end_time'])).alias('end_time'), #
			func.col(file['start_station_id']).alias('start_station_id'),
			func.col(file['end_station_id']).alias('end_station_id')
			)
	if df is None:
		df=sub
	else:
		df=df.union(sub)
	return df

def	get_trip_with_station_uid(company, file, station_df, trip_df):
	'''
	This function uses broadcast join to fulfill new station id from new station table to trip_df.
	Also, we summarize the number of rented by aggregating start station id, day of week, and year.
	'''	
	df=station_df.select('id', 'uid').distinct()
	#Use broadcast join to replace old start and end station id with new station id from new station table.
	trip_df=trip_df.join(func.broadcast(df.select(func.col('id').alias('start_station_id'), func.col("uid").alias('start_uid'))), on=['start_station_id'])\
					.join(func.broadcast(df.select(func.col('id').alias('end_station_id'), func.col("uid").alias('end_uid'))), on=['end_station_id'])\
					.drop('start_station_id', 'end_station_id')\
					.select(func.col('start_uid').alias('start_station_id'), func.col('end_uid').alias('end_station_id'), 'start_time', 'end_time').dropna()
	#Average geometery positions with identical new station id and remove the old station id. 
	station_df=station_df.select('uid', 'id', 
							func.round(func.col('lon').cast(DoubleType()), 8).alias('lon'),
							func.round(func.col('lat').cast(DoubleType()), 8).alias('lat'))\
					.groupby('uid').avg('lon', 'lat')\
						.withColumnRenamed('avg(lon)', 'lon').withColumnRenamed('avg(lat)', 'lat')\
						.withColumn('company', func.lit(company)).orderBy('uid')
	trip_df=trip_df.cache()	
	#Summarize the number of rented bikes with the aggregation of start station id, day of week, and year.	
	trip_start=trip_df.select('start_station_id','end_station_id',
						func.date_format('end_time', 'u').cast(IntegerType()).alias('dow'), func.year('start_time').alias('year'))\
					.groupby('start_station_id','end_station_id','dow', 'year')\
										.agg(func.count("dow").alias('count'))											
	return station_df, trip_df, trip_start  ##.withColumn('city', func.lit(file['city']))\

def get_station_bike_usage(trip_df):
	'''
	This function calculates the changes of bike number and duration. We have to transform trip table to station usage table
	since trip file does not provide the number of docks and no information related to how many bike is rented/returned. 
	The begining of station usage table includes station id, time, and action (+1 when bike is rented, -1 when bike is returned). 
	Then we add rent column to cummulate action partition by station id and date, and order by time. 
	Finally we summarize the count of number of rented/returned bikes and duration aggregating by station id, number of rented/returned bikes
	day of week, month, and year.
	'''
	#Get station usage table (station id, time, action: +1/-1 rent/return). 
	station_bike_usage_df= trip_df.select(func.col('start_station_id').alias('station_id'), func.col('start_time').alias('time'), func.lit(1).alias('action'))\
				.union(trip_df.select(func.col('end_station_id').alias('station_id'), func.col('end_time').alias('time'), func.lit(-1).alias('action'))).cache()
	#Summarize actions at same time and same station id. 
	station_bike_usage_df=station_bike_usage_df.groupby('station_id', 'time').agg(func.sum("action").alias("action"))
	w=Window.partitionBy('station_id', func.to_date('time')).orderBy('time')	
	#Cummulate actions partition by station id, date and order by time
	station_bike_usage_df=station_bike_usage_df.select('station_id', 'time', 'action', func.sum('action').over(w).alias('rent'))	
	w=Window.partitionBy('station_id').orderBy('time')	
	#To calculate time duration, create column next time and calculate time duration with next time - time 
	station_bike_usage_df=station_bike_usage_df\
				.withColumn('next_time', func.lead(station_bike_usage_df.time).over(w))
	station_bike_usage_df=station_bike_usage_df\
				.withColumn("dur", func.when(func.isnull(station_bike_usage_df.next_time.cast('bigint') - station_bike_usage_df.time.cast('bigint')), 0)\
				.otherwise((station_bike_usage_df.next_time.cast('bigint') - station_bike_usage_df.time.cast('bigint'))/60).cast('bigint'))#.drop('next_time')	
	#Summarize count and duration group by station id, number of rented/returned bikes, day of week, month, and year.
	station_bike_usage_agg=station_bike_usage_df.select('station_id', 'rent', 'dur',
										func.date_format('time', 'u').alias('dow'), 
										func.month('time').alias('month'),  
										func.year('time').alias('year')).groupby('station_id','rent', 'dow', 'month', 'year')\
										.agg(func.count("rent").alias('count'), func.sum("dur").alias('dur')).orderBy('station_id','year', 'month', 
											'dow', 'rent','count',  'dur').select(func.col('station_id').cast(IntegerType()),
											 'year', 'month', func.col('dow').cast(IntegerType()), 'rent','count',  'dur' )
	station_bike_usage_agg=station_bike_usage_agg.cache()
	return station_bike_usage_df, station_bike_usage_agg




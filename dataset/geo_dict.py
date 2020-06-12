from collections import Counter
df=station_df.union(station_from_trip_df)\
.select("id",
		func.round(func.col("lon").cast(DoubleType()), 8).alias('lon'),
		func.round(func.col("lat").cast(DoubleType()), 8).alias('lat'))\
		.distinct().dropna()\
		.filter(func.col('lon')!=0).filter(func.col('lat')!=0 ).toPandas().sort_values(['lon', 'lat', 'id'])
uid=station_pre_row
df['uid']=uid
id_dict, uid_dict=dict(), dict()
geo_trajectory, id_trajectory=[], []
a=pd.from_dict(Counter(df['id']), orient='index').reset_index()
b=df.set_index(['id']).join(a.set_index(['id'])).sort_values(['lon', 'lat', 'id'])


for index, row in df.iterrows():
	if row['id'] not in id_trajectory and [row['lon'], row['lat']] not in geo_trajectory:
		for i in id_trajectory:
			id_dict[i]=geo_trajectory
			uid_dict[i]=uid
		if row['id'] in id_dict:
			id_dict[row['id']].append([row['lon'], row['lat']])
			df['uid'][index]=uid_dict[row['id']]
			continue
		uid+=1
		df['uid'][index]=uid
		geo_trajectory=[[row['lon'], row['lat']]]
		id_trajectory=[row['id']]
		continue
	geo_trajectory.append([row['lon'], row['lat']])
	id_trajectory.append(row['id'])
	df['uid'][index]=uid



df[df['id']=='S32007']
df[df['uid']==108]
a=df[['id', 'uid']].drop_duplicates().groupby('id').count().sort_values('uid')

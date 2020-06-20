def write_to_psql(df, table_name, action):
	df.write \
    .format("jdbc") \
    .mode(action)\
    .option("url", "jdbc:postgresql://10.0.0.9:5432/"+os.environ['PSQL_DB']) \
    .option("dbtable", table_name) \
    .option("user", os.environ['PSQL_UNAME']) \
    .option("driver", "org.postgresql.Driver")\
    .option("password",os.environ['PSQL_PWD'])\
    .save()

def get_value_from_psql(value, table_name):
	query = "select "+ value + " from " + table_name
	out= spark.read \
	.format("jdbc") \
	.option("url", "jdbc:postgresql://10.0.0.9:5432/"+os.environ['PSQL_DB']) \
    .option("user", os.environ['PSQL_UNAME']) \
    .option("driver", "org.postgresql.Driver")\
    .option("password",os.environ['PSQL_PWD'])\
    .option("query", query)\
    .load()
	return out
#!/usr/bin/python3
import configparser
from pyspark import SparkContext
from pyspark.sql import SparkSession
import os

def aws_credential(bucket_name):
	config = configparser.ConfigParser()
	aws_profile='default'
	config.read(os.path.expanduser("~/.aws/credentials"))
	access_id = config.get(aws_profile, "aws_access_key_id")
	access_key = config.get(aws_profile, "aws_secret_access_key")
	return access_id, access_key

def create_spark_session(bucket_name):
	spark = SparkSession \
	.builder \
	.appName("Ingesting raw bike-share trip file") \
	.config('spark.driver.maxResultSize', '60g')\
	.config('spark.default.parallelism', '48') \
	.getOrCreate()
	sc = spark.sparkContext
	access_id, access_key=aws_credential(bucket_name)
	hadoop_conf=sc._jsc.hadoopConfiguration()
	hadoop_conf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
	hadoop_conf.set("fs.s3a.awsAccessKeyId", access_id)
	hadoop_conf.set("fs.s3a.awsSecretAccessKey", access_key)
	hadoop_conf.set("spark.hadoop.fs.s3a.endpoint", "s3."+access_region+".amazonaws.com")
	hadoop_conf.set("com.amazonaws.services.s3a.enableV4", "true")
	return spark

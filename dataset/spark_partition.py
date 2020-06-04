#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Apr  4 18:08:44 2020

@author: amberchen
"""
from pyspark import SparkContext, SparkConf
# The default data used for calculations
nums = range(0, 10)
print(nums)


with SparkContext("local") as sc:
    rdd = sc.parallelize(nums)
    print("Number of partitions: {}".format(rdd.getNumPartitions()))
    print("Partitioner: {}".format(rdd.partitioner))
    print("Partitions structure: {}".format(rdd.glom().collect()))
    
    
#RDD partitions
with SparkContext("local[2]") as sc:
    rdd = sc.parallelize(nums)
    print("Default parallelism: {}".format(sc.defaultParallelism))
    print("Number of partitions: {}".format(rdd.getNumPartitions()))
    print("Partitioner: {}".format(rdd.partitioner))
    print("Partitions structure: {}".format(rdd.glom().collect()))
    

with SparkContext("local[2]") as sc:
    rdd = sc.parallelize(nums) \
        .map(lambda el: (el, el)) \
        .partitionBy(2) \
        .persist()

    
    print("Number of partitions: {}".format(rdd.getNumPartitions()))
    print("Partitioner: {}".format(rdd.partitioner))
    print("Partitions structure: {}".format(rdd.glom().collect()))
    

from pyspark.rdd import portable_hash
num_partitions = 2
for el in nums:
    print("Element: [{}]: {} % {} = partition {}".format(
        el, portable_hash(el), num_partitions, portable_hash(el) % num_partitions))


transactions = [
    {'name': 'Bob', 'amount': 100, 'country': 'United Kingdom'},
    {'name': 'James', 'amount': 15, 'country': 'United Kingdom'},
    {'name': 'Marek', 'amount': 51, 'country': 'Poland'},
    {'name': 'Johannes', 'amount': 200, 'country': 'Germany'},
    {'name': 'Paul', 'amount': 75, 'country': 'Poland'},
]


# Dummy implementation assuring that data for each country is in one partition
def country_partitioner(country):
    return hash(country)
# Validate results
num_partitions = 5
print(country_partitioner("Poland") % num_partitions)
print(country_partitioner("Germany") % num_partitions)
print(country_partitioner("United Kingdom") % num_partitions)
print(country_partitioner("Taiwan") % num_partitions)


with SparkContext("local[2]") as sc:
    rdd = sc.parallelize(transactions) \
        .map(lambda el: (el['country'], el)) \
        .partitionBy(3, country_partitioner)
    
    print("Number of partitions: {}".format(rdd.getNumPartitions()))
    print("Partitioner: {}".format(rdd.partitioner))
    print("Partitions structure: {}".format(rdd.glom().collect()))
    

# Function for calculating sum of sales for each partition
# Notice that we are getting an iterator.All work is done on one node
def sum_sales(iterator):
    yield sum(transaction[1]['amount'] for transaction in iterator)
with SparkContext("local[2]") as sc:
    by_country = sc.parallelize(transactions) \
        .map(lambda el: (el['country'], el)) \
        .partitionBy(3, country_partitioner)
    
    print("Partitions structure: {}".format(by_country.glom().collect()))
    
    # Sum sales in each partition
    sum_amounts = by_country \
        .mapPartitions(sum_sales) \
        .collect()
    
    print("Total sales for each partition: {}".format(sum_amounts))
    
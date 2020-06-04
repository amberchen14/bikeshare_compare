#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun  2 18:14:36 2020

@author: amber
"""


#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from __future__ import print_function

import sys
from operator import add

from pyspark.sql import SparkSession


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: wordcount <file>", file=sys.stderr)
        sys.exit(-1)

    spark = SparkSession\
        .builder\
        .appName("PythonWordCount")\
        .config('spark.executor.memory', '3g') \
        .config('spark.executor.cores', '1')\
        .config('spark.driver.memory', '6g') \
        .config('spark.dynamicAllocation.enabled', 'true')\
        .config('spark.shuffle.service.enabled', 'true')\
        .config('spark.eventLog.logBlockUpdates.enabled', 'true')\
        .getOrCreate()#.config('spark.default.parallelism', '10') \ #.config('spark.worker.memory','4g')\.config('spark.worker.cores','2')\


        

    lines = spark.read.text(sys.argv[1]).rdd.map(lambda r: r[0])
    counts = lines.flatMap(lambda x: x.split(' ')) \
                  .map(lambda x: (x, 1)) \
                  .reduceByKey(add)
    output = counts.collect()
   # for (word, count) in output:
   #     print("%s: %i" % (word, count))

 #`   spark.stop()

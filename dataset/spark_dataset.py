#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar  6 14:35:44 2020

@author: amberchen
"""

from .main import filter_spark_data_frame
from pyspark import SparkContext
from pyspark.sql import SQLContext
import pandas as pd


def test_filter_spark_data_frame_by_value():
    # Spark Context initialisation
    spark_context = SparkContext()
    sql_context = SQLContext(spark_context)

    # Input and output dataframes
    input = sql_context.createDataFrame(
        [('charly', 15),
         ('fabien', 18),
         ('sam', 21),
         ('sam', 25),
         ('nick', 19),
         ('nick', 40)],
        ['name', 'age'],
    )
    expected_output = sql_context.createDataFrame(
        [('sam', 25),
         ('sam', 21),
         ('nick', 40)],
        ['name', 'age'],
    )
    real_output = filter_spark_data_frame(input)
    real_output = get_sorted_data_frame(
        real_output.toPandas(),
        ['age', 'name'],
    )
    expected_output = get_sorted_data_frame(
        expected_output.toPandas(),
        ['age', 'name'],
    )

    # Equality assertion
    pd.testing.assert_frame_equal(
        expected_output,
        real_output,
        check_like=True,
    )

    # Close the Spark Context
    spark_context.stop()


def get_sorted_data_frame(data_frame, columns_list):
    return data_frame.sort_values(columns_list).reset_index(drop=True)

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun  3 20:39:15 2020

@author: amberchen
"""

import os, sys, time, boto3, requests, json, glob, shutil, zipfile, configparser
import urllib.request
import pandas as pd
from bs4 import BeautifulSoup
from schema_func import * 
from downlad_func import *


tmpfolder='tmp/'
dataset=os.getenv("HOME")+'/datasets/'
gbfs={'citibike':'https://s3.amazonaws.com/tripdata/',
        'capital':'https://s3.amazonaws.com/capitalbikeshare-data/',
        'niceride':'https://s3.amazonaws.com/niceride-data/',
        'bluebike':'https://s3.amazonaws.com/hubway-data/',
        'divvy':'https://divvy-tripdata.s3.amazonaws.com/',
        'cogo':'https://s3.amazonaws.com/cogo-sys-data/'
            }
other={'metro':'https://bikeshare.metro.net/about/data/'}

s3_bucket='de-club-2020'
schema_name='company_schema.json'


def download():
    #Download trip files follow gbfs structure placed in s3. 
    for fname in gbfs:
        url=gbfs[fname]
        dwd=dataset+fname+'/'
        create_folder(dwd)
        get_gbfs(url, dwd)
        mv_all(dwd)

    #Download trip files placed in web (wget...)
    for fname in other:
        url=other[fname]
        dwd=dataset+fname+'/'
        create_folder(dwd)
        get_other(url, dwd)
        mv_all(dwd)   
   



if __name__ == '__main__':
    download()



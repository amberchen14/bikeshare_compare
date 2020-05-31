#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri May 29 14:16:40 2020

@author: amberchen
"""

import os
import shutil
from bs4 import BeautifulSoup
import urllib.request
import zipfile

tmpfolder='tmp/'
dataset=os.getenv("HOME")+'/datasets/'
gbfs={'citibike':'https://s3.amazonaws.com/tripdata/',
        'capital':'https://s3.amazonaws.com/capitalbikeshare-data/',
        'lyft': 'https://s3.amazonaws.com/baywheels-data/',
        'niceride':'https://s3.amazonaws.com/niceride-data/',
        'bluebike':'https://s3.amazonaws.com/hubway-data/',
        'divvy':'https://divvy-tripdata.s3.amazonaws.com/',
        'cogo':'https://s3.amazonaws.com/cogo-sys-data/'
            }
other={'indego':'https://www.rideindego.com/about/data/',
        'metro':'https://bikeshare.metro.net/about/data/'}

def unzip_file(dwd, file):
    zipname= dwd+tmpfolder+file
    with zipfile.ZipFile(zipname, 'r') as zip_ref:
        zip_ref.extractall(dwd+tmpfolder)

def url_gbfs(url, dwd, filename):
    if os.path.exists(dwd+tmpfolder+filename)==False and os.path.exists(dwd+filename)==False:
        link=url+filename
        file=dwd+tmpfolder+filename
        urllib.request.urlretrieve(link.replace(" ", "%20"), file)
        if 'zip' in file:
            unzip_file(dwd, filename)

def url_other(url, dwd):
    if os.path.exists(dwd+tmpfolder+filename)==False and os.path.exists(dwd+filename)==False:
        link=url
        filename=url[url.find('uploads')+7:]
        file=dwd+tmpfolder+filename
        urllib.request.urlretrieve(link.replace(" ", "%20"), file)
        if 'zip' in file:
            unzip_file(dwd, filename)            


def get_gbfs(url, dwd):
    file, st="", ""
    tag, n  = 0, 0
    dl_file= urllib.request.urlopen(url)
    dl_file=str(dl_file.read().decode('utf-8'))
    for i in dl_file:
        if tag == 1:
            if i == "<":
                if "zip" in file:
                    download_url(url, dwd, file)
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

def get_other(url, dwd):
    file, st="", ""
    tag, n  = 0, 0
    dl_file= urllib.request.urlopen(url)
    dl_file=str(dl_file.read().decode('utf-8'))
    for i in dl_file:
        if tag == 1:
            if i == '"':
                if "zip" in file or 'csv' in file:
                    download_url(url, dwd, file)
                    tag = 0
                file = ""
            else:
                file += str(i)
        if st == 'href="':
            tag = 1
            file += i
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
  #  for fname in gbfs:
  #      url=gbfs[fname]
  #      dwd=dataset+fname+'/'
  #      create_folder(dwd)
  #      get_gbfs(url, dwd)
  #      mv_all(dwd)

    #others
    for fname in other:
        url=other[fname]
        dwd=dataset+fname+'/'
        create_folder(dwd)
        get_other(url, dwd)
        mv_all(dwd)   


download()


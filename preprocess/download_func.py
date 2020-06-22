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


def unzip_file(dwd, file):
    #Unzip trip zip file
    zipname= dwd+tmpfolder+file
    with zipfile.ZipFile(zipname, 'r') as zip_ref:
        zip_ref.extractall(dwd+tmpfolder)

def url_gbfs(url, dwd, filename):
    #download trip file whose data stored in s3.
    if os.path.exists(dwd+tmpfolder+filename)==False and os.path.exists(dwd+filename)==False:
        link=url+filename
        file=dwd+tmpfolder+filename
        urllib.request.urlretrieve(link.replace(" ", "%20"), file)
        if 'zip' in file:
            unzip_file(dwd, filename)

def url_other(file, dwd):
    #download trip file whose data stored on the web (wget...).    
    filename=file[file.find('uploads')+16:]
    if os.path.exists(dwd+tmpfolder+filename)==False and os.path.exists(dwd+filename)==False:
        query='wget '+file+" -P "+dwd+tmpfolder
        print(query)
        os.system(query)
        if 'zip' in file:
            unzip_file(dwd, filename)            


def get_gbfs(url, dwd):
    '''
    This function gets trip file names where files placed in s3 and download and unzip the zip files.
    '''
    file, st="", ""
    tag = 0
    dl_file= urllib.request.urlopen(url)
    dl_file=str(dl_file.read().decode('utf-8'))
    for i in dl_file:
        if tag == 1:
            if i == "<":
                if ".zip" in file:
                    url_gbfs(url, dwd, file)
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
    '''
    This function gets trip file names where files is placed in a link (wget...) and download and unzip the zip files.
    '''    
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
    #Create folder to download the files. 
    print(dwd)
    if os.path.exists(dwd)==False:
        os.mkdir(dwd)
    print(dwd+tmpfolder)
    if os.path.exists(dwd+tmpfolder)==False:
        os.mkdir(dwd+tmpfolder)

def mv_all(dwd):
    #Move all files in unzip folder to tmp folder.
    files = os.listdir(dwd+tmpfolder)
    for f in files:
        shutil.move(dwd+tmpfolder+f, dwd)

def download():
    #gbfs structure (usually files place in s3)
    for fname in gbfs:
        url=gbfs[fname]
        dwd=dataset+fname+'/'
        create_folder(dwd)
        get_gbfs(url, dwd)
        mv_all(dwd)

    #others
    for fname in other:
        url=other[fname]
        dwd=dataset+fname+'/'
        create_folder(dwd)
        get_other(url, dwd)
        mv_all(dwd)   



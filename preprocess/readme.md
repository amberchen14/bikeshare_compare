# Preprocess
Before starting the pipelines, please follow the stpes below to prepare the trip files.
1. Run download.py. This script downloads all trip files from 7 bikeshare companies and unzip those files in local.
2. Place all of these trip files to s3 after running this script. Each company's trip files should be placed under the same folder. 
3. Run schema_normal.py. This script reads all the trip file column names in s3 and lets user define the matched column names when new type of columns is readed. The schema will upload to s3 after all companies' schemas are defined. 

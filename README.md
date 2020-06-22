# Hot bikeshare, find you!

This batch pipeline ingested 7 bikeshare companies' trip and station data and compared their performance using station usages (number of rented bikes) at one company and number of rented/returned at one station.  

[Demo](http://awsdataeng.club/)  and [Slides](https://docs.google.com/presentation/d/1MfF7WYtXP7_rn48hyBeEr0gDZD7moLwPsfvobEbHuNE/edit#slide=id.g809055a8e0_0_149).


## Problem statement
Bikeshare becomes well-known in the US. Location of bikeshare stations is one of the important factors that affecting bikeshare performance. To have a deeper understanding about which locations attract more usages, this project combined the separated data sets collected from multiple sources to analyze this business model.

## Design

![pipeline plt](/pic/pipeline.png)

The batch pipeline serves as the Extract-Transform-Load (ETL) pipeline. The raw data is stored in Amazon S3 as a collection of files in the csv format. Using schema normalization and data normalization, we extracted the target columns from these input files and developed normal trip and station table formats. Also, we used Pandas to group station ids whose id formats and geometry positions change across years. Finally, we used Spark to aggregate trip tables and saved in PostgreSQL database.


## Prepared version
Spark: 2.4.5-bin-hadoop2.7
Java: 1.8.0_252 (openjdk-8-hre-headless)
Python: 3.7.5 
R: 4.0
Jars:
  org.postgresql:postgresql: 42.2.13
  com.amazonaws:aws-java-sdk: 1.7.4
  org.apache.hadoop:hadoop-aws: 2.7.7




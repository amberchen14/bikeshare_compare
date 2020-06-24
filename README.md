# Hot bikeshare, find you!

This batch pipeline ingested 7 bikeshare companies' trip and station data and compared their performance using number of rented bikes and number of rented/returned from one station.  

[Web](http://awsdataeng.club/), [Demo](https://youtu.be/0ZssHHJbqY0),  and [Slides](https://docs.google.com/presentation/d/1MfF7WYtXP7_rn48hyBeEr0gDZD7moLwPsfvobEbHuNE/edit#slide=id.g809055a8e0_0_149).

[![video](/pic/web.png)](https://youtu.be/0ZssHHJbqY0)

## Problem statement
In recent years, bike share systems begin to gain popularity in major US cities. Several startup companies are competing to implement the most optimal bike share system. However, there is no consensus on the optimal approach to date. One of the important factors that influence bike share usage is the location of bike share stations. To gain a deeper understanding of how to run bike share business successfully, this project aimed to examine which locations attracted more bike usages by combining mulitple datasets collected from different bike share companies.

## Design

![pipeline plt](/pic/pipeline.png)

The batch pipeline serves as the Extract-Transform-Load (ETL) pipeline. The raw data is stored in Amazon S3 as a collection of files in the csv format. Using schema normalization and data normalization, we extracted the target columns from these input files and developed normal trip and station table formats. Also, we used Pandas to group station ids whose id formats and geometry positions change across years. Finally, we used Spark to aggregate trip tables and saved in PostgreSQL database.


## Prepared version
- Spark: 2.4.5-bin-hadoop2.7
- Java: 1.8.0_252 (openjdk-8-hre-headless)
- Python: 3.7.5 
- R: 4.0
- Jars:
  - org.postgresql:postgresql: 42.2.13
  - com.amazonaws:aws-java-sdk: 1.7.4
  - org.apache.hadoop:hadoop-aws: 2.7.7




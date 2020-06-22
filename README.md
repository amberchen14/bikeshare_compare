# Hot bikeshare, find you!

This batch pipeline ingested 7 bikeshare companies' trip and station data and compared their performance using station usages (number of rented bikes) at one company and number of rented/returned at one station.  

Demo and Slides.


## Problem Statement
Bikeshare becomes well-known in the US. Location of bikeshare stations is one of the important factors that affecting bikeshare performance. To have a deeper understanding about which locations attract more usages, this project combined the separated data sets collected from multiple sources to analyze this business model.

## Design


The batch pipeline serves as the Extract-Transform-Load (ETL) pipeline. The raw data is stored in Amazon S3 as a collection of files in the csv format. Using schema normalization and data normalization, we extracted the target columns from these input files and developed normal trip and station table formats. Also, we used Pandas to group station ids whose id formats and geometry positions change across years. Finally, we used Spark to aggregate trip tables and saved in PostgreSQL database.



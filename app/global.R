library("RPostgreSQL")
library(odbc)
library (dplyr)
library(ggplot2)
library(leaflet)
library (DT)
library(shiny)
library(gridExtra)
library(lubridate)
library(shinythemes)
library(stringr)
library(sp)
library(htmlwidgets)
library(progress)
library(shinyBS)
library(scales)
library(plotly)
library(shinyHeatmaply)
library(mapview)
library(shinydashboard)
library(shinyjs)
library(raster)
library(tidyr)
library(RColorBrewer)
library(config)



company_usage_compare_plot<-function (df, tt){
  plt<-ggplot(data=df, aes(x=company, y=count, fill=company))+
    geom_bar(stat='identity')+
    xlab('')+
    ylab('Count')+
    labs(fill='Company')+
    facet_grid(~year)+
    ggtitle(tt)+
    theme_bw()+
    expand_limits( y = 0)+
    scale_y_continuous(labels = comma)+
    theme(axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) 
  plt<-ggplotly(plt) 
  
  plt
}
station_usage_max_freq<-function(df){
  ids<-unique(df$station_id)
  sub<-data.frame()
  for (i in 1: length(ids)){
    s<-filter(df, df$station_id==ids[i])
    s<-filter(s, s$dur==max(s$dur))
    sub<-rbind(sub, s)
  }
  
  sub
}

#Connect to DB
dw <- config::get("insight_fellow")
con <-
  dbConnect(
    drv= dbDriver(dw$driver),
    dbname = dw$database,
    host = dw$server,
    port = dw$port,
    user = dw$uid,
    password = dw$pwd
  )
#Read station information
station<-dbGetQuery(con, "select * from station" )
#Read # of rented bikes aggregated by company, start station id, and year
query<-paste('select distinct a.company, b.start_station_id, b.end_station_id, b.year, sum(b.count) as count from station a, trip_start b\
               where b.start_station_id=a.uid group by a.company, b.start_station_id, b.end_station_id, b.year  order by a.company,b.start_station_id, b.end_station_id, b.year' , sep=" ")
company_usage<-dbGetQuery(con, query)
#Read change of bike number aggregated by station
query<-paste('select distinct station_id, rent, year, sum(count) as count, sum(dur) as dur \
              from usage_agg \
              group by station_id, year,  rent order by station_id,year, rent' , sep=" ")
station_usage<-dbGetQuery(con, query)
dbDisconnect(con)
company_name<-unique(station$company)
# Get total company usage
company_start_station_usage<-aggregate(list(count=company_usage$count),
                                       by=list(company=company_usage$company,
                                               station=company_usage$start_station_id,
                                               year=company_usage$year),
                                       FUN=sum)
# Get total company usage across years
company_total_year_usage<-aggregate(list(count=company_start_station_usage$count),
                               by=list(company=company_start_station_usage$company,
                                       year=company_start_station_usage$year),
                               FUN=sum)
# Get average company usage 
company_avg_year_usage<-aggregate(list(count=company_start_station_usage$count),
                                    by=list(company=company_start_station_usage$company,
                                            year=company_start_station_usage$year),
                                    FUN=mean)
# Get average company usage across years
company_avg_year_usage$count<-as.integer(company_avg_year_usage$count)

#Average change of bike number across stations
station_avg_usage<-aggregate(list(dur=station_usage$dur),
                             by=list(station_id=station_usage$station_id,
                                     rent=station_usage$rent),
                             FUN=sum)
#Merge station information
station_avg_usage<-base::merge(station_avg_usage, station, by.x='station_id', by.y='uid', all.x=TRUE)
#Average change of bike number across stations across years
station_year_usage<-aggregate(list(dur=station_usage$dur),
                             by=list(station_id=station_usage$station_id,
                                     year=station_usage$year,
                                     rent=station_usage$rent),
                             FUN=sum)
#Merge station information
station_year_usage<-base::merge(station_year_usage, station, by.x='station_id', by.y='uid', all.x=TRUE)


#Download properly sized icon (leaflet's built-in icon is not customizable)
markerIcon <-
  makeIcon(iconUrl = 'http://icons.iconarchive.com/icons/icons-land/vista-map-markers/32/Map-Marker-Marker-Outside-Azure-icon.png',
           iconAnchorX = 16,
           iconAnchorY = 30)



library("RPostgreSQL")
library(openair)
library(odbc)
library(plyr)
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
library(sp)
library(raster)
library(tidyr)
library(rhandsontable)
library(RColorBrewer)

dw <- config::get("insight_fellow")
#Connect to DB

con <-
  dbConnect(
    drv= dbDriver(dw$driver),
    dbname = dw$database,
    host = dw$server,
    port = dw$port,
    user = dw$uid,
    password = dw$pwd
  )


station<-dbGetQuery(con, "select * from station_backup" )
query<-paste('select distinct station_id,  rent, sum("count") as count, sum(dur) as dur from usage_agg_backup \
              group by station_id, rent order by station_id, rent' , sep=" ")
station_usage<-dbGetQuery(con, query)
#query<-paste('select distinct  b.company, a.rent, a.year as year, sum(a.count) as count, sum(a.dur) as dur \
#              from usage_agg_backup a, station_backup b \
#              where a.station_id=b.uid group by b.company, a.rent, a.year order by b.company, a.year, a.rent' , sep=" ")
#company_usage<-dbGetQuery(con, query)

query<-paste('select distinct  b.company, a.rent,  sum(a.count) as count, sum(a.dur) as dur \
              from usage_agg_backup a, station_backup b \
              where a.station_id=b.uid group by b.company, a.rent order by b.company,  a.rent' , sep=" ")
company_usage<-dbGetQuery(con, query)
dbDisconnect(con)

cut_values<-c(-Inf, seq(-200, 200, 10), Inf)
cut_labels<-paste(cut_values[1: (length(cut_values)-1)], cut_values[2:length(cut_values)], sep=" to ")
company_usage$cut<-cut(company_usage$rent, 
                      breaks=cut_values,
                      labels=cut_labels,
                      include.lowest = TRUE
)
company_usage$total<-(company_usage$rent*company_usage$dur)
#company_agg_count<-aggregate(list(count=company_usage$count), 
#                             by=list(company=company_usage$company), FUN=sum)
#comapny_agg_dur<-aggregate(list(count=company_usage$dur), 
#                             by=list(company=company_usage$company), FUN=sum)
#company_agg<-merge(x=company_agg_count, y=company_agg_dur, by.x='company', by.y='company', all.x=TRUE)

company_total_usage_rent_count<-aggregate(list(count=company_usage$count), 
                                          by=list(company=company_usage$company,
                                                  rent=company_usage$cut), FUN=sum)
company_total_usage_rent_dur<-aggregate(list(dur=company_usage$dur), 
                                          by=list(company=company_usage$company,
                                                  rent=company_usage$cut), FUN=sum)

#company_yearl_usage_rent_count<-aggregate(list(count=company_usage$count), 
#                                          by=list(company=company_usage$company,
#                                                  year=company_usage$year,
#                                                  rent=company_usage$cut), FUN=sum)
#company_year_usage_rent_dur<-aggregate(list(dur=company_usage$dur), 
#                                        by=list(company=company_usage$company,
#                                                year=company_usage$year,                                                
#                                               rent=company_usage$cut), FUN=sum)

company_total_usage<-merge(x=company_total_usage_rent_count, y=company_total_usage_rent_dur, by.x=c('company', 'rent'), by.y=c('company', 'rent'), all.x=TRUE)
company_total_usage$avg<-as.integer(company_total_usage$dur/company_total_usage$count)


comapny_agg_dur<-ggplot(data=company_total_usage, aes(x=rent, y=avg, color=company))+
  geom_line(aes(group=company))+
  geom_point()+
  theme_classic()+
  xlab('Rent(+)/Return(-)')+
  ylab('Average duration (minute)')+
  labs(colour='Company')+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
company_agg_dur<-ggplotly(comapny_agg_dur)




company_name<-unique(station$company)
trip$avg<-(trip$dur/(trip$count*60))


#Download properly sized icon (leaflet's built-in icon is not customizable)
markerIcon <-
  makeIcon(iconUrl = 'http://icons.iconarchive.com/icons/icons-land/vista-map-markers/32/Map-Marker-Marker-Outside-Azure-icon.png',
           iconAnchorX = 16,
           iconAnchorY = 30)



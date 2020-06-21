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
station<-dbGetQuery(con, "select * from station" )
query<-paste('select distinct a.company, b.year, b.rent, sum(b.count) as count, sum(b.dur) as dur from station a, usage_agg b\
               where b.station_id=a.uid group by a.company,  b.year, b.rent order by a.company,  b.year, b.rent' , sep=" ")
company_usage<-dbGetQuery(con, query)
query<-paste('select distinct station_id, rent, sum(count) as count, sum(dur) as dur \
              from usage_agg \
              group by station_id,  rent order by station_id, rent' , sep=" ")
station_usage<-dbGetQuery(con, query)
dbDisconnect(con)
company_name<-unique(station$company)
#trip$avg<-(trip$dur/(trip$count*60))

cut_values<-c(-Inf, seq(-200, 200, 10), Inf)
cut_labels<-paste(cut_values[1: (length(cut_values)-1)], cut_values[2:length(cut_values)], sep=" to ")
company_usage$cut<-cut(company_usage$rent, 
                      breaks=cut_values,
                      labels=cut_labels,
                      include.lowest = TRUE
)
company_usage$total_dur<-company_usage$rent*company_usage$dur
company_usage$total_count<-company_usage$rent*company_usage$count

company_total_count<-aggregate(list(rent=company_usage$total_count, count=company_usage$count), 
                                   by=list(company=company_usage$company), FUN=sum)
company_total_dur<-aggregate(list(rent=company_usage$total_dur,
                                  count=company_usage$count), 
                             by=list(company=company_usage$company), FUN=sum)

company_total_count$avg<-as.integer(company_total_count$rent/company_total_count$count)
company_total_dur$avg<-as.integer(company_total_dur$rent/company_total_dur$count)

#Company performance across year
company_year_count<-aggregate(list(rent=company_usage$total_count, 
                                   count=company_usage$count), 
                               by=list(company=company_usage$company, 
                                       year=company_usage$year), FUN=sum)
company_year_dur<-aggregate(list(rent=company_usage$total_dur,
                                count=company_usage$count), 
                             by=list(company=company_usage$company, 
                                     year=company_usage$year), FUN=sum)
company_year_count$avg<-as.integer(company_year_count$rent/company_year_count$count)
company_year_dur$avg<-as.integer(company_year_dur$rent/company_year_dur$count)
  

company_cut_dur<-aggregate(list(dur=company_usage$dur), 
                           by=list(company=company_usage$company,
                                   rent=company_usage$cut), FUN=sum)
company_cut_count<-aggregate(list(count=company_usage$count), 
                           by=list(company=company_usage$company,
                                   rent=company_usage$cut), FUN=sum)
company_cut<-base::merge(x=company_cut_dur, y=company_cut_count, by.x=c('company', 'rent'), by.y=c('company', 'rent'), all.x=TRUE)
company_cut$avg<-as.integer(company_cut$dur/company_cut$count)


station_usage$total_dur<-station_usage$rent*station_usage$dur
station_usage$total_count<-station_usage$rent*station_usage$count

#station_year_count<-aggregate(list(rent=station_usage$total_count, 
#                                   count=station_usage$count), 
#                              by=list(station=station_usage$station_id, 
#                                      year=station_usage$year), FUN=sum)
#station_year_dur<-aggregate(list(rent=station_usage$total_dur,
#                                 count=station_usage$count), 
#                            by=list(station=station_usage$station_id, 
#                                    year=station_usage$year), FUN=sum)
#station_year_count$avg<-as.integer(station_year_count$rent/station_year_count$count)
#station_year_dur$avg<-as.integer(station_year_dur$rent/station_year_dur$count)


station_total_count<-aggregate(list(rent=station_usage$total_count, 
                                   count=station_usage$count), 
                              by=list(station_id=station_usage$station_id), FUN=sum)
station_total_dur<-aggregate(list(rent=station_usage$total_dur,
                                 count=station_usage$dur), 
                            by=list(station_id=station_usage$station_id), FUN=sum)

station_total_count$avg<-as.integer(station_total_count$rent/station_total_count$count)
station_total_dur$avg<-as.integer(station_total_dur$rent/station_total_dur$count)


company_cut_plot<-ggplot(data=company_cut, aes(x=rent, y=avg, color=company))+
  geom_line(aes(group=company))+
  geom_point()+
  theme_classic()+
  xlab('Rent(+)/Return(-)')+
  ylab('Average duration (minute)')+
  labs(colour='Company')+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
company_cut_plot<-ggplotly(company_cut_plot)



company_total_compare_plot<-function (df, tt){
  plt<-ggplot(data=df, aes(x=company, y=avg, fill=company))+
        geom_bar(stat='identity')+
        xlab('Rent(+)/Return(-)')+
        ylab('# rented bike')+
        labs(fill='Company')+
        ggtitle(tt)+
        theme_bw()+
        theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))      
  plt<-ggplotly(plt)
  plt
}

company_year_compare_plot<-function (df, tt){
  plt<-ggplot(data=df, aes(x=company, y=avg, fill=company))+
    geom_bar(stat='identity')+
    xlab('Rent(+)/Return(-)')+
    ylab('# Rented bike')+
    labs(fill='Company')+
    facet_grid(~year)+
    ggtitle(tt)+
    theme_bw()+
    theme(axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) 
  plt<-ggplotly(plt) 
  
  plt
}

#Download properly sized icon (leaflet's built-in icon is not customizable)
markerIcon <-
  makeIcon(iconUrl = 'http://icons.iconarchive.com/icons/icons-land/vista-map-markers/32/Map-Marker-Marker-Outside-Azure-icon.png',
           iconAnchorX = 16,
           iconAnchorY = 30)



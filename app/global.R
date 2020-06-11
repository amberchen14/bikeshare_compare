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

################Default defined######################
#sensor_location_table<-'sensor_location'
#sensor_history_traffic_table<-'temporary_sensor_archive_history'
sensor_current_traffic_table<-'temporary_sensor_archive'
temporary_sensor_info<-'closure_info_temp_sensor'
temporary_sensor_loc<-'temporary_sensor_location'

road_name<-data.frame(detected_name=c("35", "183"), road=c( "I-35", "US-183"), stringsAsFactors = FALSE)
#replace_name<-data.frame(old=c("after TX 69", "after Rundberg Ln",  "after N Lamar Blvd", "before Slaughter Ln", "before Stassney Ln", "before St Elmo Rd", "before US 290 E"), 
#                         new=c("before US-183","at Little Walnut Creek", "after Lamar Blvd", "after Slaughter Ln", "after Stassney Ln", "after St Elmo Rd", "before US 290"),
#                         stringsAsFactors = FALSE)

replace_pos<-data.frame(sensor=c("after E 51st St"), lon=c(-97.70815) , lat=c(30.31315))

dir<-c("NB", "SB", "WB", "EB")

color_renderer<-
"
    function(instance, td, row, col, prop, value, cellProperties) {
      Handsontable.renderers.TextRenderer.apply(this, arguments);
      
      tbl = this.HTMLWidgets.widgets[0]

      hcols = tbl.params.col_highlight
      hcols = hcols instanceof Array ? hcols : [hcols] 
      hrows = tbl.params.row_highlight
      hrows = hrows instanceof Array ? hrows : [hrows] 
      
      if (hcols.includes(col)) {
        td.style.background = 'lightgreen';
      }
     
      
      return td;
  }"

input_am<- sprintf("%d a.m.", 0:11)
input_pm<- sprintf("%d p.m.", 0:11)
input_hour<-append(input_am, input_pm, after=length(input_am))
hr_range<-c(0:23)
names(hr_range)<-input_hour
#big event input time #######
hr_range_be<-append(hr_range, -1)
names(hr_range_be)<-c(input_hour, "now")
day_of_week<-data.frame(day=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"),
                        dnum=c(seq(100000,700000,100000 ),100000))

spd_min<-0
spd_max<-75
speed_range<-seq(spd_min, spd_max, 5)
speed_range1<-seq(spd_min, (spd_max-5), 5)
speed_range2<-seq((spd_min+5), spd_max,5)
speed<-array(c(speed_range1,speed_range2), c(1, length(speed_range1), 2))
speed<-apply(speed,c(2),mean, na.rm=TRUE)
speed_range1<-c("00", "05", seq(10, (spd_max-5), by=5) )
speed_range2<-c("05", seq(10, spd_max, by=5) )
speed_unit<-c(strsplit((paste(speed_range1, '\n to \n', speed_range2, "\n MPH,", collapse="")),  ",")[[1]])
speed_unit_label<-c(strsplit((paste(speed_range1, ' to ', speed_range2, " MPH,", collapse="")),  ",")[[1]])

speed_range[length(speed_range)]<-Inf
speed_category<-data.frame(value=speed, unit=speed_unit, label=speed_unit_label)
speed_category$tt<-(1/speed*60)
colfunc <- colorRampPalette(c("darkred", "red", "yellow","green"))
speed_category$color<-colfunc(nrow(speed_category))
speed_category$unit<-as.character(speed_category$unit)
speed_category$label<-as.character(speed_category$label)
speed_category[nrow(speed_category), ]<-c(72.5, '70 MPH -', '70 MPH -', speed_category[nrow(speed_category), 4:5])


closure_planning_timeframe<-c(1, 4,5,6,7,8,9,10,11,12)


#Arguments that should be external
server = "nmc-compute1.ctr.utexas.edu"
uname = 'vista'
net = "lane_uc"
pwd = 'vista00'

##Extract sensor location and date availability from database
drv <- dbDriver("PostgreSQL")
con3 <-
  dbConnect(
    drv,
    dbname = net,
    host = server,
    port = 5432,
    user = uname,
    password = pwd
  )

vista_link<-dbGetQuery(con3, "select * from linkdetails_nodes" )
route_name<-dbGetQuery(con3, "select * from bus_route" )
route_link<-dbGetQuery(con3, "select * from bus_route_link" )
sensor_pos_map<-dbGetQuery(con3, "select * from sensor_pos_dis" )
dbDisconnect(con3)

# con <- dbConnect(odbc::odbc(),
#                  Driver = "SQL Server", #ODBC Driver 13 for SQL Server
#                  Server = "204.144.121.89",
#                  # Server="204.144.121.89",
#                  Database = "CCAT",
#                  UID = "sql_ut",
#                  # PWD = rstudioapi::askForPassword("")
#                  PWD="mEQW43FAbddjJnBJ",
#                  Port = 1433)
# 


# temp_sensor_info<-dbGetQuery(con, paste('select * from ', temporary_sensor_info, sep=''))
# temp_sensor_id<-dbGetQuery(con, paste('select sensor_id as sensor_id, sensor_name as sensor_name from ', temporary_sensor_loc, sep=''))
# dbDisconnect(con) 
# 
# temp_sensor_info$stime<-as.POSIXct(temp_sensor_info$stime, format="%m/%d/%Y %H:%M", tz="America/Chicago")
# temp_sensor_info$etime<-as.POSIXct(temp_sensor_info$etime, format="%m/%d/%Y %H:%M", tz="America/Chicago")
# 
# temp_sensor_info=data.frame(temp_sensor_info, stringsAsFactors = FALSE) 
# 

#vista link
route_name$dir<-NULL
route_name$dir[str_detect(route_name$name, "i35_n")]<-"NB"
route_name$dir[str_detect(route_name$name, "i35_s")]<-"SB"
route_name$dir[str_detect(route_name$name, "US183_SB")]<-"EB"
route_name$dir[str_detect(route_name$name, "US183_NB")]<-"WB"

route_link<-route_link[c("route", "sequence", "link")]
route_link<-merge(x=route_link, y=route_name, by.x="route", by.y="id", all.x=TRUE)
route_link<-merge(x=route_link, y=vista_link, by.x="link", by.y="id", all.x=TRUE)
route_link<-route_link[order(-route_link$sequence), ]
route_dis<-data.frame(stringsAsFactors = FALSE)
for (i in 1:nrow(route_name))
{
  df<-filter(route_link, route_link$name==route_name$name[i])
  df$dis<-0
  df$dis<-cumsum(df$length)
  route_dis<-rbind(route_dis, df)
}

psql_connection<-function(query)
{
  drv <- dbDriver("PostgreSQL")
  con <-
    dbConnect(
      drv,
      dbname = net,
      host = server,
      port = 5432,
      user = uname,
      password = pwd
    )
  
  data<-dbGetQuery(con, query)
  dbDisconnect(con)
  
  data
  
  
}

mysql_connection<-function(query)
{
  con <- dbConnect(odbc::odbc(),
                   ## Driver = "SQL Server",
                   Driver="SQL Server",
                   Server = "204.144.121.89",
                   # Server="204.144.121.89",
                   Database = "CCAT",
                   UID = "sql_ut",
                   # PWD = rstudioapi::askForPassword("")
                   PWD="mEQW43FAbddjJnBJ",
                   Port = 1433)
  
  data<-dbGetQuery(con, query)
  dbDisconnect(con)
  data
  
  
}

write_table_psql<-function(tb_name, tb)
{
  drv <- dbDriver("PostgreSQL")
  con <-
    dbConnect(
      drv,
      dbname = net,
      host = server,
      port = 5432,
      user = uname,
      password = pwd
    )
  
  
  dbWriteTable(con, "od", value=od, overwrite=TRUE, row.names=FALSE)
  dbWriteTable(con, "od_table", value=odtable, overwrite=TRUE, row.names=FALSE)
  
  data<-dbGetQuery(con, query)
  dbDisconnect(con)
  
  data
  
}

write_table_mysql<-function(tb_name, tb)
{
  con <- dbConnect(odbc::odbc(),
                   ## Driver = "SQL Server",
                   Driver="SQL Server",
                   Server = "204.144.121.89",
                   # Server="204.144.121.89",
                   Database = "CCAT",
                   UID = "sql_ut",
                   # PWD = rstudioapi::askForPassword("")
                   PWD="mEQW43FAbddjJnBJ",
                   Port = 1433)
  
  
  dbWriteTable(con, tb_name, value=tb, append=TRUE, row.names=FALSE)
  dbDisconnect(con)

  
}

vermac_column_time<-function(ver_traf)
{
  ver_traf<-ver_traf[c("Sensor_Name", "Archive_Time", "Speed", "Volume")]
  names(ver_traf)<-c("sensor", "time", "speed", "count")
  ver_traf$time<-as.POSIXct(as.character(ver_traf$time), format="%Y-%m-%d %H:%M:%S", tz="America/Chicago")
  ver_traf$wkday<-weekdays(ver_traf$time)
  
  ver_traf
  
}

vermac_name<-function(sensor_data)
{
  sensor_data$sensor<-trimws(sensor_data$sensor, "r")
  sensor_present_name<-sensor_pos[c("data_name", "present_name", "dir")] 
  sensor_data<-merge(x=sensor_data, y=sensor_present_name, by.x="sensor",by.y="data_name", all.x=TRUE )
  

  
  sensor_data
}

mysql_inrix_space<-function(xd_traf)
{
  
  names(xd_traf)<-c("net", "segment", "agg_type", "speed", "tt", "time") 
  xd_traf<-xd_traf[c("segment", "speed", "time")] 
  xd_traf$time<-as.POSIXct(as.character(xd_traf$time), 
                           tz="America/Chicago", format='%Y-%m-%d %H:%M:%S')
  xd_traf$segment<-trimws(xd_traf$segment, "r")
  
  xd_traf
}
mysql_inrix_5minute<-function(time_range )
{
  xd_speed<-data.frame()
  for (i in 1:(length(time_range)-1))
  {
    df<-xd_traf[between(xd_traf$time, time_range[i], time_range[i+1]), ]
    if (dim(df)[1]==0) 
      next
    
    df<-aggregate(df$speed, by=list(df$segment), FUN=mean)
    names(df)<-c("segment", "speed")
    df<-data.frame(df, time=time_range[i])
    xd_speed<-rbind(xd_speed, df)
  }  
}
mysql_roadname<-function(xd_traf)
{
  xd_traf$id<-NA
  pos_detect<-which(str_detect(xd_traf$segment, paste(c("I 35", 'I-35'), collapse='|')))
  xd_traf$id[pos_detect]<-substr(xd_traf$segment[pos_detect], start=8, stop=nchar(xd_traf$segment[pos_detect]))
  pos_detect<-which(str_detect(xd_traf$segment, paste(c("uS 183", 'US-183'), collapse='|')))
  xd_traf$id[pos_detect]<-substr(xd_traf$segment[pos_detect], start=10, stop=nchar(xd_traf$segment[pos_detect]))
  
  
  xd_traf
}
get_inrix_forqueue<-function(inrix_closure, inrix_historical, time_range)
{
  
  raw_tmc$time<-as.POSIXct(raw_tmc$time,  format='%Y-%m-%d %H:%M:%S', tz='America/Chicago')
  raw_tmc$hr_min<-strftime(raw_tmc$time, '%H:%M')
  date_tmc<-filter(raw_tmc, raw_tmc$time%in%tmc_time_seq$time)
  
  raw_tmc<-filter(raw_tmc, (weekdays(as.Date(raw_tmc$time))==weekdays(stime) & 
                              (raw_tmc$hr_min %in% strftime(filter(tmc_time_seq, weekdays(tmc_time_seq$time)==weekdays(stime))$time, '%H:%M'))) 
                  |
                    (weekdays(as.Date(raw_tmc$time))==weekdays(etime) & 
                       (raw_tmc$hr_min %in% strftime(filter(tmc_time_seq, weekdays(tmc_time_seq$time)==weekdays(etime))$time, '%H:%M')))
  )
  csegment<-tmc_time_seq
  asegment<-tmc_time_seq
  
  
  for(s in 1:nrow(queue_range))
  {
    #date data
    dt<-tmc_time_seq
    date_seg<-filter(date_tmc, date_tmc$code==queue_range$tmc[s])
    dt<-merge(x=dt, y=date_seg, by.x='time', by.y='time', all.x=TRUE)
    dt<-dt[c('speed')]
    csegment<-cbind(csegment, dt) 
    
    #avg data
    avg_seg<-filter(raw_tmc, raw_tmc$code==queue_range$tmc[s])
    dt<-data.frame(time=strftime(tmc_time_seq$time, '%H:%M'))
    df<-aggregate(avg_seg$speed, by=list(avg_seg$hr_min), FUN=mean,na.rm=TRUE)
    dt<-merge(dt, df, by.x='time', by.y='Group.1', all.x=TRUE, sort = FALSE)
    dt<-data.frame(lapply(dt[c('x')], as.integer))
    asegment<-cbind(asegment, dt) 
    
  }
  names(csegment)<-c('time', queue_range$tmc)
  names(asegment)<-c('time', queue_range$tmc)
  csegment<-select(csegment, -'time')
  asegment<-select(asegment, -'time')
  
  out<-list()
  out$all_tmc<-asegment
  out$date_tmc<-csegment
  out$time_seq<-tmc_time_seq1
  
  out
}

distance_calculate<-function(sensor_position)
{
  dt<-sensor_position
  dt$dis<-NA
  for ( i in 1: nrow(dt))
  {
    sensor_name<-dt$sensor_name[i]
    sensor_lon<-as.double(dt$long[i])
    sensor_lat<-as.double(dt$lat[i])
    if (is.na(sensor_lon)| is.na(sensor_lat))
      next
    sensor_dir<-dt$dir[i]
    df<-filter(route_dis, route_dis$dir==sensor_dir)
    
    if (sensor_dir ==  "WB"){
      slink<-filter(df, df$slon>=sensor_lon)
      elink<-filter(df, df$elon<=sensor_lon)       
    }else if( sensor_dir ==  "EB"){
      slink<-filter(df, df$slon<=sensor_lon)
      elink<-filter(df, df$elon>=sensor_lon)       
    }else if (sensor_dir ==  "NB"){
      slink<-filter(df, df$slat<=sensor_lat)
      elink<-filter(df,df$elat>=sensor_lat)    
    }else{
      slink<-filter(df, df$slat>=sensor_lat)
      elink<-filter(df,df$elat<=sensor_lat)    
    }
    
    link_intersect<-intersect(slink$link, elink$link)
    occupied_link<-filter(df, df$link %in%  link_intersect)
    if (length(link_intersect)>1)
    {
      paste(sensor_name,i, sep=" ")
      df<-occupied_link
      df$sensor_lon<-sensor_lon
      df$sensor_lat<-sensor_lat
      distance<-pointDistance(cbind(df$elon, df$elat),
                              cbind(df$sensor_lon, df$sensor_lat),
                              lonlat=FALSE,
                              type='GreatCircle')*3.28 #feet
      closed_link<-df[which(distance==min(distance)), ]$link
      occupied_link<-filter(occupied_link, occupied_link$link==closed_link)
    }
    occupied_link$point_distance<-(pointDistance(c(occupied_link$elon, occupied_link$elat),
                                                 c(sensor_lon, sensor_lat),
                                                 lonlat=FALSE,
                                                 type='GreatCircle')* 349669.6) #feet)
    
    # df1<-data.frame(sensor=sensor_name, occupied_link)
    # sensor_on_link<-rbind(sensor_on_link, df1)
    dt$dis[i]<-round((occupied_link$dis-(pointDistance(c(occupied_link$elon, occupied_link$elat),
                                                                   c(sensor_lon, sensor_lat),
                                                                   lonlat=FALSE,
                                                                   type='GreatCircle')* 349669.6))/5280, 1) #feet)
  }
  
  dt
}










#tab1
time_period_selection<-function(sdate, edate, stime, etime)
{
  out<-data.frame()
  for (i in 0:difftime(edate, sdate))
  {
    sd<-(sdate+i)
    if (stime>etime){ed<-(sdate+i+1)}else
    {ed<-(sdate+i)}
    
    st<-as.POSIXct(paste(sd, " ", stime,":00", sep=""),format= "%Y-%m-%d %H:%M" , tz="America/Chicago")
    et<-as.POSIXct(paste(ed, " ", etime,":00", sep=""), format= "%Y-%m-%d %H:%M" , tz="America/Chicago")
    
    df<-data.frame(Period=as.integer(i+1), From=st, To=et)
    out<-rbind(out, df)
  }
  
  
  out
  
}
get_trailer_traffic_data<-function(trailer_name, trailer_period)
{
  tr_name<-paste(trailer_name, collapse="' or loc_dir ='")
  query1<- paste("select * from wkz_all where loc_dir = '",tr_name, "' ", sep='')
  drv <- dbDriver("PostgreSQL")
  con <-
    dbConnect(
      drv,
      dbname = net,
      host = server,
      port = 5432,
      user = uname,
      password = pwd
    )
  
  trailer_raw<- dbGetQuery(con,   query1 )  
  dbDisconnect(con)
  
  trailer_raw<-trailer_raw[c("time","loc_dir", "count", "speed")]
  trailer_raw$time<-as.POSIXct(trailer_raw$time, tz='America/Chicago', format = "%Y:%m:%d:%H:%M:%S")
  trailer_raw$date<-as.Date(trailer_raw$time, tz="America/Chicago")
  trailer_raw$hr<-as.integer(strftime(trailer_raw$time, tz="America/Chicago", format="%H"))
  trailer_raw$wkday<-weekdays(trailer_raw$time)
  trailer_raw$name<-substr(trailer_raw$loc_dir, start=12, stop=nchar(trailer_raw$loc_dir))
  
  trailer_for_selection<-data.frame()
  for (i in 1: nrow(trailer_period))
  {
    df<-filter(trailer_raw, trailer_raw$time>= trailer_period$From[i])
    df<-filter(df, df$time<= trailer_period$To[i])
    trailer_for_selection<-rbind(trailer_for_selection, df)
  }
  
  trailer_for_average<-data.frame()
  for (i in 1: nrow(trailer_period))
  {
    swkday<-weekdays(trailer_period$From[i])
    ewkday<-weekdays(trailer_period$To[i])
    shr<-as.integer(strftime(trailer_period$From[i], tz="America/Chicago", format="%H"))
    ehr<-as.integer(strftime(trailer_period$To[i], tz="America/Chicago", format="%H"))
    
    df<-filter(trailer_raw, trailer_raw$wkday== swkday)
    df<-filter(df, df$hr>=shr)
    trailer_for_average<-rbind(trailer_for_average, df)
    
    df<-filter(trailer_raw, trailer_raw$wkday== ewkday)
    df<-filter(df, df$hr<=ehr)
    trailer_for_average<-rbind(trailer_for_average, df)   
  }
  
  trailer_for_average<-unique(trailer_for_average)
  
  trailer_availability<-data.frame(trailer=trailer_name)
  for (i in 1:nrow(trailer_period))
  {
    df<-rep("X", times=length(trailer_name))
    for (j in 1:nrow(trailer_availability))
    {
      df1<-filter(trailer_for_selection, trailer_for_selection$loc_dir ==trailer_name[j])
      df1<-filter(df1, df1$time>=trailer_period$From[i])
      df1<-filter(df1, df1$time<=trailer_period$To[i])
      if (nrow(df1)>0 ) df[j]<-"O"
    }
    trailer_availability<-cbind(trailer_availability, df)
  }
  names(trailer_availability)<-c("Name", c(1:nrow(trailer_period)))
  trailer_availability$Name<-substr(trailer_availability$Name, start=12, stop=nchar(as.character(trailer_availability$Name)))
  
  #trailer_average<-filter(trailer_raw, trailer_raw$wkday==weekdays(trailer_date))
  #trailer_date<-filter(trailer_raw, trailer_raw$date==trailer_date)
  #trailer_raw<-data.frame(trailer_raw, dtime=as.POSIXct(trailer_raw$time,tz='America/Chicago', format = "%Y:%m:%d:%H:%M:%S"))  
  #trailer_raw<-data.frame(trailer_raw,  count=trailer_raw$count)  
  
  #  trailer_raw<-select(trailer_raw,  c(time, dtime, speed, count))  
  # trailer_raw<-data.frame(trailer_raw, date=substr(trailer_raw$time, start=6, stop=10))
  #  trailer_raw<-data.frame(trailer_raw, month=as.integer(substr(trailer_rawr$time, start=6, stop=7)))
  #  trailer_raw<-data.frame(trailer_raw, day=as.integer(substr(trailer_raw$time, start=9, stop=10)))
  #  trailer_raw<-data.frame(trailer_raw, hr=as.integer(substr(trailer_raw$time, start=12, stop=13)))
  #  trailer_raw<-data.frame(trailer_raw, min=as.integer(substr(trailer_raw$time, start=15, stop=16)))
  #  trailer_raw<-data.frame(trailer_raw, wkz_date=substr(trailer_raw$time, start=1, stop=1
  out<-list()
  out$average<-trailer_for_average
  out$selection<-trailer_for_selection
  out$availability<-trailer_availability
  
  out
}
get_data<-function(is_wkz,  trailer_date)
{
  #query1<- paste("select * from wkz_jan1 where loc_dir like '%%",dirct, is_wkz, "%%' order by time", sep='')  
  #query1<- paste("select * from wkz_all where loc_dir like '%%",dirct, is_wkz, "%%' order by time", sep='') 
  query1<- paste("select * from wkz_all where loc_dir = '",is_wkz,"' order by time", sep='')
  drv <- dbDriver("PostgreSQL")
  con <-
    dbConnect(
      drv,
      dbname = net,
      host = server,
      port = 5432,
      user = uname,
      password = pwd
    )
  
  trailer_raw<- dbGetQuery(con,   query1 )  
  dbDisconnect(con)
  
  trailer_raw<-data.frame(trailer_raw)
  trailer_raw<-trailer_raw[c("time", "count", "speed")]
  trailer_raw$time<-as.POSIXct(trailer_raw$time,tz='America/Chicago', format = "%Y:%m:%d:%H:%M:%S")
  trailer_raw$date<-as.Date(trailer_raw$time, tz="America/Chicago")
  trailer_raw$wkday<-weekdays(trailer_raw$time)
  trailer_average<-filter(trailer_raw, trailer_raw$wkday==weekdays(trailer_date))
  trailer_date<-filter(trailer_raw, trailer_raw$date==trailer_date)
  #trailer_raw<-data.frame(trailer_raw, dtime=as.POSIXct(trailer_raw$time,tz='America/Chicago', format = "%Y:%m:%d:%H:%M:%S"))  
  #trailer_raw<-data.frame(trailer_raw,  count=trailer_raw$count)  
  
  #  trailer_raw<-select(trailer_raw,  c(time, dtime, speed, count))  
  # trailer_raw<-data.frame(trailer_raw, date=substr(trailer_raw$time, start=6, stop=10))
  #  trailer_raw<-data.frame(trailer_raw, month=as.integer(substr(trailer_rawr$time, start=6, stop=7)))
  #  trailer_raw<-data.frame(trailer_raw, day=as.integer(substr(trailer_raw$time, start=9, stop=10)))
  #  trailer_raw<-data.frame(trailer_raw, hr=as.integer(substr(trailer_raw$time, start=12, stop=13)))
  #  trailer_raw<-data.frame(trailer_raw, min=as.integer(substr(trailer_raw$time, start=15, stop=16)))
  #  trailer_raw<-data.frame(trailer_raw, wkz_date=substr(trailer_raw$time, start=1, stop=10))
  
  
  out<-list()
  out$average<-(trailer_average)
  out$date<-(trailer_date)
  
  out
}
trailer_data_output<-function(trailer_period, time_unit, raw_traffic)
{
  trailer_raw_average<-raw_traffic$average
  trailer_raw_selection<-raw_traffic$selection
  
  trailer_raw_average$mins<-(as.integer(strftime(trailer_raw_average$time, tz="America/Chicago", format="%H"))*60+
                               as.integer(strftime(trailer_raw_average$time, tz="America/Chicago", format="%M")))
  trailer_aggregate<-data.frame()
  
  for (i in 1: nrow(trailer_period))
  {
    time_sequence<-seq(trailer_period$From[i], trailer_period$To[i], (time_unit*60))
    weekday_sequence<-weekdays(time_sequence)
    mins_sequence<-(as.integer(strftime(time_sequence, tz="America/Chicago", format="%H"))*60+
                      as.integer(strftime(time_sequence, tz="America/Chicago", format="%M")))
    
    for (j in 1: (length(time_sequence)-1))
    {
      
      df_selection<-filter(trailer_raw_selection, trailer_raw_selection$time>=time_sequence[j])
      df_selection<-filter(df_selection, df_selection$time<=time_sequence[j+1])
      
      
      df_average<-filter(trailer_raw_average, trailer_raw_average$mins>=mins_sequence[j])
      df_average<-filter( df_average,  df_average$wkday==weekday_sequence[j])    
      if (mins_sequence[j]< (24*60-time_unit))
      {
        df_average<-filter(df_average, df_average$mins<=mins_sequence[j+1])
        df_average<-filter( df_average,  df_average$wkday==weekday_sequence[j+1]) 
      }
      
      if (nrow(df_selection)>0)
      {
        count_selection<-aggregate(df_selection$count, by=list(name=df_selection$name), FUN=sum)
        speed_selection<-aggregate(df_selection$speed, by=list(name=df_selection$name), FUN=mean)         
      }
      
      count_average<-data.frame()
      unique_average_trailer<- unique(df_average$name)
      for (tr in 1:  length(unique_average_trailer))
      {
        df<-filter(df_average, df_average$name==unique_average_trailer[tr])
        df<-aggregate(df$count, by=list(date=df$date), FUN=sum)
        df<-data.frame(name=unique_average_trailer[tr], x=as.integer(mean(df$x)))
        count_average<-rbind(count_average, df)
      }
      speed_average<-aggregate(df_average$speed, by=list(name=df_average$name), FUN=mean)   
      
      if (nrow(df_selection)>0)
      {
        df<-data.frame(time=time_sequence[j], period=i, type="selection", name=count_selection$name, count=count_selection$x, speed=as.integer(speed_selection$x))
        trailer_aggregate<-rbind(trailer_aggregate, df)
      }
      df1<-data.frame(time=time_sequence[j],period=i,  type="average", name=count_average$name, count=count_average$x, speed=as.integer(speed_average$x))
      trailer_aggregate<-rbind(trailer_aggregate, df1)
      
    }
  }
  
  trailer_aggregate
  
}

#tab2
get_tmc<-function(wkz_time)
{
  query1<- paste("select * from tmc where time like '%%",wkz_time, "%%' ", sep='')  
  drv <- dbDriver("PostgreSQL")
  con <-
    dbConnect(
      drv,
      dbname = net,
      host = server,
      port = 5432,
      user = uname,
      password = pwd
    )
  tmc<- dbGetQuery(con,   query1 )  
  dbDisconnect(con)    
  
  tmc
}
get_his_wkz_info<-function(id)
{
  q<-paste("select * from cnstrt where id =", id, sep="")
  drv <- dbDriver("PostgreSQL")
  con <-
    dbConnect(
      drv,
      dbname = net,
      host = server,
      port = 5432,
      user = uname,
      password = pwd
    )  
  his_wkz_info<- dbGetQuery(con, q)
  dbDisconnect(con)
  
  his_wkz_info<-his_wkz_info[c("id", "starttime", "endtime", "weekday", "fromloc", "toloc", "closure")]
  
  his_wkz_time<-his_wkz_info[c("starttime", "endtime", "weekday")]
  his_wkz_loc<-his_wkz_info[c("fromloc", "toloc", "closure")]
  names(his_wkz_time)<-c("Start Time", "End Time", "Day of Week")
  names(his_wkz_loc)<-c("From Location", "To Location", "Closure")
  
  out<-list()
  out$time<-his_wkz_time
  out$loc<-his_wkz_loc
  
  
  out
}
#tab3
get_tmc_forqueue<-function(queue_range, stime, etime)
{
  q<-paste("select * from tmc where (code ='", sep = "")
  for (i in 1 : nrow(queue_range) )
  {
    q<-paste(q, queue_range$tmc[i],"'", sep="")
    if (i< nrow(queue_range))
      q<-paste(q, " or code ='", sep="")
  }
  q<-paste(q, ")", sep="")
  
  drv <- dbDriver("PostgreSQL")
  con <-
    dbConnect(
      drv,
      dbname = net,
      host = server,
      port = 5432,
      user = uname,
      password = pwd
    )
  raw_tmc<- dbGetQuery(con, q)
  dbDisconnect(con)
  
  tmc_time_seq<-seq(from=stime, to=etime, by=300)
  tmc_time_seq1<-seq(from=stime, to=etime, by=300)
  tmc_time_seq<-data.frame(time=tmc_time_seq)
  
  
  raw_tmc$time<-as.POSIXct(raw_tmc$time,  format='%Y-%m-%d %H:%M:%S', tz='America/Chicago')
  raw_tmc$hr_min<-strftime(raw_tmc$time, '%H:%M')
  date_tmc<-filter(raw_tmc, raw_tmc$time%in%tmc_time_seq$time)
  
  raw_tmc<-filter(raw_tmc, (weekdays(as.Date(raw_tmc$time))==weekdays(stime) & 
                              (raw_tmc$hr_min %in% strftime(filter(tmc_time_seq, weekdays(tmc_time_seq$time)==weekdays(stime))$time, '%H:%M'))) 
                  |
                    (weekdays(as.Date(raw_tmc$time))==weekdays(etime) & 
                       (raw_tmc$hr_min %in% strftime(filter(tmc_time_seq, weekdays(tmc_time_seq$time)==weekdays(etime))$time, '%H:%M')))
  )
  csegment<-tmc_time_seq
  asegment<-tmc_time_seq
  
  
  for(s in 1:nrow(queue_range))
  {
    #date data
    dt<-tmc_time_seq
    date_seg<-filter(date_tmc, date_tmc$code==queue_range$tmc[s])
    dt<-merge(x=dt, y=date_seg, by.x='time', by.y='time', all.x=TRUE)
    dt<-dt[c('speed')]
    csegment<-cbind(csegment, dt) 
    
    #avg data
    avg_seg<-filter(raw_tmc, raw_tmc$code==queue_range$tmc[s])
    dt<-data.frame(time=strftime(tmc_time_seq$time, '%H:%M'))
    df<-aggregate(avg_seg$speed, by=list(avg_seg$hr_min), FUN=mean,na.rm=TRUE)
    dt<-merge(dt, df, by.x='time', by.y='Group.1', all.x=TRUE, sort = FALSE)
    dt<-data.frame(lapply(dt[c('x')], as.integer))
    asegment<-cbind(asegment, dt) 
    
  }
  names(csegment)<-c('time', queue_range$tmc)
  names(asegment)<-c('time', queue_range$tmc)
  csegment<-select(csegment, -'time')
  asegment<-select(asegment, -'time')
  
  out<-list()
  out$all_tmc<-asegment
  out$date_tmc<-csegment
  out$time_seq<-tmc_time_seq1
  
  out
}
na_estimate<-function(date_tmc, queue_range)
{
  s_tmc<-date_tmc
  for (i in 1: nrow(s_tmc))
  {
    na<-which(is.na(s_tmc[i, ]))
    if (length(na)==0) next
    if (min(na)==1)
    {
      a<-which((s_tmc[i, ])>0)    
      s_tmc[i, 1]<-s_tmc[i,min(a)]
      na<-na[!na %in% 1]
    }
    if(max(na)==nrow(queue_range))
    {
      a<-which((s_tmc[i, ])>0)
      s_tmc[i, nrow(queue_range)]<-s_tmc[i,max(a)]
      na<-na[!na %in% max(na)]
    }  
    for (j in na)
    {
      na<-which(is.na(s_tmc[i, ]))
      a<-which((s_tmc[i, ])>0)    
      up<-max(which(a<j))
      dn<-min(which(a>j))         
      s_tmc[i, j]<-as.integer((s_tmc[i, a[up]]+s_tmc[i, a[dn]])/2)
    }
  }
  
  s_tmc
}
queue_estimate<-function(queue_range, date_tmc, ffs) 
{
  s_tmc<-date_tmc
  uplth<-data.frame(uplth=double())
  dnlth<-data.frame(dnlth=double())
  medlth<-data.frame(melth=double())
  updis<-data.frame(updis=double())
  dndis<-data.frame(updis=double())
  for (i in 1: nrow(s_tmc))
  {
    minspd<-min(s_tmc[i,])
    if (minspd< 20) 
    {
      s<-which.min(apply(s_tmc[i,],MARGIN=2,min))
      up<-s_tmc[i,1:s]
      if (length(which(up>ffs)) > 0)
      {
        uptmc<-max(which(up[1,]>ffs))
        if (s==(uptmc+1))
          ulth<-0
        else
          ulth<-sum(queue_range$length[(uptmc+1):(s-1)])*((sum(s_tmc[i, (uptmc+1):(s-1)]*queue_range$length[(uptmc+1):(s-1)])/sum(queue_range$length[(uptmc+1):(s-1)]))-s_tmc[i, (uptmc)])/(s_tmc[i, s]-s_tmc[i, (uptmc)])
        #uprto<-uplth
      }else
      {
        ulth<-sum(queue_range$length[1:s-1])
        # uprto<-uplth
      }
      uplth<-rbind(uplth, ulth)
      
      s<-max(which(s_tmc[i, ]==minspd)) 
      dn<-s_tmc[i, s:length(s_tmc)]
      if (length(which(dn>ffs)) > 0)
      {
        dntmc<-min(which(dn>ffs))+s-1  
        if (s==(dntmc-1))
          dlth<-0
        else
          dlth<-sum(queue_range$length[(s+1):(dntmc-1)])*(s_tmc[i, dntmc]-sum(s_tmc[i, (s+1):(dntmc-1)]*queue_range$length[(s+1):(dntmc-1)])/sum(queue_range$length[(s+1):(dntmc-1)]))/(s_tmc[i, dntmc]-s_tmc[i, s])
        #uprto<-uplth
      }else if (s==nrow(queue_range)){
        dlth<-0
      }else
        dlth<-sum(queue_range$length[(s+1):nrow(queue_range)])
      
      dnlth<-rbind(dnlth, dlth)
      
      melth<-sum(queue_range$length[which(s_tmc[i, ]==minspd)])
      medlth<-rbind(medlth, melth)
      
      upd<-sum(queue_range$length[1:(s-1)])-ulth
      updis<-rbind(updis, upd)   
      dnd<-sum(upd, ulth, dlth, melth) 
      dndis<-rbind(dndis,dnd)         
    }else
    {
      uplth<-rbind(uplth, 0)
      dnlth<-rbind(dnlth, 0)  
      medlth<-rbind(medlth, 0)
      dndis<-rbind(dndis,0) 
      updis<-rbind(updis, 0)   
    }
    
  }
  
  lth<-uplth+medlth+dnlth
  names(lth)<-c('length')
  qlth<-data.frame( s_tmc, lth)
  
  quedis<-data.frame(updis, dndis,dndis-updis)
  names(quedis)<-c('up', 'dn', 'queue')  
  
  output<-list()
  output$queue<-qlth
  output$dque<-quedis
  
  output
}
queue_delay<-function(queue_range, date_tmc, all_tmc, pcost, tcost, tratio, lanes)
{
  s_tmc<-date_tmc
  a_tmc<-all_tmc
  
  pratio<-(1-tratio)
  if (nrow(s_tmc)!= nrow(a_tmc))
    print('error')
  
  
  df<-data.frame()
  for (i in 1:nrow(a_tmc))
  {
    upbound_time<-0
    dnbound_time<-0
    upbound_cost<-0
    dnbound_cost<-0
    d<-data.frame()
    for(j in 1 :ncol(a_tmc))
    {
      as<-as.integer(a_tmc[i,j])
      cs<-as.integer(s_tmc[i,j])
      if (as==0) as<-1
      if (cs==0) cs<-1
      
      if(as>65) as<-65
      if(cs>65) cs<-65
      if(as>cs)
      {
        qrow<-j
        dt<-((queue_range$length[qrow]/cs)-(queue_range$length[qrow]/as))
        af<-filter(FD, FD$spd==as)
        cf<-filter(FD, FD$spd==cs)
        aflow<-((af$flow[1])/12*lanes)
        cflow<-((cf$flow[1])/12*lanes)
        
        upbound_time<-(upbound_time+dt*aflow)
        dnbound_time<-(dnbound_time+dt*cflow)
        
        upbound_cost<-(upbound_cost+dt*(aflow*(tratio*tcost+pratio*pcost)))
        dnbound_cost<-(dnbound_cost+dt*cflow*(tratio*tcost+pratio*pcost))
      }
    }
    d<-data.frame(upbound_time, dnbound_time, upbound_cost, dnbound_cost)
    df<-rbind(df, d)
  }
  
  delay<-data.frame(df)
  names(delay)<-c('up_time','dn_time', 'up_cost', 'dn_cost')
  
  delay
}
trailer_impact_area_speed<-function(queue_range, tmc_time_seq,wkz_trailer_location)
{
  tmc_date<-unique(as.Date(tmc_time_seq, tz="America/Chicago"))
  wkz_trailer_name<-paste(wkz_trailer_location$loc_dir, collapse="','")
  tmc_date_format<-strftime(tmc_date, "%Y:%m:%d")
  q<-paste("select * from wkz_all where  loc_dir in ('", wkz_trailer_name, "') and (time like '%", tmc_date_format[1], "%' or time like '%", tmc_date_format[2],"%')", sep="")
  
  queue_range$dis<-cumsum(queue_range$length)
  
  drv <- dbDriver("PostgreSQL")
  con <-
    dbConnect(
      drv,
      dbname = net,
      host = server,
      port = 5432,
      user = uname,
      password = pwd
    )
  wkz_trailer_speed<- dbGetQuery(con, q)
  dbDisconnect(con)
  if (nrow(wkz_trailer_speed) != 0)
  {
    wkz_trailer_speed<-wkz_trailer_speed[c("loc_dir", "speed", "time")]
    wkz_trailer_speed$time<-as.POSIXct(wkz_trailer_speed$time, tz="America/Chicago", format="%Y:%m:%d:%H:%M:%S")
    
    for (i in 1: nrow(wkz_trailer_speed))
    {
      df<-filter(wkz_trailer_location, wkz_trailer_location$loc_dir==wkz_trailer_speed$loc_dir[i])
      a<-which(queue_range$tmc==df$tmc)    
      wkz_trailer_speed$tmc[i]<-df$tmc
      wkz_trailer_speed$length[i]<-df$length
      if (a>1)
        wkz_trailer_speed$dis[i]<-(queue_range$dis[a-1]+ wkz_trailer_speed$length[i]) else 
          wkz_trailer_speed$dis[i]<-wkz_trailer_speed$length[i]
    } 
  }
  
  wkz_trailer_speed
}
collect_tmc_trailer_flow_function<-function(tmc_id, tmc_time_seq) 
{
  trailer_info<-filter(all_trailer_tmc_locations,all_trailer_tmc_locations$tmc==tmc_id )
  
  date_wkz_trailer_aggregate<-list()
  date_wkz_trailer_flow<-data.frame()
  avg_wkz_trailer_aggregate<-list()
  if (nrow(trailer_info)>0)
  {
    wkz_trailer_name<-paste(trailer_info$loc_dir, collapse="','")
    tmc_date<-unique(as.Date(tmc_time_seq, tz="America/Chicago"))
    tmc_date_format<-strftime(tmc_date, "%Y:%m:%d")
    #q<-paste("select * from wkz_all where  loc_dir in ('", wkz_trailer_name, "') and (time like '%", tmc_date_format[1], "%' or time like '%", tmc_date_format[2],"%')", sep="")
    q<-paste("select * from wkz_all where  loc_dir in ('", wkz_trailer_name, "')", sep="")
    
    drv <- dbDriver("PostgreSQL")
    con <-
      dbConnect(
        drv,
        dbname = net,
        host = server,
        port = 5432,
        user = uname,
        password = pwd
      )
    #trai
    raw_wkz_trailer<- dbGetQuery(con, q)
    dbDisconnect(con)
    raw_wkz_trailer<-raw_wkz_trailer[c("loc_dir", "time", "count")]
    raw_wkz_trailer$time<-as.POSIXct(raw_wkz_trailer$time, tz="America/Chicago", format="%Y:%m:%d:%H:%M:%S")
    raw_wkz_trailer$wkday<-weekdays(raw_wkz_trailer$time)
    
    wkz_wkday<-weekdays(tmc_time_seq)
    wkz_dates<-as.Date(tmc_time_seq, tz="America/Chicago") 
    wkz_times<-strftime(tmc_time_seq, tz="America/Chicago", format="%H:%M")
    wkz_mins<-(as.integer(strftime(tmc_time_seq, tz="America/Chicago", format="%H"))*60+
                 as.integer(strftime(tmc_time_seq, tz="America/Chicago", format="%M"))
    )
    
    avg_wkz_trailer<-filter(raw_wkz_trailer, raw_wkz_trailer$wkday %in% wkz_wkday)  
    avg_wkz_trailer$mins<-(as.integer(strftime(avg_wkz_trailer$time, tz="America/Chicago", format="%H"))*60+
                             as.integer(strftime(avg_wkz_trailer$time, tz="America/Chicago", format="%M"))
    )
    avg_wkz_trailer$date<-strftime(avg_wkz_trailer$time, tz="America/Chicago", format="%Y-%m-%d") 
    
    # avg_wkz_trailer$temp<-paste(avg_wkz_trailer$wkday, "_", avg_wkz_trailer$hr_min, sep="")
    # avg_wkz_trailer<-filter(avg_wkz_trailer, avg_wkz_trailer$temp %in%  wkz_dtime)
    
    # date_wkz_trailer<-filter(raw_wkz_trailer, raw_wkz_trailer$time<max(tmc_time_seq))
    
    #for table
    for (tr in 1:nrow(trailer_info))
    {  
      df<-filter(avg_wkz_trailer, avg_wkz_trailer$loc_dir== trailer_info$loc_dir[tr])
      avg_dt<-data.frame()
      date_dt<-data.frame()
      for (i in 1:(length(tmc_time_seq)-1))
      {
        df1<-filter(df, df$wkday== wkz_wkday[i])
        df1<-filter(df1, df1$mins>= wkz_mins[i])
        if(wkz_mins[i]< 1435)
        {
          df1<-filter(df1,df1$mins< wkz_mins[i+1])
        }
        
        if (nrow(df1)==0)
        {
          df3<-data.frame(loc_dir= trailer_info$loc_dir[tr], time= tmc_time_seq[i], count=0)
          df4<-data.frame(loc_dir= trailer_info$loc_dir[tr], time= tmc_time_seq[i], count=0)
          
        }else
        {
          df3<-data.frame(loc_dir= trailer_info$loc_dir[tr], time= tmc_time_seq[i], count=as.integer((sum(df1$count)/length(unique(df1$date)))))
          df4<-filter(df1,df1$date== wkz_dates[i])
          df4<-data.frame(loc_dir= trailer_info$loc_dir[tr], time= tmc_time_seq[i], count=sum(df4$count))
        } 
        avg_dt<-rbind(avg_dt, df3)
        date_dt<-rbind(date_dt, df4)     
        
      }
      avg_wkz_trailer_aggregate[[tr]]<-data.frame(avg_dt)
      date_wkz_trailer_aggregate[[tr]]<-data.frame(date_dt)    
      
    }
    
    #for plot
    for (i in 1:(length(tmc_time_seq)-1))
    {
      df<-filter(avg_wkz_trailer, avg_wkz_trailer$time>= tmc_time_seq[i])
      df<-filter(df,df$time< tmc_time_seq[i+1])
      if (nrow(df)>0)
      {
        df1<-aggregate(df$count, by=list(df$loc_dir), FUN=sum)
        names(df1)<-c("loc_dir", "count")
        df1<-data.frame(time=tmc_time_seq[i], df1)
        date_wkz_trailer_flow<-rbind(date_wkz_trailer_flow, df1)      
      }
    }
  }
  
  out<-list()
  out$avg_table<-avg_wkz_trailer_aggregate
  out$date_table<-date_wkz_trailer_aggregate
  out$date_plot<-date_wkz_trailer_flow
  out$trailer_info<-trailer_info
  out
  
}
estimate_tmc_flow_function<-function(tmc_id,tmc_lanes, date_tmc, all_tmc, queue_range, tmc_time_seq)
{
  wkz_dur<-data.frame(date_tmc$time, date_tmc$hr, date_tmc$min)
  date_tmc<-date_tmc[(length(wkz_dur)+1):(length(wkz_dur)+nrow(queue_range))]
  all_tmc<-all_tmc[(length(wkz_dur)+1):(length(wkz_dur)+nrow(queue_range))]
  
  a<-which(queue_range$tmc==tmc_id)
  date_tmc<-date_tmc[a]
  all_tmc<-all_tmc[a]
  names(date_tmc)<-"speed"
  names(all_tmc)<-"speed"  
  for (i in 1:nrow(date_tmc))
  {
    spd<-as.integer(date_tmc$speed[i])
    if (spd>65) spd<-65
    a<-which(FD$spd==spd)
    date_tmc$count[i]<-(FD$flow[a]/12*tmc_lanes)
    
    spd<-as.integer(all_tmc$speed[i])
    if (spd>65) spd<-65
    a<-which(FD$spd==spd)
    all_tmc$count[i]<-(FD$flow[a]/12*tmc_lanes)
  }
  
  date_tmc<-data.frame(time = tmc_time_seq, speed=as.integer(date_tmc$speed), count=as.integer(date_tmc$count))
  all_tmc<-data.frame(time =  tmc_time_seq, speed=as.integer(all_tmc$speed), count=as.integer(all_tmc$count))
  
  
  date_tmc<-filter(date_tmc, date_tmc$time<tmc_time_seq[length(tmc_time_seq)])
  all_tmc<-filter(all_tmc, all_tmc$time<tmc_time_seq[length(tmc_time_seq)])
  
  out<-list()
  out$date_tmc<-date_tmc
  out$all_tmc<-all_tmc  
  
  out
}



#not available
function1<-function(a, b)
{
  if (is.null(a)) b<-b
  else b<-b+1
}
fun_dens<-function(interval, dt_output)
{
  wkz_interval<-as.integer(interval)
  fc<-c("fcnt")
  dt_output[,fc ]<-NA
  for (i in 1:nrow(dt_output))
  {
    df<-filter(FD, FD$spd==dt_output$speed[i])
    counts<-as.integer(df$Density[1]*dt_output$speed[i]*wkz_interval/60)
    dt_output$fcnt[i]<-counts
  }
  
  dt_output
  
}
analyze<-function(tint,trf_data)
{
  traffic_output<-data.frame(interval=integer(), dtime=as.POSIXct(character()), speed=integer(),
                             volume=integer(),  stringsAsFactors=FALSE)
  
  time_interval<-as.integer(tint)
  seg<-60*24/time_interval
  
  
  for (i in 1: seg)
  {
    cycle<-i * time_interval
    df<-filter(trf_data,  trf_data$hr*60+trf_data$min < cycle 
               & trf_data$hr*60+trf_data$min >= cycle-time_interval)
    
    dff<-filter(df, df$speed > 0)
    if (nrow(dff) > 0)
    {
      
      df1<-data.frame(interval = cycle, dtime=as.POSIXct(paste(cycle%/%60, ":", cycle%%60, sep=""), format="%H:%M"),
                      speed=as.integer(sum(dff$speed)/count(dff)), count=as.integer(sum(dff$count)/length(unique(dff$date)))
      )
    }
    else
      df1<-data.frame(interval = cycle, dtime=as.POSIXct(paste(cycle%/%60, ":", cycle%%60, sep=""), format="%H:%M"),
                      speed=0, count=0
      )
    
    
    traffic_output<-rbind(traffic_output, df1)
  }
  
  traffic_output
}
date_volume_estimation<-function(tmc_id, date_tmc, queue_range, tmc_time_seq)
{
  a<-which(queue_range$tmc==tmc_id)
  
  trailer_info<-filter(all_trailer_tmc_locations,all_trailer_tmc_locations$tmc==tmc_id )
  
  wkz_trailer_aggregate<-list()
  wkz_trailer_flow<-data.frame()
  if (nrow(trailer_info)>0)
  {
    wkz_trailer_name<-paste(trailer_info$loc_dir, collapse="','")
    tmc_date<-unique(as.Date(tmc_time_seq, tz="America/Chicago"))
    tmc_date_format<-strftime(tmc_date, "%Y:%m:%d")
    q<-paste("select * from wkz_all where  loc_dir in ('", wkz_trailer_name, "') and (time like '%", tmc_date_format[1], "%' or time like '%", tmc_date_format[2],"%')", sep="")
    drv <- dbDriver("PostgreSQL")
    con <-
      dbConnect(
        drv,
        dbname = net,
        host = server,
        port = 5432,
        user = uname,
        password = pwd
      )
    #trai
    wkz_trailer_data<- dbGetQuery(con, q)
    dbDisconnect(con)
    wkz_trailer_data<-wkz_trailer_data[c("loc_dir", "time", "count")]
    wkz_trailer_data$time<-as.POSIXct(wkz_trailer_data$time, tz="America/Chicago", format="%Y:%m:%d:%H:%M:%S")
    
    for (tr in 1:nrow(trailer_info))
    {  
      df<-filter(wkz_trailer_data, wkz_trailer_data$loc_dir== trailer_info$loc_dir[tr])
      dt<-data.frame()
      for (i in 1:(length(tmc_time_seq)-1))
      {
        df1<-filter(df, df$time>= tmc_time_seq[i])
        df2<-filter(df1,df1$time< tmc_time_seq[i+1])
        if (nrow(df2)==0)
        {
          df3<-data.frame(loc_dir= trailer_info$loc_dir[tr], time= tmc_time_seq[i], count=0)
        }else
        {
          df3<-data.frame(loc_dir= trailer_info$loc_dir[tr], time= tmc_time_seq[i], count=sum(df2$count))
        }
        dt<-rbind(dt, df3)
        
      }
      wkz_trailer_aggregate[[tr]]<-data.frame(dt)
    }
    
    for (i in 1:(length(tmc_time_seq)-1))
    {
      df<-filter(wkz_trailer_data, wkz_trailer_data$time>= tmc_time_seq[i])
      df<-filter(df,df$time< tmc_time_seq[i+1])
      df1<-aggregate(df$count, by=list(df$loc_dir), FUN=sum)
      names(df1)<-c("loc_dir", "count")
      df1<-data.frame(time=tmc_time_seq[i], df1)
      wkz_trailer_flow<-rbind(wkz_trailer_flow, df1)
    }
    
    
  }
  
  
  
  wkz_dur<-data.frame(date_tmc$time, date_tmc$hr, date_tmc$min)
  date_tmc<-date_tmc[(length(wkz_dur)+1):(length(wkz_dur)+nrow(queue_range))]
  date_tmc<-date_tmc[a]
  names(date_tmc)<-"speed"
  for (i in 1:nrow(date_tmc))
  {
    spd<-as.integer(date_tmc$speed[i])
    if (spd>65) spd<-65
    a<-which(FD$spd==spd)
    date_tmc$count[i]<-FD$Flow[a]
  }
  date_tmc$time<-tmc_time_seq
  
  flow_estimation<-data.frame(time=tmc_time_seq, date_tmc$speed, date_tmc$count)
  flow_estimation<-filter(flow_estimation, flow_estimation$time<tmc_time_seq[length(tmc_time_seq)])
  
  for (i in 1:length(wkz_trailer_aggregate))
  {
    dt<-data.frame(wkz_trailer_aggregate[i])
    flow_estimation<-cbind(flow_estimation,dt$count)
  }
  
  data_name<-c(tmc_id,paste(trailer_info$loc_dir) )
  data_name<-paste("date_", data_name, sep="" )
  names(flow_estimation)<-c("time", "tmc_speed", data_name)
  
  
  out<-list()
  out$tmc<-date_tmc
  out$trailer<-wkz_trailer_flow
  out$flow_table<-flow_estimation
  
  out
}

#Download properly sized icon (leaflet's built-in icon is not customizable)
markerIcon <-
  makeIcon(iconUrl = 'http://icons.iconarchive.com/icons/icons-land/vista-map-markers/32/Map-Marker-Marker-Outside-Azure-icon.png',
           iconAnchorX = 16,
           iconAnchorY = 30)



shinyServer(function(input, output, session) {
  
  con <- dbConnect(odbc::odbc(),
               Driver = "SQL Server", #ODBC Driver 13 for SQL Server
                Server = "204.144.121.89",
                  # Server="204.144.121.89",
                Database = "CCAT",
                UID = "sql_ut",
                 # PWD = rstudioapi::askForPassword("")
                 PWD="mEQW43FAbddjJnBJ",
                 Port = 1433)

  
  temp_sensor_info<-dbGetQuery(con, paste('select * from ', temporary_sensor_info, sep=''))
  temp_sensor_id<-dbGetQuery(con, paste('select sensor_id as sensor_id, sensor_name as sensor_name from ', temporary_sensor_loc, sep=''))

  
  temp_sensor_info$stime<-as.POSIXct(temp_sensor_info$stime, format="%m/%d/%Y %H:%M", tz="America/Chicago")
  temp_sensor_info$etime<-as.POSIXct(temp_sensor_info$etime, format="%m/%d/%Y %H:%M", tz="America/Chicago")
  
  temp_sensor_info=data.frame(temp_sensor_info, stringsAsFactors = FALSE) 
  
  #updateSelectInput(session, "closure_id", choices =unique(temp_sensor_info$closure_id), selected=unique(temp_sensor_info$closure_id)[1])
  # updateSelectInput(session, "closure_id", choices =unique(temp_sensor_info$closure_id), selected=NULL)
  # 
  # 
  # 
  # 
  # updateSelectInput(session, "unique_id", 
  #              choices =unique(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1])$uid),
  #             # selected=unique(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1])$uid)[1]
  #             # choices=unique(temp_sensor_info$closure_id),
  #              selected=NULL
  # )
  # 
  # updateDateInput(session,inputId='be_date_start',
  #           value=as.POSIXct(as.character(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1])$stime[1]), tz="America/Chicago"),
  #           min=as.POSIXct(as.character(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1])$etime[1]), tz="America/Chicago"),
  #           max=as.POSIXct(as.character(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1])$stime[1]), tz="America/Chicago")
  #           )
  # 
  # updateDateInput(session,inputId='be_date_end', label ="End",
  #           value=as.POSIXct(as.character(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1])$etime[1]), tz="America/Chicago"),
  #           min=as.POSIXct(as.character(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1])$stime[1]), tz="America/Chicago"),
  #           max=as.POSIXct(as.character(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1])$etime[1]), tz="America/Chicago")
  #           )

  
  
  dbDisconnect(con)
  
  
  vermac_traffic<-reactiveValues()


  parameter<-reactiveValues()
  vermac_study_area<-reactiveValues()
  closure_plan<-reactiveValues()
  
  temp_sensor<-reactiveValues()
  temp_sensor$all<-data.frame()
  temp_sensor$closure<-data.frame()
  temp_sensor$selected<-data.frame()


  closure_info_db<-reactiveValues()
  closure_info_db$total<-data.frame()
  closure_info_db$selected<-data.frame()
  closure_info_db$stime<-NA
  closure_info_db$etime<-NA 
  closure_info_db$shour<-NA 
  
  
map6<-leaflet() %>%
  addProviderTiles("OpenStreetMap.BlackAndWhite") %>%
  setView(lat = 30.27884,
          lng = -97.69812,
          zoom = 11
  )


output$mapAustin6 <- renderLeaflet({map6})
if (nrow(temp_sensor_info)>0)
{
  dt<-temp_sensor_info
  dt<-dt%>%
    mutate_all(as.character)
  dt<-data.frame(dt, stringsAsFactors =FALSE)
  
  dt$corridor<-factor(dt$corridor, levels=road_name$road)
  dt$dir<-factor(dt$dir, levels=dir)
  dt$stime<-strftime(dt$stime, format="%m/%d/%Y %H:%M")
  dt$etime<-strftime(dt$etime, format="%m/%d/%Y %H:%M")
  
  dt<-dt[c('uid', 'closure_id', 'sensor_name', 'dir', 'corridor', 'stime', 'etime')]
  names(dt)<-c("Unique ID", "Closure ID", "Sensor", "Direct", "Corridor", "Active Start", "Active End")
  
  
  output$temporary_info<-renderRHandsontable({
    rhandsontable(dt, readOnly = TRUE)%>%
      hot_col('Direct', readOnly=FALSE,  type = "dropdown", source = dir)%>%
      hot_col('Active End', readOnly=FALSE)%>%
      hot_col('Corridor', readOnly=FALSE)
    
  
  })  
}
#tab 1
#Add closure info
observeEvent(input$temp_info_select,{

  abc<-123
#  if (input$temp_closure_name=="")
 #   return()
  
  query<-paste('select * from ', temporary_sensor_info, sep='')
  temp_sensor_info<-isolate(mysql_connection(query))
  

  if (nrow(temp_sensor_info)==0)
    return()
  
  temp_sensor_info<-temp_sensor_info%>%
    mutate_all(as.character)
  
  dt<-temp_sensor_info
  dt<-data.frame(dt, stringsAsFactors =FALSE)
  dt$corridor<-factor(dt$corridor, levels=road_name$road)
  dt$dir<-factor(dt$dir, levels=dir)

  if (input$temp_info_select==2)
  {
    dt<-filter(dt, str_detect(dt$closure_id, input$temp_closure_name))
  }  
 
  dt<-dt[c('uid', 'closure_id', 'sensor_name', 'dir', 'corridor', 'stime', 'etime')]
  names(dt)<-c("Unique ID", "Closure ID", "Sensor", "Direct", "Corridor", "Active Start", "Active End")


  output$temporary_info<-renderRHandsontable({
    rhandsontable(dt, readOnly = TRUE)%>%
      hot_col('Direct', readOnly=FALSE,  type = "dropdown", source = dir)%>%
      hot_col('Active End', readOnly=FALSE)%>%
      hot_col('Corridor', readOnly=FALSE)
    
 

  })  
  

})
observe({
  
#  if (input$temp_closure_name=="")
 #   return()
  
  if (input$temp_info_select==2)
  {
    query<-paste('select * from ', temporary_sensor_info, sep='')
    temp_sensor_info<-isolate(mysql_connection(query))
    
    if (nrow(temp_sensor_info)==0)
      return()
    
    
    temp_sensor_info<-temp_sensor_info%>%
      mutate_all(as.character)
    
    dt<-temp_sensor_info
    dt<-data.frame(dt, stringsAsFactors =FALSE)
    dt$corridor<-factor(dt$corridor, levels=road_name$road)
    dt$dir<-factor(dt$dir, levels=dir)
    dt<-filter(dt, str_detect(dt$closure_id, input$temp_closure_name))
    
    
    dt<-dt[c('uid', 'closure_id', 'sensor_name', 'dir', 'corridor', 'stime', 'etime')]
    names(dt)<-c("Unique ID", "Closure ID", "Sensor", "Direct", "Corridor", "Active Start", "Active End")

    

    output$temporary_info<-renderRHandsontable({
      rhandsontable(dt, readOnly = TRUE)%>%
        hot_col('Direct', readOnly=FALSE,  type = "dropdown", source = dir)%>%
        hot_col('Active End', readOnly=FALSE)%>%
        hot_col('Corridor', readOnly=FALSE)
  
    
      })
  }
})





observeEvent(input$closure_stime_select,{
  
  test<-input$start_hms
  output$closure_stime<-renderText("")
  h<-input$shour
  m<-input$smin
  #####need to change when feed data in
 
  #stime<-format(Sys.time()-300, "%m/%d/%Y %H:%M")
  stime<-paste(as.character(Sys.Date())," ",h,':',m,sep='')
  temp_sensor_loc<-NULL
  

  
  #stime<-format(as.POSIXct("2019-05-29 13:12", tz="America/Chicago"), "%m/%d/%Y %H:%M")
 # query<-sprintf("select  distinct sensor_id as sensor_id, long as long, lat as lat from %s where archive_time >'%s'", sensor_current_traffic_table, stime)
  
  query<-sprintf("select distinct b.sensor_id,lat,long from %s a, (select sensor_id,max(archive_time) as max_at from %s group by sensor_id) as b where b.sensor_id=a.sensor_id and a.archive_time=b.max_at and archive_time>'%s' and lat<>0 and long<>0",sensor_current_traffic_table, sensor_current_traffic_table,stime)
  
  temp_sensor_loc<-isolate(mysql_connection(query))
  #df<-data.frame(sensor_id=unique(temp_sensor_loc$sensor_id))
  #temp_sensor_loc<-temp_sensor_loc[c('sensor_id', 'long', 'lat')]
  #temp_sensor_loc<-merge(df, temp_sensor_loc, all.x=TRUE)
  #temp_sensor_loc<-unique(temp_sensor_loc[c('sensor_id', 'long', 'lat')])
  
  temp_sensor_loc<-merge(temp_sensor_loc, temp_sensor_id)
  if (nrow(temp_sensor_loc)<2)
  {
    updateButton(session,"closure_stime_select", style="danger")
    output$closure_stime<-renderText(paste("Not enough active sensors on", stime ,". Need at least 2",sep="")) 
    return()
  }
  
  updateButton(session,"closure_stime_select", style="success")
  
  temp_sensor_loc$dir<-"NB"
  temp_sensor_loc$dir[str_detect(temp_sensor_loc$sensor_name, 'NB')]<-'NB'
  temp_sensor_loc$dir[str_detect(temp_sensor_loc$sensor_name, 'SB')]<-'SB'
  temp_sensor_loc$dir[str_detect(temp_sensor_loc$sensor_name, 'EB')]<-'EB'
  temp_sensor_loc$dir[str_detect(temp_sensor_loc$sensor_name, 'WB')]<-'WB'
  
  temp_sensor_loc$corridor<-road_name$road[1]
    
  map1<-leaflet() %>%
    addProviderTiles("OpenStreetMap.BlackAndWhite") %>%
    setView(lat = 30.27884,
            lng = -97.69812,
            zoom = 11
    )%>%
    clearMarkers()%>%
    addMarkers(
      data=temp_sensor_loc,
      lng=~long,
      lat=~lat,
      label=~paste(as.character(sensor_name)),
      layerId = ~paste(as.character(sensor_name)),
      icon = markerIcon) 
  
  
  output$mapAustin1<-renderLeaflet({map1})
  output$closure_stime<-renderText(paste("Will use sensors active on: ", stime, sep="")) 
  
  temp_sensor_loc<-temp_sensor_loc%>%
    mutate_all(as.character)
  closure_info_db$total<-temp_sensor_loc
  closure_info_db$selected<-temp_sensor_loc
  closure_info_db$stime<-(stime)
  
  
  selected_sensor_table<-data.frame(Sensor= closure_info_db$selected$sensor_name, 
                                    Direct= factor(closure_info_db$selected$dir, levels=dir),
                                    Corridor=factor(closure_info_db$selected$corridor, levels=road_name$road),
                                    stringsAsFactors = FALSE)

  col_highlight = c(1,2)
  output$closure_selected_sensor<-renderRHandsontable({
    rhandsontable(selected_sensor_table, 
                  col_highlight = col_highlight, 
                  readOnly=FALSE)%>%
      hot_col('Direct', readOnly=FALSE)%>%
      hot_col('Corridor', readOnly=FALSE)#%>%
     #hot_cols(renderer=color_renderer)
    
  })  
  
  
  
})
observe({ 
  
  click <- input$mapAustin1_marker_click
  if (is.null(click))
    return()
  leafletProxy('mapAustin1') %>%
    clearGroup("selected_temp")%>%
    addCircleMarkers(
      data = click,
      lng = ~lng,
      lat = ~lat,
      stroke = FALSE,
      fill = TRUE,
      fillColor = 'darkorange',
      fillOpacity = 0.9,
      group = "selected_temp"
    )
  
  abc<-123
  if (input$closure_sensor_type=="2")
  {
    selected_sensor<-filter(closure_info_db$total, closure_info_db$total$sensor_name==click$id[1])
    if (nrow(closure_info_db$selected)==0)
    {
      selected_sensor_table<-data.frame(Sensor= selected_sensor$sensor_name, 
                                        Direct= factor(selected_sensor$dir, levels=dir),
                                        Corridor=factor(selected_sensor$corridor, levels=road_name$road),
                                        stringsAsFactors = FALSE) 
      
      selected_sensor_table$Corridor<-factor( selected_sensor_table$Corridor, levels=road_name$road)
      selected_sensor_table$Direct<-factor( selected_sensor_table$Direct, levels=dir)
      
      closure_info_db$selected<-rbind(closure_info_db$selected,  selected_sensor)
      output$closure_selected_sensor<-renderRHandsontable({
        rhandsontable(selected_sensor_table, readOnly=TRUE)%>%
          hot_col('Direct', readOnly=FALSE, type = "dropdown")%>%
          hot_col('Corridor', readOnly=FALSE, type = "dropdown")#%>%
      })  
      
      return()
      
    }
    
    if (length(which(closure_info_db$selected$sensor_name %in% selected_sensor$sensor_name))>0)
    {  
      return()
    }
     
    closure_info_db$selected<-rbind(closure_info_db$selected,  selected_sensor)
    selected_sensor_table<-data.frame(Sensor= closure_info_db$selected$sensor_name, 
                                      Direct= factor(closure_info_db$selected$dir, levels=dir),
                                      Corridor=factor(selected_sensor$corridor, levels=road_name$road),
                                      stringsAsFactors = FALSE)
    
    selected_sensor_table$Corridor<-factor(selected_sensor_table$Corridor, levels=road_name$road)
    selected_sensor_table$Direct<-factor(selected_sensor_table$Direct, levels=dir)
    
    output$closure_selected_sensor<-renderRHandsontable({
      rhandsontable(selected_sensor_table, readOnly=TRUE)%>%
        hot_col('Direct', readOnly=FALSE)%>%
        hot_col('Corridor', readOnly=FALSE)#%>%
    })   

  }
})

observeEvent(input$closure_sensor_type, {

  if (nrow(closure_info_db$total)==0)
    return()
  if (input$closure_sensor_type=="1")
  {
    closure_info_db$selected<- closure_info_db$total
    selected_sensor_table<-data.frame(Sensor= closure_info_db$selected$sensor, 
                                      Direct= factor(closure_info_db$selected$dir, levels=dir),
                                      Corridor=factor(closure_info_db$selected$corridor, levels=road_name$road),
                                      stringsAsFactors = FALSE)
    selected_sensor_table$Corridor<-factor( selected_sensor_table$Corridor, levels=road_name$road)
    selected_sensor_table$Direct<-factor( selected_sensor_table$Direct, levels=dir)
    
    output$closure_selected_sensor<-renderRHandsontable({
      rhandsontable(selected_sensor_table, readOnly=TRUE)%>%
        hot_col('Direct', readOnly=FALSE, type = "dropdown")%>%
        hot_col('Corridor', readOnly=FALSE, type = "dropdown")#%>%
    }) 
    return()
  }else
  {
    closure_info_db$selected<- data.frame()
    selected_sensor_table<-data.frame()    
    output$closure_selected_sensor<-renderRHandsontable({
      rhandsontable(selected_sensor_table, readOnly=TRUE)
    }) 
     
  }
  
})

observeEvent(input$temp_sensor_add_select, {
  
  withProgress(message="Writing into DB",{
    
  query<-paste('select * from ', temporary_sensor_info, sep='')
  temp_sensor_info<-isolate(mysql_connection(query)) 
  uid<-(max(temp_sensor_info$uid, 0)+1)
  closure_id<-as.character(input$cid)

 # st<-as.POSIXct(as.character(closure_info_db$stime), tz="America/Chicago", format="%m/%d/%Y %H:%M")
  st<-as.POSIXlt(closure_info_db$stime, tz="America/Chicago")
  et<-st+(as.integer(input$closure_etime_select)*86400)
  selected_sensor_table<-hot_to_r(input$closure_selected_sensor)
  df<-closure_info_db$selected[c('sensor_id','sensor_name','long', 'lat')]

  selected_sensor_table<-merge(x=df, y= selected_sensor_table, by.x=c('sensor_name'), by.y=c('Sensor'))
  names(selected_sensor_table)<-c('sensor_name', 'sensor_id', 'long', 'lat', 'dir', 'corridor')

  selected_sensor_table$uid<-uid
  selected_sensor_table$closure_id<-(closure_id)
  selected_sensor_table$stime<-strftime(st, format="%m/%d/%Y %H:%M")
  selected_sensor_table$etime<-strftime(et, format="%m/%d/%Y %H:%M")
  selected_sensor_table$dis<-NA
  
  selected_sensor_table<-isolate(distance_calculate(selected_sensor_table))
  selected_sensor_table<-selected_sensor_table[c("uid", "closure_id","sensor_id", "sensor_name", "dir", "corridor", "lat", "long", "stime", "etime", "dis")]
  
  selected_sensor_table$lat<-as.double( selected_sensor_table$lat)
  selected_sensor_table$long<-as.double( selected_sensor_table$long)
  selected_sensor_table$dis<-as.double( selected_sensor_table$dis)
  selected_sensor_table$corridor<-as.character(selected_sensor_table$corridor)
  
  
  write_table_mysql(temporary_sensor_info, selected_sensor_table)
  
  updateButton(session,"temp_sensor_add_select",style="success")

  query<-paste('select * from ', temporary_sensor_info, sep='')
  temp_sensor_info<-isolate(mysql_connection(query))   
  temp_sensor$all<-temp_sensor_info

  
  
  if (input$temp_info_select=="1"){
    
    if (nrow(temp_sensor_info)==0)
      return()
    
    
    temp_sensor_info<-temp_sensor_info%>%
      mutate_all(as.character)
    
    dt<-temp_sensor_info
    dt<-data.frame(dt, stringsAsFactors =FALSE)
    dt$corridor<-factor(dt$corridor, levels=road_name$road)
    dt$dir<-factor(dt$dir, levels=dir)
    dt<-filter(dt, str_detect(dt$closure_id, input$temp_closure_name))

    
    dt<-dt[c('uid', 'closure_id', 'sensor_name', 'dir', 'corridor', 'stime', 'etime')]
    names(dt)<-c("Unique ID", "Closure ID", "Sensor", "Direct", "Corridor", "Active Start", "Active End")
    
    output$temporary_info<-renderRHandsontable({
      rhandsontable(dt, readOnly = TRUE)%>%
        hot_col('Direct', readOnly=FALSE,  type = "dropdown", source = dir)%>%
        hot_col('Active End', readOnly=FALSE)%>%
        hot_col('Corridor', readOnly=FALSE)
  
    })
    
    updateSelectInput(session, inputId='closure_id', choices=unique(temp_sensor_info$closure_id), selected=unique(temp_sensor_info$closure_id)[1])
    uids<-unique(filter(temp_sensor_info, temp_sensor_info$closure_id==unique(temp_sensor_info$closure_id)[1]))$uid
    
    updateSelectInput(session, inputId='unique_id', choices=uids, selected=uids[1])
    

  }
})
})
# tab 2
observeEvent(input$closure_id, {
  
  uids<-(filter(temp_sensor_info, temp_sensor_info$closure_id==input$closure_id)$uid)
  updateSelectInput(session, inputId='unique_id', choices = uids, selected=uids[1])
})

observeEvent(input$unique_id_refresh, {
  
  query<-paste('select * from ', temporary_sensor_info, sep='')
  temp_sensor_info<-isolate(mysql_connection(query)) 
  uids<-(filter(temp_sensor_info, temp_sensor_info$closure_id==input$closure_id)$uid)
  updateSelectInput(session, inputId='unique_id', choices = uids, selected=uids[1])
  

  
})
observeEvent(input$unique_id, {
 
  query<-paste('select * from ', temporary_sensor_info, sep='')
  temp_sensor_info<-isolate(mysql_connection(query)) 
  
  temp_sensor_info$stime<-as.POSIXct(temp_sensor_info$stime, format="%m/%d/%Y %H:%M", tz="America/Chicago")
  temp_sensor_info$etime<-as.POSIXct(temp_sensor_info$etime, format="%m/%d/%Y %H:%M", tz="America/Chicago")
  selected_temp_sensor<-filter(temp_sensor_info, temp_sensor_info$uid==input$unique_id)
  
  
  temp_sensor$selected<-selected_temp_sensor
  #change select time on UI
  selected_closure_time_period<-paste("Data available from ",selected_temp_sensor$stime[1], " to ",
                                                             selected_temp_sensor$etime[1], sep="")
  
  dt<-data.frame(Sensor=selected_temp_sensor$sensor_name, Direction=selected_temp_sensor$dir )
  output$selected_closure_tperiod1<-renderText({selected_closure_time_period})
  output$selected_closure_tperiod2<-renderText({selected_closure_time_period})
  output$selected_closure_info<-renderTable({dt})
  temp_sensor$closure<- selected_temp_sensor
  temp_sensor$selected<- temp_sensor$closure
  ver_pos_be_road<-temp_sensor$closure

  # ver_pos_be_road<-filter(temp_sensor_info, temp_sensor_info$id==input$unique_id)
  updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", disabled=FALSE,style="primary")
  
  s<-(aggregate(ver_pos_be_road$dis, by=list(ver_pos_be_road$dir), FUN=min))
  names(s)<-c('dir', 'dis')
  e<-(aggregate(ver_pos_be_road$dis, by=list(ver_pos_be_road$dir), FUN=max))
  names(e)<-c('dir', 'dis')
  
  vermac_study_area$start<-merge(x=s, y=ver_pos_be_road, by.x=c('dir', 'dis'), by.y=c('dir', 'dis'), all.x=TRUE)
  vermac_study_area$end<-merge(x=e, y=ver_pos_be_road, by.x=c('dir', 'dis'), by.y=c('dir', 'dis'), all.x=TRUE)
  
  # updateDateInput(session, inputId='be_date_start',
  #           value=as.POSIXct(as.character(selected_temp_sensor$stime[1]), tz="America/Chicago"),
  #           min=as.POSIXct(as.character(selected_temp_sensor$stime[1]), tz="America/Chicago"),
  #           max=as.POSIXct(as.character(selected_temp_sensor$etime[1]), tz="America/Chicago"))
  # 
  # updateDateInput(session, inputId='be_date_end',
  #                 value=as.POSIXct(as.character(selected_temp_sensor$etime[1]), tz="America/Chicago"),
  #                 min=as.POSIXct(as.character(selected_temp_sensor$stime[1]), tz="America/Chicago"),
  #                 max=as.POSIXct(as.character(selected_temp_sensor$etime[1]), tz="America/Chicago")
  #                 )
  
  leafletProxy('mapAustin6') %>%     
    clearMarkers()%>%
    addMarkers(
      data=selected_temp_sensor,
      lng=~long,
      lat=~lat,
      label=~paste(as.character(sensor_name)),
      layerId = ~paste(as.character(sensor_name)),
      icon = markerIcon) 
  


})

#Reset if we change analysis type
observeEvent(input$ver_be_area_select_input,{
  vermac_study_area$start<-NULL
  vermac_study_area$end<-NULL
  vermac_study_area$sensors<-NULL
  vermac_study_area$sensor_name<-NULL
  
  vermac_traffic$queue_length<-NULL
  vermac_traffic$travel_time<-NULL
  vermac_traffic$delay_time<-NULL
  vermac_traffic$queue_position<-NULL
  vermac_traffic$speed_plot<-NULL
  vermac_traffic$closure_count<-NULL
  
  vermac_traffic$closure_raw<-NULL
  vermac_traffic$closure_ana<-NULL
  vermac_traffic$refer_raw<-NULL
  vermac_traffic$refer_ana<-NULL
  
  parameter$time_range<-NULL
  parameter$time_start<-NULL
  parameter$time_end<-NULL  
  
  ver_pos_be_road<-data.frame()
  if (input$ver_be_area_select_input == 2){
    if (input$bg_road=="I-35")
      direct<-c("NB", "SB")
    if (input$bg_road=="US-183")
      direct<-c("EB", "WB")
    
    ver_pos_be_road<-filter(temp_sensor$closure, temp_sensor$closure$dir %in%  direct)
    
    #######Reset buttons
    #Historical data
    #Create plot (block)
    updateButton(session, inputId="be_info_select", label="Create Plot" , disabled=TRUE,style="primary")
    #closure data
    updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", disabled=TRUE,style="primary")
    
  }else{
    ####If all are selected, for each direct we pick the first and last trailers
    ver_pos_be_road<-temp_sensor$closure
    # ver_pos_be_road<-filter(temp_sensor_info, temp_sensor_info$id==input$unique_id)
    updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", disabled=FALSE,style="primary")
    
    s<-(aggregate(ver_pos_be_road$dis, by=list(ver_pos_be_road$dir), FUN=min))
    names(s)<-c('dir', 'dis')
    e<-(aggregate(ver_pos_be_road$dis, by=list(ver_pos_be_road$dir), FUN=max))
    names(e)<-c('dir', 'dis')
    
    vermac_study_area$start<-merge(x=s, y=ver_pos_be_road, by.x=c('dir', 'dis'), by.y=c('dir', 'dis'), all.x=TRUE)
    vermac_study_area$end<-merge(x=e, y=ver_pos_be_road, by.x=c('dir', 'dis'), by.y=c('dir', 'dis'), all.x=TRUE)
 
    leafletProxy('mapAustin6') %>%     
      clearMarkers()%>%
      addMarkers(
        data=ver_pos_be_road,
        lng=~long,
        lat=~lat,
        label=~paste(as.character(sensor_name)),
        layerId = ~paste(as.character(sensor_name)),
        icon = markerIcon) 
    
    
  }

  
})

#Adjust trailer selection options when changing roads
observeEvent(input$bg_road,{
  
  ###Clean selected marker box
  output$trailer_start_be=renderText("")
  output$trailer_end_be=renderText("")
  updateButton(session,"trailer_start_be_select", "Select", disabled=FALSE)
  updateButton(session,"trailer_end_be_select", "Select", disabled=FALSE)
  
  ###Clean selected trailer marker
  leafletProxy('mapAustin6') %>%
    clearGroup("selected_wkz_start")%>%
    clearGroup("selected_wkz_end")
  
  ###Clean up position data
  vermac_study_area$start<-NULL
  vermac_study_area$end<-NULL
  vermac_study_area$sensors<-NULL
  vermac_study_area$sensor_name<-NULL
  
  vermac_traffic$queue_length<-NULL
  vermac_traffic$travel_time<-NULL
  vermac_traffic$delay_time<-NULL
  vermac_traffic$queue_position<-NULL
  vermac_traffic$speed_plot<-NULL
  vermac_traffic$closure_count<-NULL
  
  vermac_traffic$closure_raw<-NULL
  vermac_traffic$closure_ana<-NULL
  vermac_traffic$refer_raw<-NULL
  vermac_traffic$refer_ana<-NULL
  
  vermac_traffic$missing<-NULL
  

  
  parameter<-reactiveValues()
  
  if (input$bg_road=="I-35")
    direct<-c("NB", "SB")
  if (input$bg_road=="US-183")
    direct<-c("EB", "WB")
  
  
  ver_pos_be_road<-filter(temp_sensor_info, temp_sensor_info$dir %in% direct)
  if (nrow(ver_pos_be_road)==0)
    return()
  
  updateButton(session, inputId="be_info_select", label="Create Plot" , disabled=TRUE,style="primary")
  leafletProxy('mapAustin6') %>%     
    clearMarkers()%>%
    addMarkers(
      data=ver_pos_be_road,
      lng=~long,
      lat=~lat,
      label=~paste(as.character(sensor_name)),
      layerId = ~as.character(sensor_name),
      icon = markerIcon) 
  

  
  
})

#Adjust trailer selection options when changing roads
observe({
  
  if (input$ver_be_area_select_input=="1")
    return()
  
  ###Clean selected marker box
  output$trailer_start_be=renderText("")
  output$trailer_end_be=renderText("")
  updateButton(session,"trailer_start_be_select", "Select", disabled=FALSE)
  updateButton(session,"trailer_end_be_select", "Select", disabled=FALSE)
  
  ###Clean selected trailer marker
  leafletProxy('mapAustin6') %>%
    clearGroup("selected_wkz_start")%>%
    clearGroup("selected_wkz_end")
  
  ###Clean up position data
  vermac_study_area$start<-NULL
  vermac_study_area$end<-NULL
  vermac_study_area$sensors<-NULL
  vermac_study_area$sensor_name<-NULL
  
  vermac_traffic$queue_length<-NULL
  vermac_traffic$travel_time<-NULL
  vermac_traffic$delay_time<-NULL
  vermac_traffic$queue_position<-NULL
  vermac_traffic$speed_plot<-NULL
  vermac_traffic$closure_count<-NULL
  
  vermac_traffic$closure_raw<-NULL
  vermac_traffic$closure_ana<-NULL
  vermac_traffic$refer_raw<-NULL
  vermac_traffic$refer_ana<-NULL
  
  vermac_traffic$missing<-NULL
  parameter<-reactiveValues()
  
  if (input$bg_road=="I-35")
    direct<-c("NB", "SB")
  if (input$bg_road=="US-183")
    direct<-c("EB", "WB")
  
  
  ver_pos_be_road<-filter( temp_sensor$closure,  temp_sensor$closure$dir %in% direct)
  
  if (nrow(ver_pos_be_road)==0)
    return()
  
  updateButton(session, inputId="be_info_select", label="Create Plot" , disabled=TRUE,style="primary")
  leafletProxy('mapAustin6') %>%     
    clearMarkers()%>%
    addMarkers(
      data=ver_pos_be_road,
      lng=~long,
      lat=~lat,
      label=~paste(as.character(sensor_name)),
      layerId = ~paste(as.character(sensor_name)),
      icon = markerIcon) 
  
  
  #Create plot (block)
  updateButton(session, inputId="be_info_select", label="Create Plot" , disabled=TRUE,style="primary")
  #closure data
  updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", disabled=TRUE,style="primary")
  
  
})

#Add Circle When clicking
observe({ 
  
  click <- input$mapAustin6_marker_click
  if (is.null(click))
    return()
  leafletProxy('mapAustin6') %>%
    clearGroup("selected_wkz")%>%
    addCircleMarkers(
      data = click,
      lng = ~lng,
      lat = ~lat,
      stroke = FALSE,
      fill = TRUE,
      fillColor = 'darkorange',
      fillOpacity = 0.9,
      group = "selected_wkz"
    )
})


#####################
###Select trailers 
####################


#Select start point from map
observeEvent(input$trailer_start_be_select ,{
  click <- isolate(input$mapAustin6_marker_click)
  if (is.null(click))
    return()
  
  leafletProxy('mapAustin6') %>%
    clearGroup("selected_wkz_start")%>% 
    addCircleMarkers(
      data = click,
      lng =~lng,
      lat =~lat,
      stroke = FALSE,
      fill = TRUE,
      fillColor = 'green',
      fillOpacity = 0.9,
      group = "selected_wkz_start"
    )
  vermac_study_area$start<-filter(temp_sensor$closure, temp_sensor$closure$sensor_name==click$id)
  output$trailer_start_be<-renderText(HTML(paste0(vermac_study_area$start$sensor_name[1])))
  updateButton(session,"trailer_start_be_select", "Reset", disabled=FALSE)
  
  
  
  #######Reset buttons
  #Create plot (block)
  updateButton(session, inputId="be_info_select", label="Create Plot" , disabled=TRUE,style="primary")
  
  updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", disabled=TRUE,style="primary")
  
  if (is.null(vermac_study_area$end))
    return ()
  if (vermac_study_area$start$sensor_name[1] != vermac_study_area$end$sensor_name[1]){

    updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", disabled=FALSE,style="primary")
  }
  
  #######Delete all data to erase plots and reset hist data 
  
  vermac_traffic$queue_length<-NULL
  vermac_traffic$travel_time<-NULL
  vermac_traffic$delay_time<-NULL
  vermac_traffic$queue_position<-NULL
  vermac_traffic$speed_plot<-NULL
  vermac_traffic$closure_count<-NULL
  
  vermac_traffic$closure_raw<-NULL
  vermac_traffic$closure_ana<-NULL
  vermac_traffic$refer_raw<-NULL
  vermac_traffic$refer_ana<-NULL
  

  
  parameter$time_range<-NULL
  parameter$time_start<-NULL
  parameter$time_end<-NULL  
})

#Select end point from map
observeEvent(input$trailer_end_be_select ,{
  click <- isolate(input$mapAustin6_marker_click)
  if (is.null(click))
    return()
  
  
  leafletProxy('mapAustin6') %>%
    clearGroup("selected_wkz_end")%>%
    addCircleMarkers(
      data = click,
      lng = ~lng,
      lat = ~lat,
      stroke = FALSE,
      fill = TRUE,
      fillColor = 'green',
      fillOpacity = 0.9,
      group = "selected_wkz_end")
  
  
 vermac_study_area$end<-filter(temp_sensor$closure, temp_sensor$closure$sensor_name==click$id)
 output$trailer_end_be<-renderText(HTML(paste0(vermac_study_area$end$sensor_name[1])))
 updateButton(session,"trailer_end_be_select", "Reset", disabled=FALSE)  
  
  #######Reset buttons
  #Historical data
 
  #Create plot (block)
  updateButton(session, inputId="be_info_select", label="Create Plot" , disabled=TRUE,style="primary")
  
  updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", disabled=TRUE,style="primary")
  
  if (is.null(vermac_study_area$start))
    return()
 

  if (vermac_study_area$start$sensor_name[1] != vermac_study_area$end$sensor_name[1]){
    updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", disabled=FALSE,style="primary")
  }
  
  
  
  #######Delete all data to erase plots and reset hist data 
  
  vermac_traffic$queue_length<-NULL
  vermac_traffic$travel_time<-NULL
  vermac_traffic$delay_time<-NULL
  vermac_traffic$queue_position<-NULL
  vermac_traffic$speed_plot<-NULL
  vermac_traffic$closure_count<-NULL
  
  vermac_traffic$closure_raw<-NULL
  vermac_traffic$closure_ana<-NULL
  vermac_traffic$refer_raw<-NULL
  vermac_traffic$refer_ana<-NULL
  
  parameter$time_range<-NULL
  parameter$time_start<-NULL
  parameter$time_end<-NULL  
  
})




##Retrieve vermac data
observeEvent(input$trailer_be_time_select ,{
    
  vermac_traffic$closure_raw<-NULL
  vermac_traffic$refer_raw<-NULL
  vermac_traffic$closure_ana<-NULL
  vermac_traffic$refer_ana<-NULL
  vermac_traffic$missing<-NULL
  vermac_traffic$queue_length<-NULL
  vermac_traffic$travel_time<-NULL
  vermac_traffic$delay_time<-NULL
  vermac_traffic$queue_position<-NULL
  vermac_traffic$speed_plot<-NULL
  vermac_traffic$closure_count<-NULL
  
  parameter$time_range<-NULL
  parameter$time_start<-NULL
  parameter$time_end<-NULL  

  
  output$ver_aval_be<-NULL
  output$ver_start_be<-renderText("")
  output$ver_end_be<-renderText("")
  output$ver_aval_data<-renderText("")

  
  vermac_traffic$sensors<-NULL
    

  #####Define parameters
  withProgress(message = 'Collecting Sensor Data', {
  ver_traf<-data.frame()
  #####Verify Input Consistecy####################333
  
  sdate<-as.Date(input$be_date_start, tz="America/Chicago")
  edate<-as.Date(input$be_date_end, tz="America/Chicago")
  stime<-as.integer(input$be_shr)
  etime<-as.integer(input$be_ehr)
  st<-as.POSIXct(paste(sdate, " ", stime,":00", sep=""),format= "%Y-%m-%d %H:%M" , tz="America/Chicago")
  et<-as.POSIXct(paste(edate, " ", etime,":00", sep=""), format= "%Y-%m-%d %H:%M" , tz="America/Chicago")
  if (st>et)
  {
    output$ver_aval_be<-renderText(HTML(paste0("Start date/time is larger than End date/time\n")))
    output$ver_start_be<-renderText(HTML(paste0("Start time: ", st)))
    output$ver_end_be<-renderText(HTML(paste0("End time: ", et)))
    updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", style="danger")
    return()
  }

  
  time_range<-seq(from=st, to=et, by=300)
  
  #####Verify Data availability#######################
  
  updateButton(session,"trailer_be_time_select", "Retrieving", style="warning")
  
  
  #Sensor names
  sensor1<-vermac_study_area$start
  sensor2<-vermac_study_area$end

  subsensors<-data.frame()
  direct<-unique(sensor1$dir) 
  sensor_pos_map<-temp_sensor$selected
  
  for (i in 1: length(direct))
  {
    df<-filter(sensor_pos_map,sensor_pos_map$dir== direct[i])
    start<-filter(sensor1, sensor1$dir== direct[i])
    end<-filter(sensor2, sensor2$dir==direct[i])
    sensor_range<-c(start$dis[1], end$dis[1])
    df<-filter(df, df$dis>=min(sensor_range) & df$dis<= max(sensor_range))
    df$dis<-abs(df$dis-min(sensor_range))
    subsensors<-rbind(subsensors, df)
  }
  
  loc_list<-subsensors$sensor_id
  vermac_study_area$sensors<-subsensors
  
  
  st1<-(st-3600)
  et1<-(et+3600)
  
  vermac_table_name<-sensor_current_traffic_table
  vermac_study_area$sesnor_id<-paste(vermac_study_area$sensors$sensor_id, collapse=',')
  
  ver_count<-sprintf("select count(*) from %s where sensor_id in (%s) and Archive_Time between '%s' and '%s'",
                     vermac_table_name, vermac_study_area$sesnor_id, st,et)  
  
  ver_traf<-sprintf("select sensor_id, speed, volume as count, archive_time as time from %s where sensor_id in (%s) and Archive_Time between '%s' and '%s'",
                     vermac_table_name, vermac_study_area$sesnor_id, st,et) 

  #ver_traf<-isolate(mysql_connection(ver_traf))    
  
 
  ver_count<-isolate(mysql_connection(ver_count))
  ver_traf<-isolate(mysql_connection(ver_traf))
  df<-temp_sensor$selected[c('sensor_id', 'sensor_name', 'dir')]
  ver_traf<-merge(df, ver_traf, by.x='sensor_id', by.y='sensor_id')
  ver_traf$time<-as.POSIXct(as.character(ver_traf$time), tz='America/Chicago')
  })
  if(ver_count[1]==0)
  {
    output$ver_aval_be<-renderText(HTML(paste0("Vermac data is not available for selected trailers on the desired dates\n"))) 
    updateButton(session,"trailer_be_time_select", "Retrieve Closure Data", style="danger")
    return()
  } 
  
  parameter$time_range<-time_range
  parameter$time_start<-st
  parameter$time_end<-et  
  
  

  vermac_traffic$closure_raw<-ver_traf
  
  
 # ver_pos<-vermac_traffic$pos_study
  updateSelectInput(session, inputId="plot_be_display", choices=c( direct), selected=as.character(direct[1]))
  updateSelectInput(session, inputId="plot_be_display_flow", choices=c(  direct), selected=as.character(direct[1]))
  selected_flow_trailer<-unique(filter(vermac_study_area$sensors,  vermac_study_area$sensors$dir==direct[1])$sensor_name)
  
  updateSelectInput(session, inputId="plot_vermac_be_display_flow", choices=c(selected_flow_trailer), selected=selected_flow_trailer[1]) 
  updateButton(session,"trailer_be_time_select", "Retrieved", style="success")
  updateButton(session,"be_info_select", disabled=FALSE)
})


###############################################
########Vermac Data Organization###############
###############################################

observeEvent(input$be_info_select,{

  vermac_traffic$queue_length<-NULL
  vermac_traffic$travel_time<-NULL
  vermac_traffic$delay_time<-NULL
  vermac_traffic$queue_position<-NULL
  vermac_traffic$speed_plot<-NULL
  vermac_traffic$closure_count<-NULL
  vermac_traffic$refer_ana<-NULL
  vermac_traffic$closure_ana<-NULL
  
  updateButton(session, inputId="be_info_select", label="Creating Plot" ,style='warning')
  withProgress(message="Analyzing....", {

  vermac_closure_raw<-vermac_traffic$closure_raw

  
  time_range<-parameter$time_range
  closure_start<-parameter$time_start
  
  
 
  vermac_closure_ana<-data.frame()

  #######Aggregate to 5 minutes#####
  #smooth
  if (input$be_sm_factor==TRUE)
  {
    smooth_data<-300
  }else{
    smooth_data<-0
  }
  for (i in 1: (length(time_range)-1))
  {
    # closure data
    t1<-(time_range[i]-smooth_data) 
    t2<-(time_range[i+1]+smooth_data) ####for average speed  
    df_vermac<-vermac_closure_raw[(vermac_closure_raw$time>=t1 & vermac_closure_raw$time< t2),]
    
    if (nrow(df_vermac)!=0)
    {
      avg_speed<-aggregate(df_vermac$speed, by=list(df_vermac$sensor_name, df_vermac$dir), FUN=mean)
      t1<-time_range[i] 
      t2<-time_range[i+1] ####for average speed    
      df_vermac<-vermac_closure_raw[(vermac_closure_raw$time>=t1 & vermac_closure_raw$time< t2),]
      sum_count<-aggregate(df_vermac$count, by=list(df_vermac$sensor_name, df_vermac$dir), FUN=sum)
      if (nrow(avg_speed)!= nrow(sum_count))
      {
        print("closure: avg_speed != sum_count")
      }
      names(sum_count)<-c("sensor_name","dir", "count")
      names(avg_speed)<-c("sensor_name","dir", "speed")
      df_vermac<-merge(x=sum_count, y=avg_speed, by.x=c("sensor_name", "dir"), by.y=c("sensor_name","dir"), all.x=TRUE, all.y=TRUE)
      df_vermac<-data.frame(time=time_range[i], df_vermac)
      vermac_closure_ana<-rbind(vermac_closure_ana, df_vermac)
    }

  } 

  vermac_traffic$closure_ana<-vermac_closure_ana
  
 
  
  })
})

#Calculation
observe({

  vermac_closure<-vermac_traffic$closure_ana  

  if ( is.null(dim(vermac_closure)))
    return() 

  withProgress(message="Plotting....", {   
  threshold<-as.integer(input$be_ffs)
  time_range<-parameter$time_range
  

  ver_pos<-vermac_study_area$sensors
  direct<-unique(ver_pos$dir) 

  queue_length<-data.frame() 
  queue_position<-data.frame()
  delay_time<-data.frame()
  travel_time<-data.frame()
  seg_speed<-data.frame()

  vermac_speed_plot<-vermac_closure
  vermac_speed_plot<-vermac_speed_plot[c("time", "speed", "sensor_name", "dir")]
  df<-temp_sensor$selected[c('sensor_name', 'dir','dis' )]
  vermac_speed_plot<-merge(x=vermac_speed_plot, y=df, by.x=c("sensor_name", "dir"), by.y=c("sensor_name", "dir"), all.x=TRUE)

  
  vermac_count_plot<-filter(vermac_closure,vermac_closure$time %in% time_range)
  vermac_count_plot<-filter(vermac_count_plot, !is.na(vermac_count_plot$speed))


  
  #flow plot
  vermac_count_plot$category<-NA
  count_plot<-data.frame()
  for (i in 1: (length(speed_range)-1))
  {
    vermac_count_plot$category[vermac_count_plot$speed >= speed_range[i] & vermac_count_plot$speed< speed_range[i+1]]<-speed_category$unit[i]
  } 
  
  #for vermac queue estimation
  for (d in 1:length(direct))
  {
    ver_pos_study<-filter(ver_pos, ver_pos$dir==direct[d])
    ver_duplicate<-ver_pos_study[c("sensor_name", "dir")]
    ver_pos_study<-ver_pos_study[!duplicated(ver_duplicate), ]   
    ver_pos_study<-ver_pos_study[c("sensor_name", "dir", "long", "lat", "dis")]
    ver_pos_study<-ver_pos_study[order(ver_pos_study$dis), ]
    ver_pos_relative_mile<-ver_pos_study$dis
    
    ver_pos_dis<-c(ver_pos_study$dis[2:nrow(ver_pos_study)])
    date_tra<-filter(vermac_closure, vermac_closure$dir %in% direct[d])
    date_speed_raw<-date_tra[c("time", "speed", "sensor_name")]
    date_speed<-data.frame(time=time_range)
    q_length<-data.frame(time=time_range, length = 0, direct=direct[d])
    seg_date_speed<-data.frame(time=time_range)
    seg_length<-c()
    date_travel_time<-data.frame(time=time_range)
   
    
   
    
    for (i in 1:nrow(ver_pos_study))
    {
      df<-filter(date_speed_raw, date_speed_raw$sensor_name==ver_pos_study$sensor_name[i])
      df<-df[c('time', 'speed')]
      if (nrow(df)==0) 
      {
        df<-data.frame(speed=NA)
        date_speed<-cbind(date_speed, df)
        next
      }
      df<-aggregate(df$speed, by=list(df$time), FUN=mean, na.rm=TRUE)
      names(df)<-c("time", ver_pos_study$dis[i])
      date_speed<-merge(x=date_speed, y=df,by.x="time", by.y="time", all.x=TRUE, sort= TRUE)
    }
    names(date_speed)<-c("time", ver_pos_relative_mile)
    
    
    df<-array(c(data.matrix(date_speed[2: (ncol(date_speed)-1)]),  
                data.matrix(date_speed[3: ncol(date_speed)])), c(nrow(date_speed), (ncol(date_speed)-2), 2))
    df<-apply(df,c(1,2),mean, na.rm=TRUE)
    seg_date_speed<-data.frame(time_range, df)
    seg_length<-(ver_pos_relative_mile[2:length(ver_pos_relative_mile)] - ver_pos_relative_mile[1:(length(ver_pos_relative_mile)-1)])
    names(seg_date_speed)<-c("time", seg_length)
    

       
    date_travel_time<-cbind(date_travel_time, seg_length/(seg_date_speed[, 2:ncol(seg_date_speed)]))
   
    
    names(date_travel_time)<-c("time", seg_length)
    
    # queue length
    for (i in 2:ncol(seg_date_speed))
    {
      a<-which(seg_date_speed[i]<=threshold)
      q_length$length[a]<-(q_length$length[a]+as.numeric(names(seg_date_speed[i])))
    } 
    queue_length<-rbind(queue_length, q_length)
    # queue position

    for (i in 1:nrow(seg_date_speed))
    {
      df<-seg_date_speed[i, 2:ncol(seg_date_speed)]
      if (length(which(df<=threshold)) == 0)
      {
        dt<-data.frame(time=seg_date_speed[i, 1], distance = 0, Position="Start", direct=direct[d])
        queue_position<-rbind(queue_position, dt)
        dt<-data.frame(time=seg_date_speed[i, 1], distance = 0, Position="End", direct=direct[d])
        queue_position<-rbind(queue_position, dt)       
        next
      }
      b<-which(df>threshold)
      queue_head<-0
      queue_tail<-0
      for (j in 1: ncol(df))
      {
        if (is.na(df[j]))
          next
        if (df[j]<= threshold)
        {
          queue_tail<-ver_pos_dis[j]
        }
      }
      if (queue_tail > 0)
      {
        a<-which(df==min(df))
        queue_head<-max(ver_pos_dis[which(b<a)])
        if (queue_head=="-Inf") queue_head<-0
      }
      
      dt<-data.frame(time=seg_date_speed[i, 1], distance = queue_head, Position="Start", direct=direct[d])
      queue_position<-rbind(queue_position, dt)
      dt<-data.frame(time=seg_date_speed[i, 1], distance = queue_tail, Position="End", direct=direct[d])
      queue_position<-rbind(queue_position, dt)
      
      queue_head<-0
      queue_tail<-0
    }    
    t_closure_time<-data.frame()
    t_normal_time<-data.frame()
    t_time<-data.frame()
    if (ncol(date_travel_time)<=2)
    {
      t_closure_time<-data.frame(time=time_range, tt= date_travel_time[2], direct=direct[d], type="Closure Date")
      t_time<-rbind(t_closure_time, t_normal_time)
      names(t_time)<-c("time", "tt", "direct", "type")
    }else{
      t_closure_time<-data.frame(time=time_range, tt=rowSums((date_travel_time[, 2:ncol(date_travel_time)])*60, na.rm=TRUE), direct=direct[d], type="Closure Date")
      t_time<-rbind(t_closure_time, t_normal_time)
      names(t_time)<-c("time", "tt", "direct", "type")      
    }
    seg_date_speed<-data.frame(seg_date_speed, direct=direct[d])
    travel_time<-rbind(travel_time, t_time)
  }
  
  vermac_traffic$queue_length<-queue_length
  vermac_traffic$queue_position<-queue_position
  vermac_traffic$travel_time<-travel_time
  vermac_traffic$delay_time<-delay_time
  vermac_traffic$closure_count<-vermac_count_plot
  vermac_traffic$speed_plot<-vermac_speed_plot
  

  
 # updateButton(session, inputId="plots_download", disabled=FALSE, style="warning")

  })
  
  updateButton(session, inputId="save_analysis", disabled=FALSE, style="primary")
})


observe({
  
  if (is.null(vermac_study_area$sensors)){
    selected_flow_trailer<-filter(sensor_pos_map,sensor_pos_map$dir==as.character(input$plot_be_display_flow))     
  }else{
    
    selected_flow_trailer<-filter(vermac_study_area$sensors,vermac_study_area$sensors$dir==as.character(input$plot_be_display_flow))
  }
  
  updateSelectInput(session, inputId="plot_vermac_be_display_flow", choices =  unique(selected_flow_trailer$sensor_name),
                    selected = selected_flow_trailer$sensor_name[1])
  
})
#flow plot 
observe({
  
  closure_count<-vermac_traffic$closure_count
  output$impact_vehicle_check<-renderText({HTML("")})

  if (is.null(dim(closure_count))){
    hide("ver_be_count")
    hide("ver_be_percent")
    output$ver_be_count<-NULL
    output$ver_be_percent<-NULL

    return()
  }
  withProgress(message='Displaying the plots',{
  his_count<-vermac_traffic$refer_ana
  impact_count<-vermac_traffic$closure_ana
  
  
  pos_dir<-filter(vermac_study_area$sensors, vermac_study_area$sensors$dir==as.character(input$plot_be_display_flow))
  pos_dir<-pos_dir[order(pos_dir$dis), ]
  if (as.character(input$plot_vermac_be_display_flow) != "All"){
    pos<-filter(pos_dir, pos_dir$sensor_name== as.character(input$plot_vermac_be_display_flow))$sensor_name
  }else{
    
    pos<-pos_dir$sensor_name
  }
  if (length(pos)==0) return()
  #dnstream<-max(which(pos_dir$dis<pos$dis[1]))
  #distance<- pos$dis[1]-pos_dir$dis[dnstream]
  #if (is.na(distance)) distance<-1
  #distance<-1  
  
  #############################
  #####Speed distribution######
  #############################
  closure_count<-closure_count[c(closure_count$sensor%in% pos & closure_count$dir==as.character(input$plot_be_display_flow)),]
  
  if (nrow(closure_count)==0)
  {
    output$impact_vehicle_check<-renderText({HTML("No data")})
    hide("ver_be_count")
    hide("ver_be_percent")
    output$ver_be_count<-NULL
    output$ver_be_percent<-NULL
    return()
  }
  closure_count_dist<-aggregate(closure_count$count, by=list(closure_count$category), FUN=sum)
 # closure_count_sum<-aggregate(closure_count$count, by=list(closure_count$sensor), FUN=sum)
  names(closure_count_dist)<-c("speed_unit", "count")
 # names(closure_count_sum)<-c("sensor", "sum")  
  
  #closure_count_dist<-merge(x=closure_count_dist, y=closure_count_sum, by.x="sensor", by.y="sensor", all.x=TRUE)
  closure_count_dist<-merge(x=closure_count_dist, y=speed_category, by.x="speed_unit", by.y="unit", all.y=TRUE) 
  closure_count_dist$count[is.na(closure_count_dist$count)]<-0
  closure_count_dist$ttt<-as.integer(closure_count_dist$tt*closure_count_dist$count)
  closure_count_dist$percent<-as.integer(closure_count_dist$count/sum(closure_count_dist$count, na.rm=TRUE)*100) 


  df<-filter(closure_count_dist, closure_count_dist$count!= 0)
  m <- list(
  #  l = 50,
  #  r = 20,
 #   b = 20,
   t = 100
    
  )

  a<-plot_ly(data=df, 
             labels=~label, 
             values=~count, 
             marker=list(
               colors=df$color,
               line = list(color = 'black', width = 1)
               ),
  sort = FALSE,
  type="pie"
  ) %>%
    layout(title="Speed Distribution %",
           autosize = F, margin=m
    )#%>%
    #subplot(nrows = length(pos), shareX = TRUE)
  
  output$ver_be_percent<-renderPlotly({a})


  
  #############################################
  ####################travel time##############
  #############################################
  output$ver_be_tt<-renderPlot({ 
    ggplot(data=speed_category, mapping=aes(x=reorder(speed_unit, value), y=as.integer(tt), fill=speed_unit), size=2)+
      geom_col()+
      geom_text(aes(x=speed_unit, y = (tt/2),label = paste(format(round(tt,0), big.mark=","))), position = "identity")+
      scale_fill_manual(values=c(speed_category$color), aesthetics = "fill")+
      
      theme_classic()+
      theme(axis.title = element_text(size = rel(1.2)),
            axis.text= element_text(size=rel(1)),
            # axis.text.x = element_text(angle=270),
            plot.title = element_text(hjust=0.5),
            legend.position='none'
      ) +
      #  facet_grid(rows=vars(count_plot$Sensor), scales="free_y")+
      labs(title="Travel Time")+
      xlab("Speed")+ ylab("Travel Time (mins)")
    
  })#breaks=c(speed_unit_label), 
  ###############################################
  ###################Volume######################
  ###############################################
  df<-closure_count_dist
  df$speed_unit<-paste(df$speed_unit, "\n", as.integer(speed_category$tt), "\nmin", sep="")
  output$ver_be_count<-renderPlot({ 
    ggplot(data=df, mapping=aes(x=reorder(speed_unit, value), y=count, fill=speed_unit), size=2)+
      geom_col()+
      scale_fill_manual(values=c(closure_count_dist$color), aesthetics = "fill")+
      geom_text(aes(x=speed_unit, y = (count/2),label = paste(format(round(count,0), big.mark=","))), position = "identity")+
     # scale_x_discrete()+
     # theme_classic()+
      theme(axis.title = element_text(size = rel(1.2)),
            axis.text= element_text(size=rel(1)),
            # axis.text.x = element_text(angle=270),
            plot.title = element_text(hjust=0.5),
            legend.position='none'
      ) +
      #  facet_grid(rows=vars(count_plot$Sensor), scales="free_y")+
      labs(title="Speed Distribution and Corresponding Travel Time per Mile")+
      xlab("Speed and Travel Time per Minute")+ ylab("Vehicles")
    
  })#breaks=c(speed_unit_label),
  
  ###############################################
  ################total travel time##############
  ###############################################
  ###############################################  
  
  output$ver_be_ttt<-renderPlot({ 
    ggplot(data=closure_count_dist, mapping=aes(x=reorder(speed_unit, value), y=as.integer(ttt), fill=speed_unit), size=2)+
      geom_col()+
      scale_fill_manual(values=c(closure_count_dist$color), aesthetics = "fill")+
      geom_text(aes(x=speed_unit, y = (ttt/2),label = paste(format(round(ttt,0), big.mark=","))), position = "identity")+
      scale_x_discrete()+
     # theme_classic()+
      theme(axis.title = element_text(size = rel(1.2)),
            axis.text= element_text(size=rel(1)),
            # axis.text.x = element_text(angle=270),
            plot.title = element_text(hjust=0.5),
            legend.position='none'
      ) +
      #  facet_grid(rows=vars(count_plot$Sensor), scales="free_y")+
      labs(title="Total Travel Time per Speed Distribution per Mile")+
      xlab("Speed")+ ylab("Travel Time (mins)")
    
  })#breaks=c(speed_unit_label),  
  
  #####################################################
  ##################Impacted Vehicles##################
  #####################################################
  
  
  impact_count<-impact_count[c(impact_count$sensor %in% pos & impact_count$dir == as.character(input$plot_be_display_flow) ), ]
  volume_impact<-sum(impact_count$count, na.rm=TRUE)

  volume_impact<-data.frame(flow=volume_impact, type='Closure Date')
  
  output$ver_be_compare<-renderPlot({ 
    ggplot(data= volume_impact)+
      geom_histogram( mapping=aes(x=type, y=flow, fill=type), size=2, stat = "identity", show.legend = FALSE)+
      geom_text(aes(x=type, y = (flow/2),label = paste(format(round(flow,0), big.mark=","),"\n" ,sep=""), position = "identity"))+
      
      #  annotate("text", x=volume_compare$type[2], y=max(volume_compare$flow)/2, label = paste(format(round(dif,0), big.mark=","), "%", sep=""), size=5)+
      theme_classic()+
      theme(axis.title = element_text(size = rel(1.2)),
            axis.text= element_text(size=rel(1)),
            axis.title.x=element_blank(),
            plot.title = element_text(hjust=0.5)
      ) +
      #  facet_grid(rows=vars(count_plot$Sensor), scales="free_y")+
      labs(title="Detected Vehicles During the Analysis Hours")+
      ylab("Number of Vehicles")
    
  })
  
  
  })
})
#queue position length and delay plot
observe( {
  
  output$delay_check<-renderText({HTML("")})
  queue_length<-vermac_traffic$queue_length
  travel_time<-vermac_traffic$travel_time
  queue_position<- vermac_traffic$queue_position
  speed_plot<-vermac_traffic$speed_plot
  vermac_start<-vermac_study_area$start
  vermac_end<-vermac_study_area$end
  
  #time_frame<-vermac_traffic$time_range
  
 if (is.null(dim(queue_length)) 
     & is.null(dim(travel_time)) 
     & is.null(dim(queue_position)) 
     & is.null(dim(speed_plot))  
     ){
   hide("ver_be_queue_length")
   hide("ver_be_queue_pos")
   hide("ver_be_tt_pos")
   hide("ver_be_delay_pos")
   output$ver_be_queue_length<-NULL
   output$ver_be_queue_pos<-NULL
   output$ver_be_tt_pos<-NULL
   output$ver_be_delay_pos<-NULL
   return()
  }
  withProgress(message='Displaying the plots',{
  queue_length<-filter(queue_length, queue_length$direct==as.character(input$plot_be_display))
  queue_position<-filter(queue_position, queue_position$direct==as.character(input$plot_be_display))
  speed_plot<-filter(speed_plot, speed_plot$dir==as.character(input$plot_be_display))
  travel_time<-filter(travel_time, travel_time$direct==as.character(input$plot_be_display))
  vermac_start<-filter(vermac_start, vermac_start$dir==as.character(input$plot_be_display))
  vermac_end<-filter(vermac_end, vermac_end$dir==as.character(input$plot_be_display))
 
  if (nrow(speed_plot)==0)
  {
    output$delay_check<-renderText({HTML("This direct does not have data")})
    updateButton(session, inputId="be_info_select", label="Created Plot" , disabled=FALSE,style="success")
    hide("ver_be_queue_length")
    hide("ver_be_queue_pos")
    hide("ver_be_tt_pos")
    output$ver_be_queue_length<-NULL
    output$ver_be_queue_pos<-NULL
    output$ver_be_tt_pos<-NULL
    
    
    return()
  }
  
  time_frame<-seq(from=min(queue_length$time), to=max(queue_length$time), by=900)
  
  output$ver_be_queue_length<-renderPlot({ 
    ggplot(data=queue_length, mapping=aes(time, length))+
      geom_line(size=1, color="black", alpha=0.6)+
      #scale_x_datetime(limits=c(min(queue_length$time), max(queue_length$time)), labels=date_format("%m-%d %H:%M", tz='America/Chicago'))+
      scale_x_datetime(breaks= time_frame, labels=date_format("%m-%d %H:%M", tz='America/Chicago'))+
      scale_y_continuous(limits=c(0, max(queue_length$length)+0.5), expand = c(0, 0))+
      theme_classic()+
      theme(axis.title = element_text(size = rel(1.2)),
            axis.text= element_text(size=rel(1)),
            axis.text.x= element_text(angle=90),
            plot.title = element_text(hjust=0.5, size=15, color="black")
      ) +
      labs(title=paste("Queue Length \nFrom ", vermac_start$present_name, " to ", vermac_end$present_name, sep=""))+
      xlab("Time")+ ylab("Length (mile)")    
    
  })
  
 travel_time<-filter(travel_time, !travel_time$time==max(travel_time$time))
  tt_plot<-    
    ggplot(data=travel_time, mapping=aes(x=time, y=tt, color=type))+
    geom_line(size=1,  alpha=0.6)+
    scale_x_datetime(breaks= time_frame, labels=date_format("%m-%d %H:%M", tz='America/Chicago'))+
    theme_classic()+
    theme(axis.title = element_text(size = rel(1.2)),
          axis.text= element_text(size=rel(1)),
          axis.text.x= element_text(angle=90),
          plot.title = element_text(hjust=0.5, size=12),
          legend.title=element_blank()

    ) +
    labs(title=paste("Travel time \nFrom ", vermac_start$present_name, " to ", vermac_end$present_name, sep=""))+
    xlab("Time")+ ylab(paste("Travel time (mins per vehicle)", sep="")) 
  tt_plot<-ggplotly(tt_plot)
  
  output$ver_be_tt_pos<-renderPlotly({tt_plot}) 
  
    
  
  

  queue_plot<-ggplot()+
    geom_point(data=speed_plot, mapping=aes(x=time, y=dis, color=speed, group=sensor_name), size=2)+
    geom_line(data=queue_position, mapping=aes(x=time, y=distance, linetype=Position), size=1, alpha=0.6)+
    #geom_text(data=speed_plot, mapping=aes(label=sensor,x=(min(time)+300), y= (dis+0.2)), stat = "identity", alpha=0.8, size=3)+
    scale_colour_gradientn(colours=c("red", "green"), limits=c(0, 75))+
    scale_x_datetime(breaks= time_frame, labels=date_format("%m-%d %H:%M", tz='America/Chicago'))+
    scale_y_continuous(limits=c(0, max(speed_plot$dis)+0.5))+
    guides(type=guide_legend(order=1), col = guide_colourbar(ncol = 1, order=2))+
    theme_classic()+
    theme(axis.title = element_text(size = rel(1.2)),
          axis.text= element_text(size=rel(1)),
          axis.text.x = element_text(angle=90),
          plot.title = element_text(hjust=0.5),
          legend.position="right"
    ) +
    labs(title=paste("Queue Position \nFrom ", vermac_start$present_name, sep=""), col=NULL, linetype=NULL)+
    xlab("Time")+ ylab(paste("Distance (miles)" ,sep=""))
    queue_plot<-ggplotly(queue_plot)
  #queue_plot<-queue_plot %>% layout(showlegend=TRUE)
  #queue_plot<-queue_plot+plot_ly(data=speed_plot, y=~sensor)
  output$ver_be_queue_pos<-renderPlotly({queue_plot})
  
 # write.csv(queue_position, 'queue_position.csv', sep=",")
 # write.csv(queue_length, 'queue_length.csv', sep=",")
 # write.csv(delay_time, 'delay_time.csv', sep=",")
  
  updateButton(session, inputId="be_info_select", label="Created Plot" , disabled=FALSE,style="success")
  
  })
})

observe({
  
  if (!is.null(dim(vermac_traffic$closure_raw)) & !is.null(dim(vermac_traffic$refer_raw)) ){
    if (nrow(vermac_traffic$closure_raw)>0 & nrow(vermac_traffic$refer_raw)){
      
      updateButton(session, inputId="be_info_select", label="Create Plot" , disabled=FALSE)
    }
    else{
      updateButton(session, inputId="be_info_select", label="Create Plot" , disabled=FALSE)
    }
    
  }
  
})







##end

#no use

observeEvent(input$temp_info_update1, {
  
  abc<-123
  closure_info<-hot_to_r(input$temporary_info$data)
  if (input$temp_info_select==1)
  {
    temp_sensor_info<- closure_info
  }else{
    
    temp_sensor_info<-filter(temp_sensor_info, !temp_sensor_info$closure_id==input$temp_closure_name)
    temp_sensor_info<-rbind( temp_sensor_info, closure_info)
  }
  
  con <- dbConnect(odbc::odbc(),
                   Driver = "SQL Server", #ODBC Driver 13 for SQL Server
                   Server = "204.144.121.89",
                   # Server="204.144.121.89",
                   Database = "CCAT",
                   UID = "sql_ut",
                   # PWD = rstudioapi::askForPassword("")
                   PWD="mEQW43FAbddjJnBJ",
                   Port = 1433)
  
  dbWriteTable(con, 'closure_info_temp_sensor',  temp_sensor_info, overwrite=TRUE, row.names=FALSE )
  
  
})
observe({

  if (is.null(input$temporary_info$changes$changes))
    return()
  abc<-123
  
  hot_to_r(input$temporary_info)
  #bsButton(inputId="temp_info_update", "Refresh Closure Info", distabled=FALSE, style="primary") 
  
})

  
})











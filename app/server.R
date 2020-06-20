shinyServer(function(input, output, session) {

  map_cnt<-leaflet() %>%
    addProviderTiles("CartoDB.Positron") %>%
    setView(lat = 41.269988,
            lng=  -103.391310,
            zoom = 3
    )
  
  map_dur<-leaflet() %>%
    addProviderTiles("CartoDB.Positron") %>%
    setView(lat = 41.269988,
            lng=  -103.391310,
            zoom = 3
    )
  map_max<-leaflet() %>%
    addProviderTiles("CartoDB.Positron") %>%
    setView(lat = 41.269988,
            lng=  -103.391310,
            zoom = 3
    )
  
  output$stationMax<- renderLeaflet({map_max})
  output$stationAvg<- renderLeaflet({map_avg}) 
  
  output$company_count<-renderPlotly({company_total_compare_plot(company_total_count, 'By frequency')})
  output$company_dur<-renderPlotly({company_total_compare_plot(company_total_dur, 'By duration')})
  output$company_count_year<-renderPlotly({company_year_compare_plot(company_year_count, 'By frequency')})
  output$company_dur_year<-renderPlotly({company_year_compare_plot(company_year_dur, 'By duration')})
  
  output$company_avg_dur<-renderPlotly({company_cut_plot}) 
  
  
observeEvent(input$company_select,{
  substation<-filter(station, station$company==input$company_select)
  id<-unique(substation$uid)
  sub=data.frame()
  for (i in 1: length(id)){
    s<-filter(station_usage, station_usage$station_id==id[i])
    s<-filter(s, s$dur==max(s$dur))
    sub<-rbind(sub, s)
  }
  abc<-123
  sub<-base::merge(sub, station, by.x='station_id', by.y='uid', all.x=TRUE)
  pal <- colorNumeric(palette="Spectral", domain =sub$rent)
  map_max<-map_max%>%setView(
            lat = mean(substation$lat),
            lng= mean(substation$lon),
            zoom = 11
    )%>%addCircleMarkers(
      data=sub,
      lat=~lat,
      lng=~lon,
      #radius=3,
      radius=~(abs(rent)+3),
      color=~pal(rent),
      label=~paste(rent)
    )%>%addLegend("bottomright", pal = pal, values = sub$rent,
              title = "Rent(+)/Return(-)",
            #  labFormat = labelFormat(transform = function(x) sort(x, decreasing = TRUE)),
              opacity = 1
    )
  sub<-filter(station_total_count, station_total_count$station_id%in%id)
  sub<-base::merge(sub, station, by.x='station_id', by.y='uid', all.x=TRUE)
  pal <- colorNumeric(palette="Spectral", domain =sub$avg)
  map_cnt<-map_cnt%>%setView(
    lat = mean(substation$lat),
    lng= mean(substation$lon),
    zoom = 11
  )%>%addCircleMarkers(
    data=sub,
    lat=~lat,
    lng=~lon,
    #radius=3,
    radius=~(abs(avg)+3),
    color=~pal(avg),
    label=~paste(avg)
  )%>%addLegend("bottomright", pal = pal, values = sub$avg,
                title = "Rent(+)/Return(-)",
                #  labFormat = labelFormat(transform = function(x) sort(x, decreasing = TRUE)),
                opacity = 1
  )
  sub<-filter(station_total_dur, station_total_dur$station_id%in%id)
  sub<-base::merge(sub, station, by.x='station_id', by.y='uid', all.x=TRUE)  
  pal <- colorNumeric(palette="Spectral", domain =sub$avg)
  map_dur<-map_dur%>%clearMarkers()%>%setView(
    lat = mean(substation$lat),
    lng= mean(substation$lon),
    zoom = 11
  )%>%addCircleMarkers(
    data=sub,
    lat=~lat,
    lng=~lon,
    #radius=3,
    radius=~(abs(avg)+3),
    color=~pal(avg),
    label=~paste(avg)
  )%>%addLegend("bottomright", pal = pal, values = sub$avg,
                title = "Rent(+)/Return(-)",
                #  labFormat = labelFormat(transform = function(x) sort(x, decreasing = TRUE)),
                opacity = 1
  )  
  output$stationCnt<-renderLeaflet({map_cnt})
  output$stationDur<-renderLeaflet({map_dur})
  
})


})











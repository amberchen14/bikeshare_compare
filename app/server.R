shinyServer(function(input, output, session) {

  map1<-leaflet() %>%
    addProviderTiles("CartoDB.Positron") %>%
    setView(lat = 41.269988,
            lng=  -103.391310,
            zoom = 3
    )
  output$shareMap<- renderLeaflet({map1})
  output$company_avg_dur<-renderPlotly({company_agg_dur})
  
observeEvent(input$company_select,{
  substation<-filter(station, station$company==input$company_select)
  id<-unique(substation$uid)
  sub=data.frame()
  for (i in 1: length(id)){
    s<-filter(station_usage, station_usage$station_id==id[i])
    s<-filter(s, s$dur==max(s$dur))
    sub<-rbind(sub, s)
  }
  sub<-merge(sub, station, by.x='station_id', by.y='uid', all.x=TRUE)
  pal <- colorNumeric(palette="Spectral", domain =sub$rent)
  map1<-map1%>%setView(
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
  output$shareMap<-renderLeaflet({map1})
  
})


})











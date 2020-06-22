shinyServer(function(input, output, session) {
  map_dur_avg<-leaflet() %>%
    addProviderTiles("CartoDB.Positron") %>%
    setView(lat = 41.269988,
            lng=  -103.391310,
            zoom = 3
    )
  map_dur_year<-map_dur_avg
  
  output$station_dur_avg<- renderLeaflet({map_dur_avg})
  output$station_dur_year<- renderLeaflet({map_dur_year}) 
  
  output$company_total<-renderPlotly({company_usage_compare_plot(company_total_year_usage, 'Total')})
  output$company_avg<-renderPlotly({company_usage_compare_plot(company_avg_year_usage, 'Average')})
  
observeEvent(input$company_select,{
  sub_avg<-filter(station_avg_usage, station_avg_usage$company==input$company_select)
  sub_avg<-station_usage_max_freq(sub_avg)
  pal <- colorNumeric(palette="Spectral", domain = sub_avg$rent)
  map_dur_avg<-map_dur_avg%>%setView(
    lat = mean(sub_avg$lat),
    lng= mean(sub_avg$lon),
    zoom = 11
  )%>%clearMarkers()%>%clearControls()%>%
    addCircleMarkers(
    data=sub_avg,
    lat=~lat,
    lng=~lon,
    #radius=3,
    radius=~(abs(rent)+3),
    color=~pal(rent),
    label=~paste(rent)
  )%>%addLegend("bottomright", pal = pal, values = sub_avg$rent,
                title = "Rent(+)/Return(-)",
                #  labFormat = labelFormat(transform = function(x) sort(x, decreasing = TRUE)),
                opacity = 1
  )
  output$station_dur_avg<-renderLeaflet({map_dur_avg})
  #Show station usage by year
  station_year_max_usage<-data.frame()
  df<-filter(station_year_usage, station_year_usage$company==input$company_select)
  years<-unique(df$year)
  for (y in 1: length(years)){
    dff<-filter(df, df$year==years[y])
    station_year_max_usage<-rbind(station_year_max_usage, station_usage_max_freq(dff))
  }  
  map_dur_year<-map_dur_year%>%setView(
    lat = mean(sub_avg$lat),
    lng= mean(sub_avg$lon),
    zoom = 11
  )%>%clearMarkers()%>%clearControls()
    
  #Revise year rage 
  updateSliderInput(session, 'company_year',
                    min=min(unique(station_year_max_usage$year)),
                    max=max(unique(station_year_max_usage$year)),
                    value=max(unique(station_year_max_usage$year))
  )  
  observeEvent(input$company_year, {
    pal_max <- colorNumeric(palette="Spectral", domain = station_year_max_usage$rent) 
    sub_year<-filter(station_year_max_usage,   station_year_max_usage$year==input$company_year)    
    map_dur_year<-map_dur_year%>%
      clearMarkers()%>%
      clearControls()%>%
      addCircleMarkers(
        data=sub_year,
        lat=~lat,
        lng=~lon,
        #radius=3,
        radius=~(abs(rent)+3),
        color=~pal_max(rent),
        label=~paste(rent)
    )%>%addLegend("bottomright", pal = pal_max, 
                     values = sub_year$rent,
                     title = "Rent(+)/Return(-)",
                     #  labFormat = labelFormat(transform = function(x) sort(x, decreasing = TRUE)),
                     opacity = 1
    )    
    output$station_dur_year<-renderLeaflet({map_dur_year}) 

  })
  
})




})











navbarPage("Hot Bikeshare", 
           id="nav",
           theme = shinytheme("darkly"),
           tabPanel("Compare",
                    div(class="outer",
                        tags$head(
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),                    
            h4('Station usage'),
            splitLayout(cellWidths=c("50%", "50%"),
            plotlyOutput('company_total'),
            plotlyOutput('company_avg')                       
                        )
            )#End of company dev
            ), #End of company tabPnael
           tabPanel("Change of bike number",
                    div(class="outer",
                        tags$head(
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),           
          #plotlyOutput('company_avg_dur', width="70%", height="65%"),
          selectInput("company_select", h4("Company selection"), company_name, 
                      selected = company_name[1], multiple = FALSE) , 
          h5('Average'),
          leafletOutput("station_dur_avg", width="70%", height="65%"),
          h5('Across year'),          
          sliderInput("company_year", 
                      "Year range", 
                      min=min(unique(station_year_usage$year)),
                      max=max(unique(station_year_usage$year)),
                      value=max(unique(station_year_usage$year)),
                      step = 1,
                      animate=animationOptions(interval = 2000, loop = TRUE)),
                      leafletOutput("station_dur_year", width="70%", height="65%")                        
                      
                    
         
                    )# End of div 
           )  #End of tabPanel
                      

)##Closing navBarPage

navbarPage("Bikeshare Compare", 
           id="nav",
           theme = shinytheme("darkly"),
           tabPanel("Company", value=1,
                    div(class="outer",
                        tags$head(
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),
                        h4('#Rented bikes'),
                        splitLayout(cellWidths=c("50%", "50%"),
                        plotlyOutput('company_count'),
                        plotlyOutput('company_dur')                       
                                    ),
                        h4('#Rented bikes across years'),
                        splitLayout(cellWidths=c("50%", "50%"),
                                    plotlyOutput('company_count_year'),
                                    plotlyOutput('company_dur_year')                       
                        )
                    )##Closing outer division
           ), ##Closing Tab Panel 1
           tabPanel("Station", value=1,
                    div(class="outer",
                        tags$head(
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),
                        #plotlyOutput('company_avg_dur', width="70%", height="65%"),
                        selectInput("company_select", h4("Company selection"), company_name, 
                                    selected = company_name[1], multiple = FALSE) ,                       
                        leafletOutput("stationCnt", width="70%", height="65%"),
                        br(),
                        leafletOutput("stationDur", width="70%", height="65%")                        
                    )##Closing outer division
           ) ##Closing Tab Panel 2         
)##Closing navBarPage

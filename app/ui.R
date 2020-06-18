navbarPage("Bikeshare Compare", 
           id="nav",
           theme = shinytheme("darkly"),
           tabPanel("Analysis Setup", value=1,
                    div(class="outer",
                        tags$head(
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),
                        h4('Average duration across number of rented bikes across cities'),
                        plotlyOutput('company_avg_dur', width="70%", height="65%"),
                        selectInput("company_select", h4("Company selection"), company_name, 
                                    selected = company_name[1], multiple = FALSE) ,                       
                        leafletOutput("shareMap", width="70%", height="65%")
                    )##Closing outer division
           ) ##Closing Tab Panel 1
)##Closing navBarPage

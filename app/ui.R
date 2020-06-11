navbarPage("Work Zone Traffic Information", 
           id="nav",
           theme = shinytheme("lumen"),
           tabPanel("Temporary Sensor Setup", 
             div(class="outer",
                 tags$head(
                   includeCSS("styles.css"),
                   includeScript("gomap.js"),
                   tags$style(
                     HTML('#sidebarPanel {background-color: #dec4de;}')
                   )
                 ),
                 sidebarLayout(
                 sidebarPanel(width=8, 
                  splitLayout(cellWidths=c("70%", "30%"),
                  wellPanel(                   
                  h3('Closure Info for temporary sensors'),
                   radioButtons(inputId='temp_info_select', label=NULL, choiceNames=c('All closure', 'Select one'), choiceValues = c(1, 2), selected=1),
                 #  conditionalPanel(condition='input.temp_info_select==2',
                  #                selectInput(inputId='temp_closure_name', label='Choose Clousre ID', choices=temp_sensor_info$closure_id)
                   #               ),
                   textOutput("temp_sensor_infor_ava"),
                   rHandsontableOutput('temporary_info')
                #bsButton(inputId="temp_info_update", "Refresh Closure Info", distabled=TRUE, style="primary") 
                 ),   
                 wellPanel(
                 h3('Add Closure Info Table'),
              #  radioButtons(inputId='temp_info_update', label="Update Type", 
              #               choiceNames=c('Add New Closure', 'Add sesnsor on existing closure'), choiceValues = c(1, 2), selected=1),
              #   conditionalPanel(condition='input.temp_info_update==1',
                                  textInput(inputId='cid', label='Closure ID', value = NULL, width = NULL, placeholder = TRUE),
                                  br(),
                                  h4('Set Start Time'),
                                  p('Start date will be set to current date'),
                                  splitLayout(cellWidths = c("50%", "50%"),
                                   numericInput('shour','Hour',as.integer(hour(Sys.time())),0,24,1,200),
                                   numericInput('smin','Minute',as.integer(minute(Sys.time())),0,60,1,200)
                                                         
                                  ),
              
              
              
              
                                  bsButton(inputId='closure_stime_select', label='Set Start Time'),
                                  
                                  
                                  textOutput(outputId='closure_stime'),
                                  h4('Select End Date (+days)'),
                                  selectInput("closure_etime_select", label=NULL,  choice=c(1, 2, 3, 4, 5), selected=3),
                                  br(),
                                  h4('Select Sensors'),
                                  radioButtons(inputId='closure_sensor_type', label= NULL, 
                                               choiceNames = c('All temporary sensors', 'Specific sensors'),
                                               choiceValues = c(1, 2), 
                                               selected=1),
                                  conditionalPanel(condition='input.closure_sensor_type==2',
                                                   h5("Click sensor on the map"), 
                                                   tags$head(tags$style("#trailer_start_be{overflow-x:scroll;}"))
                                                  
                                                               
         
                                   ), #conditional Panel end
                                   rHandsontableOutput("closure_selected_sensor"),
                                   bsButton(inputId="temp_sensor_add_select", "Save Closure", size="8", style="primary")                             
                                #  )
                 )# end of absolutePanel 2
               )#end split layout
               ), #end of sidePanel
                mainPanel(width=3,
                br(),
                
                leafletOutput("mapAustin1") # end of Panel 3
                
               ),#end main Panel
               position = c("left", "right"),
               fluid = TRUE
              )# end sidebar Layout
             ) # end of div
           ), # end of tab
           
           tabPanel("Analysis Setup", 
                    div(class="outer",
                        tags$head(
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),
                        leafletOutput("mapAustin6", width="50%", height="65%"),
                        br(),
                        absolutePanel(id = "controls_tab4_1", 
                                      #class = "panel panel-default", fixed = TRUE,
                                      draggable = FALSE, 
                                      top = 20, 
                                      left = "auto", 
                                      right = "25%", 
                                      bottom = "auto",
                                      width = "24%", 
                                      height = "auto",
                                      tags$head(includeCSS("styles.css")), 
                                      
                                      wellPanel(
                                        
                                        h4("1- Select Closure ID"), 
                                        selectInput( "closure_id", label="Closure ID", choices =c("testingtime","closure_0531_845","closure_0531_1130"), selected=c("testingtime")),
                                        selectInput( "unique_id", label="Unique ID", 
                                                     choices =c("12","4","16","18"),
                                                     selected=c("12")
                                                     ),
                                        bsButton(inputId='unique_id_refresh', label='Refresh'),
                                        tableOutput('selected_closure_info'),
                                        textOutput('selected_closure_tperiod1')
                                      ),
                                      
                                      wellPanel(
                                        h4("4-Parameters for Analysis"),
                                        
                                        selectInput( inputId="be_ffs", "Queue Speed Threshold (mph)",
                                                     choices = seq(from=10,to=50, by=5)),
                                        checkboxInput(inputId="be_sm_factor", label= "Smooth data", value = FALSE, width = NULL),
                                        p(
                                          class = "text-muted",
                                          HTML("Smoothing uses a rolling 10-minute average to report the speed and volumes every 5 minutes")
                                        ),

                                        bsButton(inputId="be_info_select", "Create Plots", disabled=TRUE, style="primary"),
                                        p(
                                          class = "text-muted",
                                          HTML("Make sure that \"Retrieve Data\" buttons are <b>GREEN</b> before creating plots")
                                        ),
                                        tags$head(tags$style(HTML(".shiny-split-layout > div {overflow: visible;}")))
                                      ), #cLOSE WELL PANEL ANALYSIS PARAMETERS  

                                      
                                      p(
                                        class = "text-muted",
                                        HTML("Make sure that \"Create Plots\" buttons are <b>GREEN</b> before creating plots")
                                      )
                                      
                        ),  ##Closing absolute panel1
                        absolutePanel(id = "controls_tab4_2", 
                                      #class = "panel panel-default", fixed = TRUE,
                                      draggable = FALSE, 
                                      top = 20, 
                                      left = "auto", 
                                      right = 10, 
                                      bottom = "auto",
                                      width = "24%", 
                                      height = "auto",
                                      tags$head(includeCSS("styles.css")), 
                                      wellPanel(
                                        fixedRow(
                                          h4("2- Select study area"), 
                                          radioButtons("ver_be_area_select_input", "", c("Analyze all available corridors (end-to-end)"=1, 
                                                                                         "Select corridor sub-section"= 2)) ,
                                          wellPanel(
                                            conditionalPanel(
                                              condition = "input.ver_be_area_select_input == 2",
                                              selectInput( "bg_road", "Corridor", choices =road_name$road, selected=road_name$road[1]), 
                                              p(
                                                class = "text-muted",
                                                HTML("Select two sensors on corridor by <b>clicking on markers</b> and pressing <b>Select</b>"),
                                                HTML("Start and end sensors should not be connected")
                                              ),
                                              #bsButton(inputId="bg_road_select", "Choose", size="8", style="primary")   ,
                                              splitLayout(cellWidths = c("50%", "50%"),
                                                          verticalLayout(
                                                            h5("Start Sensor"),  
                                                            verbatimTextOutput(outputId="trailer_start_be", placeholder=TRUE),                          
                                                            #tags$head(tags$style("#trailer_start_be{overflow-x:scroll;}")), 
                                                            bsButton(inputId="trailer_start_be_select", "Choose", size="8", style="primary")                             
                                                          ),
                                                          verticalLayout(
                                                            h5("End Sensor"),  
                                                            verbatimTextOutput(outputId="trailer_end_be", placeholder=TRUE),                              
                                                            #tags$head(tags$style("#trailer_end_be{font-size: 16px;}")) ,
                                                            bsButton(inputId="trailer_end_be_select", "Choose", size="8", style="primary")   
                                                            
                                                          )
                                              )
                                              
                                              
                                            )#Close first conditional
                                            
                                            #,
                                            # conditionalPanel(
                                            #  condition = "input.ver_be_area_select_input == 'Use all'",
                                            #bsButton(inputId="vermac_total_select", "Choose", size="8", style="primary")
                                            # )                                              
                                            
                                          )                                            
                                        )                                          
                                        
                                      ), #cLOSE WELL PANEL SENSOR SELECTION
                                      
                                      wellPanel(
                                        h4("3- Select Time Period"), 
                                        textOutput('selected_closure_tperiod2'),
                                        splitLayout(cellWidths = c("50%", "50%"),
                                                    verticalLayout(
                                                      dateInput(inputId='be_date_start', label ="Start", 
                                                                value="5/31/2019",
                                                                min="5/31/2019",
                                                                max="6/02/2019",
                                                                
                                                                format = "mm/dd/yyyy"),              
                                                      selectInput( inputId="be_shr", label=NULL, choices = c(hr_range),selected=min(hr_range))
                                                    ),
                                                    verticalLayout(
                                                      dateInput(inputId='be_date_end', label ="End", 
                                                                value="5/31/2019",
                                                                min="5/31/2019",
                                                                max="6/02/2019",
                                                                format = "mm/dd/yyyy"),  
                                                      selectInput( inputId="be_ehr", label=NULL,choices = c(hr_range),selected=min(hr_range))
                                                    )
                                        ),
                                        splitLayout(cellWidths = c("50%", "50%"),
                                                    bsButton(inputId="trailer_be_time_select", "Retrieve Closure Data", size="8",disabled=TRUE,style="primary")
                                                    
                                        ),
                                        textOutput("ver_aval_be"),
                                        textOutput("ver_start_be"),
                                        textOutput("ver_end_be"),
                                        textOutput("ver_aval_data")
                                      )#cLOSE WELL PANEL DATA FOR CLOSURE DAY
                                     
                        )##Closing absolute panel2
                    )##Closing outer division
           ), ##Closing Tab Panle
           tabPanel("Output: Delay", 
                    div(class="outer",
                        tags$head(
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),
                        
                        selectInput( inputId="plot_be_display", "Direction",
                                     choices = c( "NB", "SB", "EB", "WB"), selected="NB"), 
                        #  bsButton(inputId="plot_be_display_select", "Choose", size="8", style="primary"),
                        textOutput("delay_check"),
                        plotOutput("ver_be_queue_length", width="70%"),
                        br(),
                        plotlyOutput("ver_be_queue_pos", width="70%"),
                        br(),
                        plotlyOutput("ver_be_tt_pos", width="70%")
                        
                        
                    )##Closing outer division
           ), ##Closing Tab Panle
           tabPanel("Output: Impacted Vehicles", 
                    div(class="outer",
                        tags$head(
                          includeCSS("styles.css"),
                          includeScript("gomap.js")
                        ),
                        
                        selectInput( inputId="plot_be_display_flow", "Direction",
                                     choices = c( "NB", "SB", "EB", "WB"), selected="NB"), 
                        
                        selectInput( inputId="plot_vermac_be_display_flow", "Sensor",
                                     choices =NULL, selected=NULL), 
                        textOutput("impact_vehicle_check"),
                        
                        plotlyOutput("ver_be_percent", width="50%"),
                        br(),
                        br(),
                        br(),

                        br(),
                        plotOutput("ver_be_count", width="50%"),
                        br(),

                        br(),
                        plotOutput("ver_be_ttt", width="50%"),
                        br(),
                        br(),
                        #    textOutput("ver_be_closure_volume"),
                        #    textOutput("ver_be_typical_volume"),
                        plotOutput("ver_be_compare", width="50%")
                  
                        
                        
                    )##Closing outer division
           )
)##Closing navBarPage

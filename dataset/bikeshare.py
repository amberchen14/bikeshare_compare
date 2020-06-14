import json
bluebike={"company": "bluebike",
           # "state": "MA",
            "city": "Boston",
            "trip_file":{
            	"keyword": "trip",
            	"version":[{
	                "start_time":"Start_Date",
	                "end_time": "End_Date",
	                "start_station_id": "Start_station_number",
	                #"start_station_name":"Start_station_name",
	                "end_station_id": "End_station_number",
	                #"end_station_name":"End_station_name",
	                "end_station_lon": "End_station_longitude",
	                "end_station_lat":"End_station_latitude",	                
	                "start_station_lon": "Start_station_longitude",
	                "start_station_lat":"Start_station_latitude"
            	},{           	
	                "start_time":"starttime",
	                "end_time": "stoptime",
	                "start_station_id": "start_station_id",
	                #"start_station_name":"start_station_name",
	                "start_station_lon": "start_station_longitude",
	                "start_station_lat":"start_station_latitude",
	                "end_station_id": "end_station_id",
	                #"end_station_name":"end_station_name",
	                "end_station_lon": "end_station_longitude",
	                "end_station_lat":"end_station_latitude"
            	},
            	]
            },
            "station_file": {
                "keyword": "station",
                "version":[{
	                "id": "number",
	                "name": "name",
	                "lon":"longitude",
	                "lat":"latitude"                 	
	                },{
		            "id": "station_id",
		            "name": "Station",
		            "lon":"longitude",
		            "lat":"latitude"                        
	            }
              ]

            }
}
citibike={"company": "citibike",
            "city": "NYC",
            "trip_file":{
                "keyword": "trip",
            	"version":[
            		{
            	    "start_time": "starttime",
                	"end_time": "stoptime",
                	"start_station_id": "start_station_id",
                	#"start_station_name":"start_station_name",
                	"start_station_lon": "start_station_longitude",
                	"start_station_lat":"start_station_latitude",
                	"end_station_id": "end_station_id",
                	#"end_station_name":"end_station_name",
                	"end_station_lon": "end_station_longitude",
                	"end_station_lat":"end_station_latitude"
                	},
            		{
            	    "start_time": "start_time",
                	"end_time": "stop_Time",
                	"start_station_id": "start_station_id",
                	#"start_station_name":"start_station_name",
                	"start_station_lon": "start_station_longitude",
                	"start_station_lat":"start_station_latitude",
                	"end_station_id": "end_station_id",
                	#"end_station_name":"end_station_name",
                	"end_station_lon": "end_station_longitude",
                	"end_station_lat":"end_station_latitude"
                	}                	
            	]
		},
		"station_file": {
				 "keyword": "none"
				 }  
}
divvy={"company": "divvy",
           # "state": "MA",
            "city": "Boston",
            "trip_file":{
                "keyword": "trip",
                "version":[{
                    "start_time":"start_time",
                    "end_time": "end_time",
                    "start_station_id": "from_station_id",
                   # "start_station_name":"from_station_name",
                    "end_station_id": "to_station_id"
                   # "end_station_name":"to_station_name"
                },{
                    "start_time":"start_at",
                    "end_time": "end_at",
                    "start_station_id": "start_station_id",
                    #"start_station_name":"start_station_name",
                    "end_station_id": "end_station_id",
                    #"end_station_name":"end_station_name",
                    "end_station_lon": "end_lng",
                    "end_station_lat":"end_lat",
                    "start_station_lon": "start_lng",
                    "start_station_lat":"start_lat"                 
                     }, {
                    "start_time":"01_-_rental_details_local_start_time",
                    "end_time": "01_-_rental_details_local_end_time",
                    "start_station_id": "03_-_rental_start_station_id",
                  # "start_station_name":"03_-_rental_start_station_name",
                    "end_station_id": "03_-_rental_end_station_id"
                   # "end_station_name":"03_-_rental_end_station_name"
                     }            
                ]
            },
            "station_file": {
                "keyword": "station",
                "version":[{
                    "id": "id",
                    "name": "name",
                    "lon":"longitude",
                    "lat":"latitude"                    
                    }

              ]

            }
}
lyft={
    "company": "lyft",
    "city":"SA"
            "trip_file":{
                "keyword": "trip",
                "version":[{
                    "start_time":"start_time",
                    "end_time": "end_time",
                    "start_station_id": "start_station_id",
                    #"start_station_name":"start_station_name",
                    "end_station_id": "start_station_id",
                    #"end_station_name":"start_station_name",
                    "end_station_lon": "end_station_longitude",
                    "end_station_lat":"end_station_latitude",
                    "start_station_lon": "start_station_longitude",
                    "start_station_lat":"start_station_latitude"                                        
                }
                ]
            },
            "station_file":{
				 "keyword": "none"
            }            


}
cogo={"company": "cogo",
           # "state": "MA",
        "city": "Boston",
        "trip_file":{
            "keyword": "trip",
            "version":[{          
                "start_time":"start_time",
                "end_time": "end_time",
                "start_station_id": "from_station_id",
              #  "start_station_name":"from_station_location",
                "end_station_id": "to_station_id"
             #   "end_station_name":"to_station_location"
            },{
                "start_time":"start_time_and_date",
                "end_time": "end_time_and_date",
                "start_station_id": "start_station_id",
               # "start_station_name":"start_station_name",
                "end_station_id": "stop_station_id",
                #"end_station_name":"stop_station_name",
                "start_station_lon": "start_station_long",
                "start_station_lat":"start_station_lat",
                "end_station_lon": "stop_station_long",
                "end_station_lat":"stop_station_lat",
            }
            ]
        },
        "station_file": {
            "keyword": "location",
            "version":[{
                "id": "number",
                "name": "name",
                "lon":"longitude",
                "lat":"latitude"                    
                },{
                "id": "station_id",
                "name": "Station",
                "lon":"longitude",
                "lat":"latitude"                        
            }
          ]

        }
}
capital={"company": "capital",
            "city": "DC",
            "trip_file":{
                "keyword": "trip",            
            	"version":[{           	
                "start_time":"start_date",
                "end_time": "end_date",
                "start_station_id": "start_station_number",
                #"start_station_name":"start_station",
                "end_station_id": "end_station_number"
                #"end_station_name":"end_station"
                },
                {              
                "start_time":"started_at",
                "end_time": "ended_at",
                "start_station_id": "start_station_id",
                #"start_station_name":"start_station_name",
                "end_station_id": "end_station_id",
                #"end_station_name":"end_station_name",
                "start_station_lon": "start_lng",
                "start_station_lat":"start_lat",
                "end_station_lon": "end_lng",
                "end_station_lat":"end_lat",                
                }
                ]
            },
         	"station_file": {
         	"keyword":"location",
         	"version": 
         	[{
         	"id": "id",
         	"name": "address",
            "lon":"longitude",
            "lat":"latitude"             	
         	}
         	]
         	}  
}

niceride={
	"company": "niceride",
            "city": "DC",
            	"trip_file":{
                "keyword": "trip",            
            	"version":[{           	
                "start_time":"start_time",
                "end_time": "end_time",
                "start_station_id": "start_station_id",
                #"start_station_name":"start_station_name",
                "end_station_id": "end_station_id"
                #"end_station_name":"end_station"
                }
                ]
            },
         	"station_file": {
         	"keyword":"location",
         	"version": 
         	[{
         	"id": "id",
         	"name": "address",
            "lon":"longitude",
            "lat":"latitude"             	
         	}
         	]
         	}  

}


citibike={"company": "citibike",
            "city": "NYC",
            "trip_file":{
                "keyword": "trip",
                "version":[
                    {
                    "start_time": "starttime",
                    "end_time": "stoptime",
                    "start_station_id": "start_station_id",
                    #"start_station_name":"start_station_name",
                    "start_station_lon": "start_station_longitude",
                    "start_station_lat":"start_station_latitude",
                    "end_station_id": "end_station_id",
                    #"end_station_name":"end_station_name",
                    "end_station_lon": "end_station_longitude",
                    "end_station_lat":"end_station_latitude"
                    },
                    {
                    "start_time": "start_time",
                    "end_time": "stop_Time",
                    "start_station_id": "start_station_id",
                    #"start_station_name":"start_station_name",
                    "start_station_lon": "start_station_longitude",
                    "start_station_lat":"start_station_latitude",
                    "end_station_id": "end_station_id",
                    #"end_station_name":"end_station_name",
                    "end_station_lon": "end_station_longitude",
                    "end_station_lat":"end_station_latitude"
                    }                   
                ]
        },
        "station_file": {
                 "keyword": "none"
                 }  
}

indego={"company": "indego",
            "city": "philly",
            "trip_file":{
                "keyword": "trip",
                "version":[
                    {
                    "start_time": "starttime",
                    "end_time": "stoptime",
                    "start_station_id": "start_station_id",
                    #"start_station_name":"start_station_name",
                    "start_station_lon": "start_station_longitude",
                    "start_station_lat":"start_station_latitude",
                    "end_station_id": "end_station_id",
                    #"end_station_name":"end_station_name",
                    "end_station_lon": "end_station_longitude",
                    "end_station_lat":"end_station_latitude"
                    },
                    {
                    "start_time": "start_time",
                    "end_time": "stop_Time",
                    "start_station_id": "start_station_id",
                    #"start_station_name":"start_station_name",
                    "start_station_lon": "start_station_longitude",
                    "start_station_lat":"start_station_latitude",
                    "end_station_id": "end_station_id",
                    #"end_station_name":"end_station_name",
                    "end_station_lon": "end_station_longitude",
                    "end_station_lat":"end_station_latitude"
                    }                   
                ]
        },
        "station_file": {
                 "keyword": "none"
                 }  
}

bikeshare=json.dumps([citibike])


#bikeshare=json.dumps([bluebike, citibike, cogo, capital, divvy, lyft])
                





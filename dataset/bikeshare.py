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
	                "start_station_name":"Start_station_name",
	                "end_station_id": "End_station_number",
	                "end_station_name":"End_station_name",
	                "end_station_lon": "End_station_longitude",
	                "end_station_lat":"End_station_latitude",	                
	                "start_station_lon": "Start_station_longitude",
	                "start_station_lat":"Start_station_latitude"
            	},{
	                "start_time":"starttime",
	                "end_time": "stoptime",
	                "start_station_id": "start_station_id",
	                "start_station_name":"start_station_name",
	                "start_station_lon": "start_station_longitude",
	                "start_station_lat":"start_station_latitude",
	                "end_station_id": "end_station_id",
	                "end_station_name":"end_station_name",
	                "end_station_lon": "end_station_longitude",
	                "end_station_lat":"end_station_latitude"
            	},
            	]
            },
            "station_file": {
                "keyword": "station",
                "version":[{
	                "id": "Number",
	                "name": "Name",
	                "lon":"Longitude",
	                "lat":"Latitude"                 	
	                },{
		            "id": "Station_ID",
		            "name": "Station",
		            "lon":"Longitude",
		            "lat":"Latitude"                        
	            }
              ]

            }
}
bikeshare=json.dumps([bluebike])


citibike={"company": "citibike",
          #  "state": "NY",
            "city": "NYC",
            "trip_file":{
                "keyword": "trip",
            	"version":[
            	    "start_time": "starttime",
                	"end_time": "stoptime",
                	"start_station_id": "start_station_id",
                	"start_station_name":"start_station_name",
                	"start_station_lon": "start_station_longitude",
                	"start_station_lat":"start_station_latitude",
                	"end_station_id": "end_station_id",
                	"end_station_name":"end_station_name",
                	"end_station_lon": "end_station_longitude",
                	"end_station_lat":"end_station_latitude"
            	]
		},
		"station_file": "None"  
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
                    "start_station_name":"from_station_name",
                    "end_station_id": "to_station_id",
                    "end_station_name":"to_station_name"
                }
                ]
            },
            "station_file": {
                "keyword": "station",
                "version":[{
                    "id": "id",
                    "name": "Name",
                    "lon":"longitude",
                    "lat":"latitude"                    
                    }
              ]

            }
}
start_time  end_time    start_station_id    start_station_name  start_station_latitude  start_station_longitude end_station_id  end_station_name    end_station_latitude    end_station_longitude

lyft={
    "company": "lyft",
            "trip_file":{
                "keyword": "trip",
                "version":[{
                    "start_time":"start_time",
                    "end_time": "end_time",
                    "start_station_id": "start_station_id",
                    "start_station_name":"start_station_name",
                    "end_station_id": "start_station_id",
                    "end_station_name":"start_station_name",
                    "end_station_lon": "end_station_longitude",
                    "end_station_lat":"end_station_latitude",
                    "start_station_lon": "start_station_longitude",
                    "start_station_lat":"start_station_latitude"                                        
                }
                ]
            },


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
                    "start_station_name":"from_station_location",
                    "end_station_id": "to_station_id",
                    "end_station_name":"to_station_location"
                }]
            },
            "station_file": {
                "keyword": "station",
                "version":[{
                    "id": "Number",
                    "name": "Name",
                    "lon":"Longitude",
                    "lat":"Latitude"                    
                    },{
                    "id": "Station_ID",
                    "name": "Station",
                    "lon":"Longitude",
                    "lat":"Latitude"                        
                }
              ]

            }
}


capital={"company": "capital",
            "city": "DC",
            "trip_file":{
                "keyword": "trip",
                "start_time":"Start_Date",
                "end_time": "End_Date",
                "start_station_id": "Start_station_number",
                "start_station_name":"Start_station",
                "end_station_id": "End_station_number",
                "end_station_name":"End_station",
            },
         	"station_file": "None"  
}




bikeshare=json.dumps([bluebike, citibike])
                


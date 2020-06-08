import json
citibike={"company": "citibike",
            "state": "NY",
            "city": "NYC",
            "trip_file":{
                "keyword": "trip",
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
		},
		"station_file": "None"  
}

bluebike={"company": "bluebike",
            "state": "MA",
            "city": "Boston",
            "trip_file":{
                "keyword": "trip",
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
            "station_file": {
                "keyword": "station",
                "file":[{
                        "file_name": "current_bluebikes_stations.csv", 
                        "header": "1",
                        "id": "Number",
                        "name": "Name",
                        "lon":"Longitude",
                        "lat":"Latitude"
                        },
                        {"file_name": "Hubway_Stations_as_of_July_2017.csv", 
                        "header": "0",
                        "id": "Number",
                        "name": "Name",
                        "lon":"Longitude",
                        "lat":"Latitude"
                        },
                        {"file_name": "Hubway_Stations_2011_2016.csv", 
                        "header": "0",
                        "id": "Station ID",
                        "name": "Station",
                        "lon":"Longitude",
                        "lat":"Latitude"                        
                        }
                    ]
            }


}

bikeshare=json.dumps([bluebike, citibike])
                

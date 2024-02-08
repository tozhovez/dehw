
def insert_from_csv_telemetry(tb_name, file_name):
    #vehicleID,timestamp,speed,location_coordinates,miles
    line = f"\copy \"{tb_name}\"(\"vehicle_id\", \"timestamp\", \"speed\", \"location_coordinates\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_drivers(tb_name, file_name):

    #id,license_number,age,company_id
    line = f"\copy \"{tb_name}\"(\"id\", \"license_number\", \"age\", \"company_id\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_vehicles(tb_name, file_name):

    #vehicle_id,type,model,year
    line = f"\copy \"{tb_name}\"(\"vehicle_id\", \"type\", \"model\", \"year\") FROM '{file_name}' delimiter ',' csv header"
    print(line)
    return line


def insert_from_csv_claims(tb_name, file_name):

    #vehicle_id,location_coordinates,cost,damage_type,timestamp
    line = f"\copy \"{tb_name}\"(\"vehicle_id\", \"location_coordinates\", \"cost\", \"damage_type\", \"timestamp\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_policy_quotes(tb_name, file_name):

    #policy_quote_id,vehicle_id,price_per_mile,price_per_hour
    line = f"\copy \"{tb_name}\"(\"policy_quote_id\", \"vehicle_id\", \"price_per_mile\", \"price_per_hour\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_assignments(tb_name, file_name):
    #driver_id,vehicle_id,start_datetime,end_datetime
    line = f"\copy \"{tb_name}\"(\"driver_id\", \"vehicle_id\", \"start_time\", \"end_time\") FROM '{file_name}' delimiter ',' csv header"
    return line

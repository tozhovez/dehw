import os
import subprocess
import pathlib

data_storage = pathlib.Path(__file__).parent / "data_storage"

def insert_from_csv_telemetry(name):
    tb_name = name
    file_name = f"{data_storage}/{tb_name}.csv"
    #vehicleID,timestamp,speed,location_coordinates,miles
    line = f"\copy \"{tb_name}\"(\"vehicle_id\", \"timestamp\", \"speed\", \"location_coordinates\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_drivers(name):
    tb_name = name
    file_name = f"{data_storage}/{tb_name}.csv"
    #id,license_number,age,company_id
    line = f"\copy \"{tb_name}\"(\"id\", \"license_number\", \"age\", \"company_id\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_vehicles(name):
    tb_name = name
    file_name = f"{data_storage}/{tb_name}.csv"
    #vehicle_id,type,model,year
    line = f"\copy \"{tb_name}\"(\"vehicle_id\", \"type\", \"model\", \"year\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_claims(name):
    tb_name = name
    file_name = f"{data_storage}/{tb_name}.csv"
    #vehicle_id,location_coordinates,cost,damage_type,timestamp
    line = f"\copy \"{tb_name}\"(\"vehicle_id\", \"location_coordinates\", \"cost\", \"damage_type\", \"timestamp\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_policy_quotes(name):
    tb_name = name
    file_name = f"{data_storage}/{tb_name}.csv"
    #policy_quote_id,vehicle_id,price_per_mile,price_per_hour
    line = f"\copy \"{tb_name}\"(\"policy_quote_id\", \"vehicle_id\", \"price_per_mile\", \"price_per_hour\") FROM '{file_name}' delimiter ',' csv header"
    return line


def insert_from_csv_assignments(name):
    tb_name = name
    file_name = f"{data_storage}/{tb_name}.csv"
    #driver_id,vehicle_id,start_datetime,end_datetime
    line = f"\copy \"{tb_name}\"(\"driver_id\", \"vehicle_id\", \"start_time\", \"end_time\") FROM '{file_name}' delimiter ',' csv header"
    return line




pg_url = str(f"postgres://docker:docker@localhost:6432/transportation")

subprocess.run([
    "psql", pg_url, "-X", "--quiet", "-c", insert_from_csv_drivers("drivers")
    ])
subprocess.run([
    "psql", pg_url, "-X", "--quiet", "-c", insert_from_csv_vehicles("vehicles")
    ])
subprocess.run([
    "psql", pg_url, "-X",
    "--quiet", "-c",
    insert_from_csv_assignments("assignments")
    ])
subprocess.run([
    "psql", pg_url, "-X", "--quiet", "-c",
    insert_from_csv_telemetry("telemetry")
    ])
subprocess.run([
    "psql", pg_url, "-X", "--quiet", "-c", insert_from_csv_claims("claims")
    ])
subprocess.run([
    "psql", pg_url, "-X", "--quiet", "-c",
    insert_from_csv_policy_quotes("policy_quotes")
    ])

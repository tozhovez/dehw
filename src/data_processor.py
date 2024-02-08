import csv
import re
from datetime import datetime
import pathlib
import os
import subprocess
from src.build_insert_data import(
    insert_from_csv_assignments,
    insert_from_csv_drivers,
    insert_from_csv_claims,
    insert_from_csv_telemetry,
    insert_from_csv_vehicles,
    insert_from_csv_policy_quotes
    )
redydata_storage = pathlib.Path(__file__).parent.parent / "redydata_storage"
pathlib.Path(redydata_storage).mkdir(mode=0o777, parents=False, exist_ok=True)
pg_url = str(f"postgres://docker:docker@localhost:6432/transportation")

#Exception
class DataErrorsException(Exception):
    """Errors Input data """
    pass


class DataFileErrorsException(Exception):
    """Errors data file """
    pass


# Define a function for date parsing
def parse_date(date_str):
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
        try:
            return datetime.strptime(date_str, fmt)
        except ValueError:
            continue
    raise ValueError("no valid date format found")


def validate_year(year_str):
    """Validate the year to be within a realistic range"""
    current_year = datetime.now().year
    try:
        year = int(year_str)
        return 1900 <= year <= current_year
    except ValueError:
        return False


def validate_and_clean_drivers(file_path):

    # Initialize lists to store valid and cleaned data
    valid_cleaned_drivers = []

    # Define regular expressions for validating license number format
    license_number_regex = re.compile(r'^[\w-]+$')

    # Define a function to validate each driver's data row
    def validate_and_clean_driver(row):
        id, license_number, age, company_id = row

        # Strip unwanted whitespaces
        id = id.strip()
        license_number = license_number.strip()
        age = age.strip()
        company_id = company_id.strip()

        # Validate 'license_number' for certain format
        #(Assuming alphanumeric with dashes)
        if not license_number_regex.match(license_number):
            return None  # Skip rows with invalid 'license_number'

        # Validate 'age' for integer and within
        # a reasonable range (e.g., 18 to 100)
        if not age.isdigit() or not 18 <= int(age) <= 100:
            return None  # Skip rows with invalid or unreasonable 'age'

        # Cleaning: License number upper case (making a standard practice)
        license_number = license_number.upper()

        return [id, license_number, int(age), company_id]

    # Read the CSV file and perform validation and cleaning
    with open(file_path, mode='r') as csvfile:
        csvreader = csv.reader(csvfile)
        header = next(csvreader)  # Skip header

        # Process each row
        for row in csvreader:
            cleaned_driver = validate_and_clean_driver(row)
            if cleaned_driver:
                valid_cleaned_drivers.append(cleaned_driver)

    # Remove duplicates (based on 'license_number')
    unique_drivers = {}
    for row in valid_cleaned_drivers:
        if row[1] not in unique_drivers:
            unique_drivers[row[1]] = row

    # Write the clean and validated data to a new CSV file
    file_name = redydata_storage.joinpath('drivers.csv')
    with open(file_name, mode='w', newline='') as new_csvfile:
        csvwriter = csv.writer(new_csvfile)
        csvwriter.writerow(header)  # Write the original header
        for driver_data in unique_drivers.values():
            csvwriter.writerow(driver_data)
    subprocess.run([
        "psql", pg_url, "-X", "--quiet", "-c",
        insert_from_csv_drivers(tb_name="drivers", file_name=file_name)
        ])
    return file_name.name


def validate_and_clean_telemetry(file_path):

    # Initialize a list to store valid and cleaned data
    valid_cleaned_telemetry = []

    # Define regular expressions for validating location coordinates format
    coordinates_regex = re.compile(r'^\([-+]?([1-8]?\d(\.\d+)?|90(\.0+)?), \s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)\)$')

    # Function to validate and clean a single row of telemetry data
    def validate_telemetry(row):
        vehicle_id, timestamp, speed, location_coordinates = row

        # Strip white spaces
        vehicle_id = vehicle_id.strip()
        timestamp = timestamp.strip()
        speed = speed.strip()
        location_coordinates = location_coordinates.strip()

        # Validate 'timestamp'
        try:
            timestamp = datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            return None

        # Validate 'speed' to be a numeric value within a reasonable range
        try:
            speed = float(speed)
            if not 0 <= speed <= 300:  # Assuming a reasonable speed range 0-300
                return None
        except ValueError:
            return None

        # Validate 'location_coordinates' format
        if not re.match(coordinates_regex, location_coordinates):
            return None
        return [vehicle_id, timestamp, speed, location_coordinates]

    # Read the CSV file, validating and cleaning data
    with open(file_path, mode='r') as csvfile:
        csvreader = csv.reader(csvfile)
        header = next(csvreader)  # Skip header

        for row in csvreader:
            #cleaned_row = validate_telemetry(row)
            cleaned_row = row
            if cleaned_row:
                valid_cleaned_telemetry.append(cleaned_row)

    # # Remove duplicates (based on 'vehicle_id' and 'timestamp')
    # unique_telemetry = {}
    # for row in valid_cleaned_telemetry:
    #     unique_key = (row[0], row[1])  # vehicle_id and timestamp as unique key
    #     if unique_key not in unique_telemetry:
    #         unique_telemetry[unique_key] = row
    file_name = redydata_storage.joinpath('telemetry.csv')
    # Write the clean and validated data to a new CSV file
    with open(file_name, mode='w', newline='') as new_csvfile:
        csvwriter = csv.writer(new_csvfile)
        csvwriter.writerow(header)  # Write the original header
        for row in valid_cleaned_telemetry:
            # Format timestamp for writing
            #row[1] = row[1].strftime("%Y-%m-%d %H:%M:%S")
            csvwriter.writerow(row)
    subprocess.run([
        "psql", pg_url, "-X", "--quiet", "-c",
        insert_from_csv_telemetry(tb_name="telemetry", file_name=file_name)
        ])
    return file_name.name

def validate_and_clean_vehicles(file_path):

    def clean_type_or_model(value):
        """Basic cleaning for type/model strings"""
        return value.strip().upper()

    valid_cleaned_vehicles = []

    with open(file_path, mode='r', encoding='utf-8') as csvfile:
        csvreader = csv.reader(csvfile)
        header = next(csvreader)  # Skip header

        for row in csvreader:
            vehicle_id, ttype, model, year = row
            # Strip whitespaces
            vehicle_id = vehicle_id.strip()

            # Cleaning type and model: trim and upper
            ttype = clean_type_or_model(ttype)
            model = clean_type_or_model(model)

            # Validate 'year'
            if not validate_year(year):
                continue  # Skip row if 'year' is not valid

            valid_cleaned_vehicles.append([
                vehicle_id, ttype, model, int(year)
                ])
    file_name = redydata_storage.joinpath('vehicles.csv')
    print(file_name)
    # Write cleaned data to a new CSV
    with open(file_name, mode='w', newline='', encoding='utf-8') as new_csvfile:
        csvwriter = csv.writer(new_csvfile)
        csvwriter.writerow(header)  # Write the original header
        for row in valid_cleaned_vehicles:
            csvwriter.writerow(row)

    subprocess.run([
        "psql", pg_url, "-X", "--quiet", "-c",
        insert_from_csv_vehicles(tb_name="vehicles", file_name=file_name)
    ])
    return file_name.name


def validate_and_clean_claims(file_path):
    # Define a regular expression for validating location coordinates
    coordinates_regex = re.compile(r'^\([-+]?([1-8]?\d(\.\d+)?|90(\.0+)?), \s*[-+]?(180(\.0+)?|((1[0-7]\d)|(\d\d?))(\.\d+)?)\)$')

    def validate_coordinate(coord):
        """Validate the format of GPS coordinates."""
        return bool(re.match(coordinates_regex, coord))

    def clean_damage_type(damage_type):
        """Capitalizes and trims damage type string."""
        return damage_type.strip().upper()

    def validate_cost(cost_str):
        """Validate and parse cost to a proper format."""
        try:
            cost = float(cost_str)
            return cost >= 0  # Making sure the cost isn't negative.
        except ValueError:
            return False

    valid_cleaned_claims = []

    with open(file_path, mode='r', encoding='utf-8') as csvfile:
        csvreader = csv.reader(csvfile)
        header = next(csvreader)  # Skip header

        for row in csvreader:
            vehicle_id, location_coordinates, timestamp, damage_type, cost = row

            # Validate location
            if not validate_coordinate(location_coordinates):
                continue  # Skip row if location coordinate is not valid

            # Validate timestamp
            timestamp = parse_date(timestamp)
            if not timestamp:
                continue  # Skip row if timestamp is not valid

            # Clean damage_type
            damage_type = clean_damage_type(damage_type)

            # Validate cost
            if not validate_cost(cost):
                continue  # Skip invalid cost

            valid_cleaned_claims.append([
                vehicle_id, location_coordinates, timestamp,
                damage_type, float(cost)
                ])
    file_name = redydata_storage.joinpath('claims.csv')
    # Write cleaned data to a new CSV
    with open(file_name, mode='w', newline='', encoding='utf-8') as new_csvfile:
        csvwriter = csv.writer(new_csvfile)
        csvwriter.writerow(header)  # Write the original header
        for row in valid_cleaned_claims:
            # Formatting timestamp back to string
            row[2] = row[2].strftime("%Y-%m-%d %H:%M:%S")
            csvwriter.writerow(row)
    subprocess.run([
        "psql", pg_url, "-X", "--quiet", "-c",
        insert_from_csv_claims(tb_name="claims", file_name=file_name)
    ])
    return file_name.name


def validate_and_clean_assignments(file_path):

    # Initialize lists to store valid and cleaned data
    valid_cleaned_rows = []
    # Define a function to validate each row
    def validate_and_clean_row(row):
        driver_id, vehicle_id, start_time, end_time = row

        # Remove any leading/trailing white spaces in IDs and times
        driver_id = driver_id.strip()
        vehicle_id = vehicle_id.strip()
        start_time = start_time.strip()
        end_time = end_time.strip() if end_time else None  # Handle missing end_time

        # Validate IDs are integers
        if not driver_id.isdigit() or not vehicle_id.isdigit():
            return None  # Skip rows with invalid IDs

        # Parse start and end times
        try:
            start_time = parse_date(start_time)
            if end_time:
                end_time = parse_date(end_time)
                if start_time > end_time:  # Start time must be before end time
                    return None
            else:
                end_time = 'Ongoing'  # For missing or Ongoing assignments
        except ValueError:
            return None  # Skip rows with invalid dates

        return [driver_id, vehicle_id, start_time, end_time]

    # Read the CSV file and perform validation and cleaning
    with open(file_path, mode='r') as csvfile:
        csvreader = csv.reader(csvfile)
        header = next(csvreader)  # Skip header

        # Process each row
        for row in csvreader:
            cleaned_row = validate_and_clean_row(row)
            if cleaned_row:
                valid_cleaned_rows.append(cleaned_row)
    # Remove duplicates (based on driver_id, vehicle_id, start_time)
    unique_rows = []
    seen = set()
    for row in valid_cleaned_rows:
        identifier = (row[0], row[1], row[2])  # Create a unique identifier tuple
        if identifier not in seen:
            unique_rows.append(row)
            seen.add(identifier)

    # Optionally, handle outliers or further clean up here...
    file_name = redydata_storage.joinpath('assignments.csv')
    # Write the clean and validated data to a new CSV file
    with open(file_name, mode='w', newline='') as new_csvfile:
        csvwriter = csv.writer(new_csvfile)
        csvwriter.writerow(header)  # Write the original header
        for row in unique_rows:
            # If assignment is 'Ongoing', write an empty string as end_time
            if row[3] == 'Ongoing':
                row[3] = ''
            csvwriter.writerow(row)
    subprocess.run([
        "psql", pg_url, "-X", "--quiet", "-c",
        insert_from_csv_assignments(tb_name="assignments", file_name=file_name)
    ])
    return file_name.name

def validate_and_clean_policy_quotes(file_path):
    def validate_and_parse_float(value_str, min_value=0):
        """Parse a string into a float and validate it's above a min_value."""
        try:
            value = float(value_str)
            if value >= min_value:
                return value
        except ValueError:
            pass
        return None

    valid_cleaned_policy_quotes = []

    with open(file_path, mode='r', encoding='utf-8') as csvfile:
        csvreader = csv.reader(csvfile)
        header = next(csvreader)  # Skip header

        for row in csvreader:
            policy_quote_id, vehicle_id, price_per_mile, price_per_hour = row

            # Strip whitespaces and validate 'policy_quote_id' and 'vehicle_id' for integer
            vehicle_id = vehicle_id.strip()

            # Validate and clean prices
            price_per_mile = validate_and_parse_float(price_per_mile.strip())
            price_per_hour = validate_and_parse_float(price_per_hour.strip())
            if price_per_mile is None or price_per_hour is None:
                continue  # Skip row if prices are not valid

            valid_cleaned_policy_quotes.append([
                policy_quote_id, vehicle_id, price_per_mile, price_per_hour
                ])
    file_name = redydata_storage.joinpath('policy_quotes.csv')
    # Write cleaned data to a new CSV
    with open(file_name, mode='w', newline='', encoding='utf-8') as new_csvfile:
        csvwriter = csv.writer(new_csvfile)
        csvwriter.writerow(header)  # Write the original header
        for row in valid_cleaned_policy_quotes:
            csvwriter.writerow(row)

    subprocess.run([
        "psql", pg_url, "-X", "--quiet", "-c",
        insert_from_csv_policy_quotes(
            tb_name="policy_quotes", file_name=file_name
            )
    ])
    return file_name.name


def validate_and_clean(file_path):
    try:
        if  file_path.match("drivers.csv") == True:
            return validate_and_clean_drivers(file_path)
        elif file_path.match("telemetry.csv") == True:
            return validate_and_clean_telemetry(file_path)
        elif file_path.match("vehicles.csv") == True:
            return validate_and_clean_vehicles(file_path)
        elif file_path.match("claims.csv") == True:
            return validate_and_clean_claims(file_path)
        elif file_path.match("assignments.csv") == True:
            return validate_and_clean_assignments(file_path)
        elif file_path.match("policy_quotes.csv") == True:
            return validate_and_clean_policy_quotes(file_path)
        else:
            raise DataFileErrorsException(f"error filename not exists in {file_path}")
    except Exception as e:
        print(f"Error processing file {file_path}: {str(e)}")
        return None
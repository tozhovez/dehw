import pandas as pd
from datetime import datetime, timedelta
from geopy.distance import geodesic
import numpy as np
import pathlib

data_storage = pathlib.Path(__file__).parent / "data_storage"
pathlib.Path(data_storage).mkdir(mode=0o777, parents=False, exist_ok=True)

# Create a sample DataFrame for the assignments table
data = {
    'driver_id': [ i % 3 + 1 for i in range(200)],
    'vehicle_id': [ i % 5 + 1 for i in range(200)],
    'start_time': [
        datetime(2023, 2, 1, 7, i%2) + timedelta(days=i) for i in range(200)
        ],
    'end_time': [
        datetime(2023, 2, 2, 19, 0) + timedelta(days=i) for i in range(200)
        ],
}
df = pd.DataFrame(data)
df.to_csv(f"{data_storage}/assignments.csv", index=False)
print(df)

# Define sample telemetry data
data = {
    'vehicle_id': [ i % 5 + 1 for i in range(4000)],
    'timestamp': [
        datetime(2023, 2, 1, 19, 23) + timedelta(minutes=i) for i in range(4000)
        ],
    'speed': [5 * (i % 50) for i in range(4000)],
    'location_coordinates': [
        (f'{50.0502+i%31}', f'{-40.2437-i%31}') for i in range(4000)
        ]  # Initial coordinates
}

# Create DataFrame2
telemetry_df = pd.DataFrame(data)

# Convert timestamp to datetime
telemetry_df['timestamp'] = pd.to_datetime(telemetry_df['timestamp'])

# Sort by vehicleID and timestamp to ensure sequential calculations
telemetry_df.sort_values(by=['vehicle_id', 'timestamp'], inplace=True)

# Calculate the distance traveled between successive points for the same vehicle
def calculate_distance(row, prev_row):
    if row['vehicle_id'] == prev_row['vehicle_id']:
        return geodesic(
            row['location_coordinates'], prev_row['location_coordinates']
            ).miles
    return 0

#telemetry_df['miles'] = [calculate_distance(
# row, telemetry_df.iloc[i - 1]) if i > 0 else 0 for i,
# row in telemetry_df.iterrows()]
# Assuming speed is in miles per hour and intervals are of 1 hour,
# this is a fallback
# Calculate the miles based on speed and time interval
# (optional, simplified and less accurate)
# df['miles_based_on_speed'] = df.speed *
#(df.timestamp.diff().dt.total_seconds().div(3600)).fillna(0)
# Save the final table to CSV
telemetry_df.to_csv(f"{data_storage}/telemetry.csv", index=False)
print(telemetry_df)


# Sample data for the Drivers table
data = {
    'id': [ i % 5 + 1 for i in range(4)],  # Generating unique IDs for drivers
    'license_number': [ f"AFR{i}" for i in range(4)],
    'age': [ 25 + i for i in range(4)],
    'company_id': [ 101 + i for i in range(4)]
}

# Creating DataFrame
drivers_df = pd.DataFrame(data)

drivers_df.to_csv(f"{data_storage}/drivers.csv", index=False)
print(drivers_df)

# Sample data for the Vehicles table
data = {
    'vehicles_id': [1,2,3,4,5, 6,7,8,9,10],
    'type': ['Sedan', 'SUV', 'Truck', 'Sedan', 'Coupe', 'Sedan', 'SUV', 'Truck', 'Sedan', 'Coupe'],
    'model': ['Model A', 'Model B', 'Model C', 'Model D', 'Model E', 'Model A', 'Model B', 'Model C', 'Model D', 'Model E'],
    'year': [2010, 2015, 2020, 2020, 2018, 2010, 2015, 2020, 2020, 2018]
}

# Creating DataFrame
vehicles_df = pd.DataFrame(data)
vehicles_df.to_csv(f"{data_storage}/vehicles.csv", index=False)
print("Original Vehicles DataFrame:")
print(vehicles_df)

# Sample data for the Claims table
claims_data = {
    'vehicle_id': [ i % 5 + 1 for i in range(100)],
    'location_coordinates': [
        (f'{50.0502+i%20}', f'{-40.2437-i%20}') for i in range(100)
        ],  # Initial coordinates
    'cost': [ i%5 * 100 + 1 for i in range(100)],
    'damage_type': [ f"{i%5}A00" for i in range(100)],
    'timestamp': [
        datetime(2023, 2, 1, 1, i%2)+ timedelta(days=i) for i in range(100)
        ]
}

# Creating DataFrame
claims_df = pd.DataFrame(claims_data)

claims_df.to_csv(f"{data_storage}/claims.csv", index=False)
print("Claims DataFrame with High Cost Flag:")
print(claims_df)


# Sample data for the Policy Quotes table
policy_data = {
    'policy_quote_id': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
    'vehicle_id': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'price_per_mile': [1.21, 1.15, 1.52, 1.14, 1.81, 1.21, 1.15, 1.52, 1.14, 1.81],
    'price_per_hour': [0.2, 9.2, 4.2, 6.2, 4.2, 1.21, 1.15, 1.52, 1.14, 1.81]
}

# Creating DataFrame
policy_df = pd.DataFrame(policy_data)

policy_df.to_csv(f"{data_storage}/policy_quotes.csv", index=False)
print("Policy Quotes DataFrame with Sample Total Cost:")
print(policy_df)
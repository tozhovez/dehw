--Report the monthly level of use (miles per driver/vehicle)

WITH MileageCalculations AS (
    SELECT
        vehicle_id,
        timestamp,
        EXTRACT(month FROM timestamp) AS month,
        EXTRACT(year FROM timestamp) AS year,
        speed * (EXTRACT(EPOCH FROM (LEAD(timestamp) OVER (PARTITION BY vehicle_id ORDER BY timestamp) - timestamp))/3600) AS distance
    FROM telemetry
)
SELECT
    vehicle_id,
    month,
    year,
    SUM(distance) AS total_miles -- Now you can aggregate directly since distance is pre-calculated
FROM MileageCalculations
WHERE distance IS NOT NULL -- Ensure to exclude NULL distances which result from the LEAD function at the last row of each partition
GROUP BY vehicle_id, month, year
ORDER BY vehicle_id, year, month;

WITH DriverMileage AS (
    SELECT
        ass.driver_id,
        EXTRACT(month FROM ass.start_time) AS month,
        EXTRACT(year FROM ass.start_time) AS year,
        tel.vehicle_id,
        ass.start_time,
        ass.end_time,
        -- Calculate distance traveled in each telemetry record assuming each record is for one hour.
        speed * (EXTRACT(EPOCH FROM (LEAD(tel.timestamp) OVER (PARTITION BY tel.vehicle_id ORDER BY tel.timestamp)- tel.timestamp))/3600) AS distance
    FROM
        assignments ass
        JOIN telemetry tel ON ass.vehicle_id = tel.vehicle_id
        AND tel.timestamp BETWEEN ass.start_time AND ass.end_time
)
SELECT
    driver_id, --vehicle_id,
    month,
    year,
    SUM(distance) AS total_miles_for_driver
FROM
    DriverMileage
WHERE
    distance IS NOT NULL -- Excluding records where LEAD function results in NULL
GROUP BY
    driver_id, --vehicle_id,
    month,
    year
ORDER BY
    driver_id, --vehicle_id,
    year,
    month;
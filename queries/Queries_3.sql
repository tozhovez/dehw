--Claims cost per month / per mile
WITH ordered_telemetry AS (
    SELECT
        vehicle_id,
        timestamp,
        speed,
        LEAD(timestamp) OVER (PARTITION BY vehicle_id ORDER BY timestamp) AS next_timestamp
    FROM
        telemetry
),
time_intervals AS (
    SELECT
        vehicle_id,
        timestamp,
        next_timestamp,
        speed,
        -- Calculating the time interval in hours between this timestamp and the next
        EXTRACT(EPOCH FROM (next_timestamp - timestamp)) / 3600 AS time_hours
    FROM
        ordered_telemetry
    WHERE
        next_timestamp IS NOT NULL
),
distance_per_vehicle_per_month AS (
    SELECT
        vehicle_id,
        DATE_TRUNC('month', timestamp) AS month,
        SUM(speed * time_hours) AS total_distance_miles
    FROM
        time_intervals
    GROUP BY vehicle_id, DATE_TRUNC('month', timestamp)
),
claims_cost_per_vehicle_per_month AS (
    SELECT
        vehicle_id,
        DATE_TRUNC('month', timestamp) AS month,
        SUM(cost) AS total_claims_cost
    FROM
        claims
    GROUP BY vehicle_id, DATE_TRUNC('month', timestamp)
),
claims_cost_per_mile AS (
    SELECT
        d.vehicle_id,
        d.month,
        d.total_distance_miles,
        c.total_claims_cost,
        (c.total_claims_cost / NULLIF(d.total_distance_miles, 0)) AS claims_cost_per_mile
    FROM
        distance_per_vehicle_per_month d
    JOIN
        claims_cost_per_vehicle_per_month c ON d.vehicle_id = c.vehicle_id AND d.month = c.month
)
SELECT * FROM claims_cost_per_mile ORDER BY vehicle_id, month;
-- Connect the assignment to a policy quote (price per vehicle type, miles/duration drove)
WITH telemetrymiles AS (
    SELECT
        vehicle_id,
        "timestamp",
        LEAD("timestamp") OVER (PARTITION BY vehicle_id ORDER BY "timestamp") AS next_timestamp,
        EXTRACT(epoch FROM LEAD("timestamp") OVER (PARTITION BY vehicle_id ORDER BY "timestamp") - "timestamp") / 3600 AS intervals,
        "speed" * EXTRACT(epoch FROM LEAD("timestamp") OVER (PARTITION BY vehicle_id ORDER BY "timestamp") - "timestamp") / 3600 AS miles,
        "speed",
        "location_coordinates"
    FROM
        "telemetry"
),
totalmiles AS (
    SELECT
        b."driver_id",
        b."start_time",
        b."end_time",
        a."vehicle_id",
        SUM(a.intervals) AS real_total_time,
        SUM(a.miles) AS total_miles
    FROM
        telemetrymiles a
    INNER JOIN
        assignments b ON a."vehicle_id" = b."vehicle_id"
    WHERE
        b."start_time" <= a."timestamp" AND a.next_timestamp <= b."end_time"
    GROUP BY
        b."driver_id", b."start_time", b."end_time", a."vehicle_id"
),
durations AS (
    SELECT
        a."driver_id",
        a."vehicle_id",
        a."start_time",
        a."end_time",
        a."end_time" - a."start_time" AS duration,
        EXTRACT(epoch FROM a."end_time" - a."start_time") / 3600 AS hours_duration,
        b."price_per_mile",
        b."price_per_hour",
        b."price_per_hour" * EXTRACT(epoch FROM a."end_time" - a."start_time") / 3600 AS assignment_price_by_hours
    FROM
        "assignments" a
    INNER JOIN
        "policy_quotes" b ON a."vehicle_id" = b."vehicle_id"
),
get_telemetry AS (
    SELECT
        aa."driver_id",
        aa."start_time",
        aa."end_time",
        aa."vehicle_id",
        aa.real_total_time,
        aa.total_miles,
        bb."price_per_mile",
        bb."price_per_hour",
        aa.total_miles * bb."price_per_mile" AS total_price_by_miles,
        aa.real_total_time * bb."price_per_hour" AS total_price_by_real_time
    FROM
        totalmiles aa
    INNER JOIN
        "policy_quotes" bb ON aa."vehicle_id" = bb."vehicle_id"
)
SELECT
    a."driver_id",
    a."vehicle_id",
    a."start_time",
    a."end_time",
    a.duration,
    a.hours_duration,
    a."price_per_hour",
    b."price_per_mile",
    b.real_total_time,
    b.total_miles,
    b.total_price_by_miles,
    b.total_price_by_real_time,
    a.assignment_price_by_hours
FROM
    durations a
INNER JOIN
    get_telemetry b ON a."driver_id" = b."driver_id" AND a."vehicle_id" = b."vehicle_id" AND a."start_time" = b."start_time" AND a."end_time" = b."end_time"
ORDER BY
    a."driver_id",  a."vehicle_id"

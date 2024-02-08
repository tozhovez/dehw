

DROP TABLE IF EXISTS "assignments";
DROP SEQUENCE IF EXISTS assignments_assignment_id_seq;
CREATE SEQUENCE assignments_assignment_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 START 230 CACHE 1;

CREATE TABLE "public"."assignments" (
    "assignment_id" integer DEFAULT nextval('assignments_assignment_id_seq') NOT NULL,
    "driver_id" integer NOT NULL,
    "vehicle_id" integer NOT NULL,
    "start_time" timestamp NOT NULL,
    "end_time" timestamp,
    CONSTRAINT "assignments_driver_id_vehicle_id_start_time" UNIQUE ("driver_id", "vehicle_id", "start_time"),
    CONSTRAINT "assignments_pkey" PRIMARY KEY ("assignment_id")
) WITH (oids = false);


DROP TABLE IF EXISTS "claims";
DROP SEQUENCE IF EXISTS claims_claim_id_seq;
CREATE SEQUENCE claims_claim_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 START 260 CACHE 1;

CREATE TABLE "public"."claims" (
    "claim_id" integer DEFAULT nextval('claims_claim_id_seq') NOT NULL,
    "vehicle_id" integer NOT NULL,
    "location_coordinates" character varying(255),
    "timestamp" timestamp,
    "damage_type" character varying(255) NOT NULL,
    "cost" numeric(10,2),
    CONSTRAINT "claims_pkey" PRIMARY KEY ("claim_id"),
    CONSTRAINT "claims_vehicle_id_location_coordinates_timestamp" UNIQUE ("vehicle_id", "location_coordinates", "timestamp")
) WITH (oids = false);


DROP TABLE IF EXISTS "drivers";
DROP SEQUENCE IF EXISTS drivers_id_seq;
CREATE SEQUENCE drivers_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."drivers" (
    "id" integer DEFAULT nextval('drivers_id_seq') NOT NULL,
    "license_number" character varying(255) NOT NULL,
    "age" integer,
    "company_id" integer,
    CONSTRAINT "drivers_license_number_key" UNIQUE ("license_number"),
    CONSTRAINT "drivers_pkey" PRIMARY KEY ("id")
) WITH (oids = false);


DROP TABLE IF EXISTS "policy_quotes";
DROP SEQUENCE IF EXISTS policy_quotes_policy_quote_id_seq;
CREATE SEQUENCE policy_quotes_policy_quote_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."policy_quotes" (
    "policy_quote_id" integer DEFAULT nextval('policy_quotes_policy_quote_id_seq') NOT NULL,
    "vehicle_id" integer NOT NULL,
    "price_per_mile" numeric(10,2),
    "price_per_hour" numeric(10,2),
    CONSTRAINT "policy_quotes_pkey" PRIMARY KEY ("policy_quote_id"),
    CONSTRAINT "policy_quotes_vehicle_id_price_per_mile_price_per_hour" UNIQUE ("vehicle_id", "price_per_mile", "price_per_hour")
) WITH (oids = false);


DROP TABLE IF EXISTS "telemetry";
DROP SEQUENCE IF EXISTS telemetry_telemetry_id_seq;
CREATE SEQUENCE telemetry_telemetry_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 START 288250 CACHE 1;

CREATE TABLE "public"."telemetry" (
    "telemetry_id" integer DEFAULT nextval('telemetry_telemetry_id_seq') NOT NULL,
    "vehicle_id" integer NOT NULL,
    "timestamp" timestamp NOT NULL,
    "speed" numeric(5,2),
    "location_coordinates" character varying(255),
    CONSTRAINT "telemetry_pkey" PRIMARY KEY ("telemetry_id"),
    CONSTRAINT "telemetry_vehicle_id_timestamp" UNIQUE ("vehicle_id", "timestamp")
) WITH (oids = false);


DROP TABLE IF EXISTS "vehicles";
DROP SEQUENCE IF EXISTS vehicles_vehicle_id_seq;
CREATE SEQUENCE vehicles_vehicle_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."vehicles" (
    "vehicle_id" integer DEFAULT nextval('vehicles_vehicle_id_seq') NOT NULL,
    "type" character varying(255),
    "model" character varying(255),
    "year" integer,
    CONSTRAINT "vehicles_pkey" PRIMARY KEY ("vehicle_id")
) WITH (oids = false);


ALTER TABLE ONLY "public"."assignments" ADD CONSTRAINT "assignments_driver_id_fkey" FOREIGN KEY (driver_id) REFERENCES drivers(id) NOT DEFERRABLE;
ALTER TABLE ONLY "public"."assignments" ADD CONSTRAINT "assignments_vehicle_id_fkey" FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) NOT DEFERRABLE;

ALTER TABLE ONLY "public"."claims" ADD CONSTRAINT "claims_vehicle_id_fkey" FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) NOT DEFERRABLE;

ALTER TABLE ONLY "public"."policy_quotes" ADD CONSTRAINT "policy_quotes_vehicle_id_fkey" FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE SET NULL NOT DEFERRABLE;

ALTER TABLE ONLY "public"."telemetry" ADD CONSTRAINT "telemetry_vehicle_id_fkey" FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) NOT DEFERRABLE;

CREATE MATERIALIZED VIEW driver_assignment_data AS
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
    a."driver_id",  a."vehicle_id";

CREATE MATERIALIZED VIEW claims_cost_per_mile_view AS
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
        CASE
            WHEN d.total_distance_miles > 0 THEN c.total_claims_cost / d.total_distance_miles
            ELSE NULL
        END AS claims_cost_per_mile
    FROM
        distance_per_vehicle_per_month d
    JOIN
        claims_cost_per_vehicle_per_month c ON d.vehicle_id = c.vehicle_id AND d.month = c.month
)
SELECT * FROM claims_cost_per_mile ORDER BY vehicle_id, month;

CREATE MATERIALIZED VIEW vehicle_monthly_mileage AS
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


CREATE MATERIALIZED VIEW driver_monthly_mileage AS
WITH DriverMileage AS (
    SELECT
        ass.driver_id,
        EXTRACT(month FROM ass.start_time) AS month,
        EXTRACT(year FROM ass.start_time) AS year,
        tel.vehicle_id,
        ass.start_time,
        ass.end_time,
        -- Calculate distance traveled in each telemetry record assuming
        -- each record accounts for the time until the next record.
        speed * (EXTRACT(EPOCH FROM (LEAD(tel.timestamp) OVER (PARTITION BY tel.vehicle_id ORDER BY tel.timestamp) - tel.timestamp)) / 3600) AS distance
    FROM
        assignments ass
        JOIN telemetry tel ON ass.vehicle_id = tel.vehicle_id
        AND tel.timestamp BETWEEN ass.start_time AND ass.end_time
)
SELECT
    driver_id,
    month,
    year,
    SUM(distance) AS total_miles_for_driver
FROM
    DriverMileage
WHERE
    distance IS NOT NULL -- Excluding records where LEAD function results in NULL
GROUP BY
    driver_id,
    month,
    year;
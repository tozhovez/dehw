

DROP TABLE IF EXISTS  assignments ;
DROP SEQUENCE IF EXISTS assignments_assignment_id_seq;
CREATE SEQUENCE assignments_assignment_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 START 230 CACHE 1;

CREATE TABLE   assignments  (
     assignment_id  integer DEFAULT nextval('assignments_assignment_id_seq') NOT NULL,
     driver_id  integer NOT NULL,
     vehicle_id  integer NOT NULL,
     start_time  timestamp NOT NULL,
     end_time  timestamp,
    CONSTRAINT  assignments_driver_id_vehicle_id_start_time  UNIQUE ( driver_id ,  vehicle_id ,  start_time ),
    CONSTRAINT  assignments_pkey  PRIMARY KEY ( assignment_id )
) WITH (oids = false);


DROP TABLE IF EXISTS  claims ;
DROP SEQUENCE IF EXISTS claims_claim_id_seq;
CREATE SEQUENCE claims_claim_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 START 260 CACHE 1;

CREATE TABLE   claims  (
     claim_id  integer DEFAULT nextval('claims_claim_id_seq') NOT NULL,
     vehicle_id  integer NOT NULL,
     location_coordinates  character varying(255),
     timestamp  timestamp,
     damage_type  character varying(255) NOT NULL,
     cost  numeric(10,2),
    CONSTRAINT  claims_pkey  PRIMARY KEY ( claim_id ),
    CONSTRAINT  claims_vehicle_id_location_coordinates_timestamp  UNIQUE ( vehicle_id ,  location_coordinates ,  timestamp )
) WITH (oids = false);


DROP TABLE IF EXISTS  drivers ;
DROP SEQUENCE IF EXISTS drivers_id_seq;
CREATE SEQUENCE drivers_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE   drivers  (
     id  integer DEFAULT nextval('drivers_id_seq') NOT NULL,
     license_number  character varying(255) NOT NULL,
     age  integer,
     company_id  integer,
    CONSTRAINT  drivers_license_number_key  UNIQUE ( license_number ),
    CONSTRAINT  drivers_pkey  PRIMARY KEY ( id )
) WITH (oids = false);


DROP TABLE IF EXISTS  policy_quotes ;
DROP SEQUENCE IF EXISTS policy_quotes_policy_quote_id_seq;
CREATE SEQUENCE policy_quotes_policy_quote_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE   policy_quotes  (
     policy_quote_id  integer DEFAULT nextval('policy_quotes_policy_quote_id_seq') NOT NULL,
     vehicle_id  integer NOT NULL,
     price_per_mile  numeric(10,2),
     price_per_hour  numeric(10,2),
    CONSTRAINT  policy_quotes_pkey  PRIMARY KEY ( policy_quote_id ),
    CONSTRAINT  policy_quotes_vehicle_id_price_per_mile_price_per_hour  UNIQUE ( vehicle_id ,  price_per_mile ,  price_per_hour )
) WITH (oids = false);


DROP TABLE IF EXISTS  telemetry ;
DROP SEQUENCE IF EXISTS telemetry_telemetry_id_seq;
CREATE SEQUENCE telemetry_telemetry_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 START 288250 CACHE 1;

CREATE TABLE   telemetry  (
     telemetry_id  integer DEFAULT nextval('telemetry_telemetry_id_seq') NOT NULL,
     vehicle_id  integer NOT NULL,
     timestamp  timestamp NOT NULL,
     speed  numeric(5,2),
     location_coordinates  character varying(255),
    CONSTRAINT  telemetry_pkey  PRIMARY KEY ( telemetry_id ),
    CONSTRAINT  telemetry_vehicle_id_timestamp  UNIQUE ( vehicle_id ,  timestamp )
) WITH (oids = false);


DROP TABLE IF EXISTS  vehicles ;
DROP SEQUENCE IF EXISTS vehicles_vehicle_id_seq;
CREATE SEQUENCE vehicles_vehicle_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE   vehicles  (
     vehicle_id  integer DEFAULT nextval('vehicles_vehicle_id_seq') NOT NULL,
     type  character varying(255),
     model  character varying(255),
     year  integer,
    CONSTRAINT  vehicles_pkey  PRIMARY KEY ( vehicle_id )
) WITH (oids = false);


ALTER TABLE ONLY   assignments  ADD CONSTRAINT  assignments_driver_id_fkey  FOREIGN KEY (driver_id) REFERENCES drivers(id) NOT DEFERRABLE;
ALTER TABLE ONLY   assignments  ADD CONSTRAINT  assignments_vehicle_id_fkey  FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) NOT DEFERRABLE;

ALTER TABLE ONLY   claims  ADD CONSTRAINT  claims_vehicle_id_fkey  FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) NOT DEFERRABLE;

ALTER TABLE ONLY   policy_quotes  ADD CONSTRAINT  policy_quotes_vehicle_id_fkey  FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE SET NULL NOT DEFERRABLE;

ALTER TABLE ONLY   telemetry  ADD CONSTRAINT  telemetry_vehicle_id_fkey  FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) NOT DEFERRABLE;
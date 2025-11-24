CREATE DATABASE IF NOT EXISTS earthquake_db;

USE earthquake_db;

CREATE TABLE IF NOT EXISTS networks (
    code VARCHAR(10) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS earthquakes (
    event_id VARCHAR(50) PRIMARY KEY,
    event_time DATETIME,
    latitude DOUBLE,
    longitude DOUBLE,
    depth_km DOUBLE,
    magnitude DOUBLE,
    mag_type VARCHAR(10),
    nst INT,
    gap DOUBLE,
    dmin DOUBLE,
    rms DOUBLE,
    net_code VARCHAR(10),
    updated_time DATETIME,
    place VARCHAR(255),
    event_type VARCHAR(50),
    location_source VARCHAR(20),
    mag_source VARCHAR(20),
    horizontal_error DOUBLE,
    depth_error DOUBLE,
    mag_error DOUBLE,
    mag_nst DOUBLE,
    status VARCHAR(20),
    CONSTRAINT fk_network
        FOREIGN KEY (net_code) REFERENCES networks(code)
);

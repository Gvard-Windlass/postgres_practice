CREATE DATABASE subway;

CREATE TABLE line (
    line_number SMALLINT PRIMARY KEY,
    line_name VARCHAR(100),
    wagons_in_trains SMALLINT
);

CREATE TABLE station (
    id INT PRIMARY KEY,
    station_name VARCHAR(100),
    line_number SMALLINT,
    opening_time TIME(0),
    closing_time TIME(0),
    commissioning_date DATE,

    FOREIGN KEY (line_number)
    REFERENCES line(line_number)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);

CREATE TABLE route (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    departure_station_id INT,
    arrival_station_id INT,
    commute_time DOUBLE PRECISION,

    FOREIGN KEY (departure_station_id)
    REFERENCES station(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (arrival_station_id)
    REFERENCES station(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE interchange (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    station_a_id INT,
    station_b_id INT,

    FOREIGN KEY (station_a_id)
    REFERENCES station(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (station_b_id)
    REFERENCES station(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE street (
    id INT PRIMARY KEY,
    street_name VARCHAR(100)
);

CREATE TABLE exit (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    street_id INT,
    station_id INT,
    building_number INT,

    FOREIGN KEY (street_id)
    REFERENCES street(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (station_id)
    REFERENCES station(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

ALTER TABLE line ADD COLUMN map_color CHAR(6);
ALTER TABLE line DROP COLUMN map_color;
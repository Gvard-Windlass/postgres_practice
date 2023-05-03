-- prep
INSERT INTO line (line_number, line_name, wagons_in_trains) VALUES
(9, 'Новая Линия', 7);

INSERT INTO station (id, station_name,  line_number,  opening_time,  closing_time,  commissioning_date) VALUES
(46, 'Новая Станция 1', 9, '07:00', '00:00', '2020.12.12'),
(47, 'Новая Станция 2', 9, '07:00', '00:00', '2020.12.12');

ALTER TABLE station
ADD exit_count INT DEFAULT 0;

CREATE TABLE station_log (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    station_id INT,
    station_name VARCHAR(100),
    line_number SMALLINT,
    opening_time TIME(0),
    closing_time TIME(0),
    commissioning_date DATE
);

-- BEFORE INSERT Проверяет значение времени проезда, сигнализирует ошибку если оно слишком маленькое
CREATE OR REPLACE FUNCTION check_path_time() RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.commute_time < 1 THEN
        RAISE 'Value of commute time is too low';
    END IF;
END;
$$;

CREATE TRIGGER check_path_time
BEFORE INSERT ON route FOR EACH ROW
EXECUTE FUNCTION check_path_time();

INSERT INTO route (departure_station_id, arrival_station_id, commute_time) VALUES
(46, 47, 0.5);

-- AFTER INSERT Увеличивает количество выходов у станции
CREATE OR REPLACE FUNCTION increase_exit_count() RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE station SET exit_count = exit_count+1 WHERE id = NEW.station_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER increase_exit_count
AFTER INSERT ON exit FOR EACH ROW
EXECUTE FUNCTION increase_exit_count();

SELECT id, exit_count FROM station WHERE id IN(46, 47) ORDER BY ID;
INSERT INTO exit (street_id, station_id, building_number) VALUES (36, 46, 100);
SELECT id, exit_count FROM station WHERE id IN(46, 47) ORDER BY ID;

-- AFTER UPDATE Изменяет информацию о числе выходов у соответствующих станций
CREATE OR REPLACE FUNCTION update_exit_count() RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE station SET exit_count = exit_count-1 WHERE id = OLD.station_id;
    UPDATE station SET exit_count = exit_count+1 WHERE id = NEW.station_id;
    RETURN OLD;
END;
$$;

CREATE TRIGGER update_exit_count
AFTER UPDATE ON exit FOR EACH ROW
EXECUTE FUNCTION update_exit_count();

UPDATE exit SET station_id = 47 WHERE station_id = 46;
SELECT id, exit_count FROM station WHERE id IN(46, 47) ORDER BY ID;

-- AFTER DELETE Уменьшает количество выходов у станции
CREATE OR REPLACE FUNCTION decrease_exit_count() RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE station SET exit_count = exit_count-1 WHERE id = OLD.station_id;
    RETURN OLD;
END;
$$;

CREATE TRIGGER decrease_exit_count
AFTER DELETE ON exit FOR EACH ROW
EXECUTE FUNCTION decrease_exit_count();

DELETE FROM exit WHERE station_id = 47;
SELECT id, exit_count FROM station WHERE id IN(46, 47) ORDER BY ID;

-- BEFORE UPDATE Логгирует информацию о станции при её изменении
CREATE OR REPLACE FUNCTION log_station_info() RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO station_log (station_id, station_name,  line_number,  opening_time,  closing_time,  commissioning_date) VALUES
    (OLD.id, OLD.station_name,  OLD.line_number,  OLD.opening_time,  OLD.closing_time,  OLD.commissioning_date);
    RETURN OLD;
END;
$$;

CREATE TRIGGER log_station_info
BEFORE UPDATE ON station FOR EACH ROW
EXECUTE FUNCTION log_station_info();

UPDATE station SET opening_time = '07:30:00' WHERE station_name = 'Новая Станция 1';
SELECT * FROM station_log;

-- BEFORE DELETE Удаляет все соответствующие станции при удалении линии
CREATE OR REPLACE FUNCTION clear_stations() RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM route WHERE departure_station_id 
    IN (SELECT id FROM station WHERE line_number = OLD.line_number);

    DELETE FROM route WHERE arrival_station_id
    IN (SELECT id FROM station WHERE line_number = OLD.line_number);

    DELETE FROM interchange WHERE station_a_id
    IN (SELECT id FROM station WHERE line_number = OLD.line_number);

    DELETE FROM interchange WHERE station_b_id
    IN (SELECT id FROM station WHERE line_number = OLD.line_number);

    DELETE FROM station WHERE line_number = OLD.line_number;
    RETURN OLD;
END;
$$;

CREATE TRIGGER clear_stations
BEFORE DELETE ON line FOR EACH ROW
EXECUTE FUNCTION clear_stations();

SELECT * FROM station WHERE line_number = 9;
DELETE FROM line WHERE line_number = 9;
SELECT * FROM station WHERE line_number = 9;

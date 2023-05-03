-- Вставка с пополнением справочников
CREATE OR REPLACE PROCEDURE insert_station(st_name VARCHAR(100), ln_name VARCHAR(100))
LANGUAGE plpgsql
AS $$
DECLARE 
    ln_num_new INT;
    st_id_new INT;
BEGIN
    IF EXISTS(SELECT * FROM line WHERE line_name=ln_name)
        THEN SELECT line_number INTO ln_num_new FROM line WHERE line_name=ln_name;
    ELSE BEGIN
        ln_num_new:=(SELECT COALESCE(MAX(line_number)+1,0) FROM line);
        INSERT INTO line(line_number, line_name) VALUES (ln_num_new, ln_name);
    END;
    END IF;
    
    st_id_new:=(SELECT COALESCE(MAX(id)+1,0) FROM station);
    INSERT INTO station (id, station_name, line_number)
    VALUES (st_id_new, st_name, ln_num_new);
END;
$$;

CALL insert_station('Новая Станция', 'Новая Линия');

-- Удаление с очисткой справочников
CREATE OR REPLACE PROCEDURE delete_station_clear_line(st_id_del INT)
LANGUAGE plpgsql
AS $$
DECLARE 
    ln_num_del INT;
BEGIN
    SELECT line_number INTO ln_num_del FROM station WHERE id=st_id_del;
    DELETE FROM station WHERE id=st_id_del;

    IF NOT EXISTS(SELECT * FROM station WHERE line_number=ln_num_del)
        THEN DELETE FROM line WHERE line_number=ln_num_del;
    END IF;
END;
$$;

CALL delete_station_clear_line(46);

-- Каскадное удаление
CREATE OR REPLACE PROCEDURE delete_station_cascade(st_id_del INT)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM route WHERE departure_station_id = st_id_del;
    DELETE FROM interchange WHERE station_a_id = st_id_del;
    DELETE FROM station WHERE id=st_id_del;
END;
$$;

CALL delete_station_cascade(39);

-- Вычисление и возврат значения агрегатной функции
CREATE OR REPLACE FUNCTION get_full_line_time(IN ln_num INT, OUT total_time INT)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT SUM(p.commute_time) INTO total_time FROM line l
    JOIN station s USING(line_number)
    JOIN route p
    ON(s.id=p.departure_station_id) 
    WHERE l.line_number = ln_num;
END;
$$;

SELECT get_full_line_time(1);

-- Формирование статистики во временной таблице
CREATE OR REPLACE FUNCTION get_lines_stat()
RETURNS TABLE (
    id_stat INT,
    line_num INT,
    count_st INT,
    count_tr INT,
    time_between_st_avg FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS lines_stat (
        id_stat INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        line_num INT,
        count_st INT,
        count_tr INT,
        time_between_st_avg FLOAT
    ) ON COMMIT DROP;

    INSERT INTO lines_stat (line_num, count_st, count_tr)
    SELECT line_number, COUNT(s.id) AS count_st, COUNT(t.id) AS count_tr FROM line l
    LEFT JOIN station s USING(line_number)
    LEFT JOIN interchange t ON s.id=t.station_a_id
    GROUP BY l.line_number ORDER BY l.line_number;

    WITH q AS
    (SELECT l.line_number, AVG(commute_time) AS a_time FROM line l
        JOIN station s USING(line_number)
        JOIN route p ON s.id=p.departure_station_id
        GROUP BY l.line_number
    )
    UPDATE lines_stat AS ls
    SET time_between_st_avg = q.a_time
    FROM q
    WHERE ls.line_num = q.line_number 
    AND ls.id_stat>0;

    RETURN QUERY SELECT * FROM lines_stat ORDER BY line_num ASC;
END;
$$;

SELECT * FROM get_lines_stat();

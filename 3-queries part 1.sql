-- а. станции, в названии которых есть слово «площадь», но оно на него не заканчивается
SELECT * FROM station WHERE station_name ILIKE "%площадь%_";

-- б. линии без станций (в проекте)
SELECT line.* FROM line LEFT JOIN station USING(line_number) WHERE station.line_number IS NULL;

-- в. пересадочные станции с линии 1 на линию 2
SELECT 
    station.station_name, 
    station.line_number, 
    station2.station_name, 
    station2.line_number 
FROM interchange
JOIN station
ON station.id = interchange.station_a_id
JOIN station AS station2
ON station2.id = interchange.station_b_id
WHERE station.line_number = 1 AND station2.line_number = 2;
-- г. линия с самым большим временем проезда
SELECT l.* FROM line l
JOIN station s using(line_number)
JOIN route p on s.id=p.departure_station_id
GROUP BY line_number
HAVING SUM(p.commute_time) =

(SELECT MAX(total) FROM
(SELECT SUM(p.commute_time) AS total FROM station s
JOIN route p ON s.id=p.departure_station_id
GROUP BY s.line_number) t);

-- д. линия, на которой собраны все стации, которые открываются раньше 7 утра
-- academic one
SELECT DISTINCT l1.* FROM line l1 JOIN station using(line_number)
WHERE not exists
(SELECT * FROM station s1 
WHERE s1.opening_time < '07:00:00'
AND not exists
(SELECT * FROM line l2 JOIN station s2 using(line_number)
WHERE l2.line_number=l1.line_number
AND s2.id=s1.id));
-- sensible one
SELECT DISTINCT l1.* FROM line l1
JOIN station USING(line_number)
WHERE NOT EXISTS(
SELECT * FROM station s
WHERE NOT EXISTS
(SELECT * FROM line l2
WHERE s.opening_time<'07:00:00'
AND l2.line_number=s.line_number
) AND l1.line_number=s.line_number);

-- е. станция с самым ранним открытием
SELECT * FROM station WHERE opening_time <= ALL (SELECT opening_time FROM station);
 
-- ж. линия на которой нет перегона больше 3 минут
-- not in
SELECT * FROM line 
WHERE line.line_number NOT IN 
(SELECT line_number FROM station 
JOIN route 
ON route.departure_station_id = station.id
WHERE route.commute_time > 3);

-- exept
SELECT line_number FROM line 
EXCEPT 
(SELECT line_number FROM station 
JOIN route 
ON route.departure_station_id = station.id
WHERE route.commute_time > 3);

-- join
SELECT l.* FROM line l
LEFT JOIN 
(SELECT line_number FROM station 
JOIN route 
ON route.departure_station_id = station.id
WHERE route.commute_time > 3) AS j 
ON l.line_number = j.line_number
WHERE j.line_number is NULL;
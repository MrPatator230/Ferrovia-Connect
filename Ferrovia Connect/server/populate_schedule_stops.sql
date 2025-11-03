-- ===================================================================
-- Script pour peupler la table schedule_stops à partir des stops_json
-- ===================================================================
-- Ce script extrait les arrêts du JSON et les insère dans schedule_stops
-- pour permettre la recherche de trains en arrêt intermédiaire

USE horaires;

-- Vider la table schedule_stops au cas où elle contient déjà des données
TRUNCATE TABLE schedule_stops;

-- Procédure pour extraire et insérer les arrêts depuis stops_json
DROP PROCEDURE IF EXISTS populate_stops_from_json;

DELIMITER $$
CREATE PROCEDURE populate_stops_from_json()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_schedule_id INT;
    DECLARE v_stops_json JSON;
    DECLARE v_stop_count INT;
    DECLARE v_idx INT;
    DECLARE v_station_name VARCHAR(190);
    DECLARE v_station_id INT;
    DECLARE v_arrival_time TIME;
    DECLARE v_departure_time TIME;
    
    -- Curseur pour parcourir tous les sillons avec des stops_json
    DECLARE cur CURSOR FOR 
        SELECT id, stops_json 
        FROM sillons 
        WHERE stops_json IS NOT NULL 
        AND JSON_LENGTH(stops_json) > 0;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_schedule_id, v_stops_json;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Nombre d'arrêts dans le JSON
        SET v_stop_count = JSON_LENGTH(v_stops_json);
        SET v_idx = 0;
        
        -- Parcourir chaque arrêt dans le JSON
        WHILE v_idx < v_stop_count DO
            -- Extraire les informations de l'arrêt
            SET v_station_name = JSON_UNQUOTE(JSON_EXTRACT(v_stops_json, CONCAT('$[', v_idx, '].station_name')));
            
            -- Trouver l'ID de la station
            SELECT id INTO v_station_id 
            FROM stations 
            WHERE name = v_station_name 
            LIMIT 1;
            
            -- Si la station existe, insérer l'arrêt
            IF v_station_id IS NOT NULL THEN
                -- Extraire les horaires
                SET v_arrival_time = JSON_UNQUOTE(JSON_EXTRACT(v_stops_json, CONCAT('$[', v_idx, '].arrival_time')));
                SET v_departure_time = JSON_UNQUOTE(JSON_EXTRACT(v_stops_json, CONCAT('$[', v_idx, '].departure_time')));
                
                -- Convertir 'null' en NULL
                IF v_arrival_time = 'null' THEN SET v_arrival_time = NULL; END IF;
                IF v_departure_time = 'null' THEN SET v_departure_time = NULL; END IF;
                
                -- Insérer l'arrêt
                INSERT INTO schedule_stops (schedule_id, stop_order, station_id, arrival_time, departure_time)
                VALUES (v_schedule_id, v_idx + 1, v_station_id, v_arrival_time, v_departure_time)
                ON DUPLICATE KEY UPDATE
                    arrival_time = v_arrival_time,
                    departure_time = v_departure_time;
            END IF;
            
            SET v_idx = v_idx + 1;
        END WHILE;
    END LOOP;
    
    CLOSE cur;
END$$
DELIMITER ;

-- Exécuter la procédure
CALL populate_stops_from_json();

-- Vérifier le résultat
SELECT 
    COUNT(*) as total_stops,
    COUNT(DISTINCT schedule_id) as schedules_with_stops,
    COUNT(DISTINCT station_id) as stations_served
FROM schedule_stops;

-- Afficher quelques exemples
SELECT 
    st.schedule_id,
    s.train_number,
    stn.name as station_name,
    st.arrival_time,
    st.departure_time,
    st.stop_order
FROM schedule_stops st
JOIN sillons s ON s.id = st.schedule_id
JOIN stations stn ON stn.id = st.station_id
ORDER BY st.schedule_id, st.stop_order
LIMIT 20;

-- Nettoyer
DROP PROCEDURE IF EXISTS populate_stops_from_json;

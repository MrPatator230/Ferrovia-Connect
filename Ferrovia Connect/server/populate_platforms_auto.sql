-- ===================================================================
-- Script automatique pour peupler les quais depuis les trains existants
-- ===================================================================
-- Ce script génère des quais pour tous les trains aux gares de départ,
-- d'arrivée et intermédiaires
-- ===================================================================

USE `horaires`;

-- 1. Créer des quais pour les gares de DÉPART
INSERT INTO schedule_platforms (schedule_id, station_id, platform)
SELECT 
    s.id as schedule_id,
    s.departure_station_id as station_id,
    -- Générer un numéro de quai basé sur l'ID (modulo pour avoir des quais entre 1 et 8)
    CAST((s.id % 8) + 1 AS CHAR) as platform
FROM sillons s
WHERE NOT EXISTS (
    SELECT 1 FROM schedule_platforms sp 
    WHERE sp.schedule_id = s.id 
    AND sp.station_id = s.departure_station_id
)
LIMIT 100;

-- 2. Créer des quais pour les gares d'ARRIVÉE
INSERT INTO schedule_platforms (schedule_id, station_id, platform)
SELECT 
    s.id as schedule_id,
    s.arrival_station_id as station_id,
    -- Générer un numéro de quai différent pour l'arrivée
    CAST(((s.id + 3) % 8) + 1 AS CHAR) as platform
FROM sillons s
WHERE NOT EXISTS (
    SELECT 1 FROM schedule_platforms sp 
    WHERE sp.schedule_id = s.id 
    AND sp.station_id = s.arrival_station_id
)
AND s.departure_station_id != s.arrival_station_id  -- Éviter les doublons
LIMIT 100;

-- 3. Créer des quais pour les gares INTERMÉDIAIRES (désservies)
INSERT INTO schedule_platforms (schedule_id, station_id, platform)
SELECT 
    st.schedule_id,
    st.station_id,
    -- Générer un numéro de quai basé sur la combinaison schedule_id et station_id
    CAST(((st.schedule_id + st.station_id) % 8) + 1 AS CHAR) as platform
FROM schedule_stops st
WHERE NOT EXISTS (
    SELECT 1 FROM schedule_platforms sp 
    WHERE sp.schedule_id = st.schedule_id 
    AND sp.station_id = st.station_id
)
LIMIT 200;

-- Vérifier les quais créés
SELECT 
    COUNT(*) as total_quais,
    COUNT(DISTINCT schedule_id) as trains_avec_quais,
    COUNT(DISTINCT station_id) as gares_avec_quais
FROM schedule_platforms;

-- Afficher quelques exemples
SELECT 
    sp.id,
    s.train_number,
    st.name as station_name,
    sp.platform as quai,
    DATE_FORMAT(s.departure_time, '%H:%i') as heure_depart,
    sp.created_at
FROM schedule_platforms sp
JOIN sillons s ON s.id = sp.schedule_id
JOIN stations st ON st.id = sp.station_id
ORDER BY s.train_number, st.name
LIMIT 20;

-- Pour attribuer des quais spécifiques (A, B, C, etc.) pour certaines grandes gares
-- Exemple pour Dijon (remplacer l'ID par celui de votre BDD)
/*
UPDATE schedule_platforms sp
JOIN sillons s ON s.id = sp.schedule_id
SET sp.platform = CASE 
    WHEN s.id % 4 = 0 THEN 'A'
    WHEN s.id % 4 = 1 THEN 'B'
    WHEN s.id % 4 = 2 THEN 'C'
    ELSE 'D'
END
WHERE sp.station_id = 1  -- ID de Dijon
LIMIT 50;
*/

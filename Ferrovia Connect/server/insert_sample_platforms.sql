-- ===================================================================
-- Script d'insertion de quais de test pour la table schedule_platforms
-- ===================================================================
-- Ce script ajoute des quais pour les trains et gares existants
-- À adapter selon vos données réelles
-- ===================================================================

USE `horaires`;

-- Insérer des quais pour les trains depuis différentes gares
-- Format: (schedule_id, station_id, platform)

-- Exemple: Si vous avez un train avec l'ID 1 qui passe par plusieurs gares
-- Vous devez avoir ces données dans vos tables sillons et stations

-- Pour la gare de Dijon (supposons ID = 1)
INSERT INTO schedule_platforms (schedule_id, station_id, platform) 
VALUES 
    (1, 1, '2'),  -- Train 1, Gare Dijon, Voie 2
    (2, 1, '3'),  -- Train 2, Gare Dijon, Voie 3
    (3, 1, '1'),  -- Train 3, Gare Dijon, Voie 1
    (4, 1, '4')   -- Train 4, Gare Dijon, Voie 4
ON DUPLICATE KEY UPDATE 
    platform = VALUES(platform),
    updated_at = CURRENT_TIMESTAMP;

-- Pour la gare de Besançon (supposons ID = 2)
INSERT INTO schedule_platforms (schedule_id, station_id, platform) 
VALUES 
    (1, 2, 'A'),  -- Train 1, Gare Besançon, Voie A
    (2, 2, 'B'),  -- Train 2, Gare Besançon, Voie B
    (3, 2, 'C'),  -- Train 3, Gare Besançon, Voie C
    (5, 2, '1')   -- Train 5, Gare Besançon, Voie 1
ON DUPLICATE KEY UPDATE 
    platform = VALUES(platform),
    updated_at = CURRENT_TIMESTAMP;

-- Pour la gare d'Auxonne (supposons ID = 3)
INSERT INTO schedule_platforms (schedule_id, station_id, platform) 
VALUES 
    (1, 3, '1'),  -- Train 1, Gare Auxonne, Voie 1
    (2, 3, '2'),  -- Train 2, Gare Auxonne, Voie 2
    (6, 3, '1'),  -- Train 6, Gare Auxonne, Voie 1
    (7, 3, '2')   -- Train 7, Gare Auxonne, Voie 2
ON DUPLICATE KEY UPDATE 
    platform = VALUES(platform),
    updated_at = CURRENT_TIMESTAMP;

-- Vérification des données insérées
SELECT 
    sp.id,
    s.train_number,
    st.name as station_name,
    sp.platform,
    sp.created_at
FROM schedule_platforms sp
JOIN sillons s ON s.id = sp.schedule_id
JOIN stations st ON st.id = sp.station_id
ORDER BY st.name, s.train_number;

-- Pour insérer des quais pour tous les trains existants automatiquement
-- (à adapter selon vos besoins réels)
/*
INSERT INTO schedule_platforms (schedule_id, station_id, platform)
SELECT 
    s.id as schedule_id,
    s.departure_station_id as station_id,
    CONCAT('', FLOOR(1 + RAND() * 10)) as platform  -- Quai aléatoire entre 1 et 10
FROM sillons s
LEFT JOIN schedule_platforms sp ON sp.schedule_id = s.id AND sp.station_id = s.departure_station_id
WHERE sp.id IS NULL  -- Seulement si le quai n'existe pas déjà
ON DUPLICATE KEY UPDATE 
    platform = VALUES(platform);
*/

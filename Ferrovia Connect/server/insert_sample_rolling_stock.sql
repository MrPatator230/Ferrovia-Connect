-- Exemples de données pour tester le matériel roulant
-- À exécuter dans la base de données ferrovia_bfc

USE ferrovia_bfc;

-- Insérer des exemples de matériel roulant
INSERT INTO materiel_roulant (name, technical_name, capacity, train_type, serial_number) VALUES
('Regiolis', 'B 84500', 220, 'TER', '84500'),
('AGC', 'B 82500', 200, 'TER', '82500'),
('Coradia Liner', 'B 84600', 240, 'TER', '84600'),
('Régiolis 4 caisses', 'B 84501', 280, 'TER', '84501'),
('AGC Bimode', 'B 82501', 210, 'TER', '82501')
ON DUPLICATE KEY UPDATE 
    name = VALUES(name),
    technical_name = VALUES(technical_name),
    capacity = VALUES(capacity),
    train_type = VALUES(train_type);

-- Vérifier les données insérées
SELECT * FROM materiel_roulant;

-- migration_add_region_to_infos_trafics.sql
-- Ajoute la colonne `region` à la table `infos_trafics` si elle n'existe pas

DELIMITER $$
CREATE PROCEDURE add_region_if_not_exists()
BEGIN
  IF NOT EXISTS (
    SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'ferrovia_bfc'
      AND TABLE_NAME = 'infos_trafics'
      AND COLUMN_NAME = 'region'
  ) THEN
    ALTER TABLE infos_trafics ADD COLUMN region VARCHAR(191) NULL;
  END IF;
END$$

CALL add_region_if_not_exists();
DROP PROCEDURE IF EXISTS add_region_if_not_exists;
DELIMITER ;

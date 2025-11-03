-- seed_infotrafic_bfc.sql
-- Insère des exemples d'infos trafic pour la région Bourgogne-Franche-Comté

USE ferrovia_bfc;

INSERT INTO infos_trafics (`type`, `titre`, `contenu`, `created_at`, `updated_at`, `region`) VALUES
('travaux', 'Info Travaux', 'Le trafic sera interrompu entre Laroche et Auxerre en semaine de 9h30 à 16h30 du 17 novembre au 28 novembre.\n\n-892604 sera origine Laroche et substitué par l\'autocar 418074 d\'Avallon à Laroche.\n\n-892601 sera terminus Auxerre et substitué par le 418053.\n\nLimitations des TRAINS Mobigo et mise en place de substitution autocar entre Laroche et Auxerre.\n\nVérifiez vos horaires sur les applications habituelles.', NOW(), NOW(), 'Bourgogne-Franche-Comté'),
('travaux', 'Travaux sur le réseau TRAIN Mobigo', 'TRAVAUX SUR LES VOIES\n\nDes travaux ont lieu tout au long de l\'année sur le réseau TRAIN Mobigo et peuvent impacter la circulation des trains. Retrouvez le détail sur la page dédiée et vérifiez les horaires avant votre déplacement.', NOW(), NOW(), 'Bourgogne-Franche-Comté');

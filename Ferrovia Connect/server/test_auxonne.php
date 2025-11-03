<?php
// Script de test pour diagnostiquer le problème avec Auxonne

header('Content-Type: text/html; charset=utf-8');

$host = '72.61.96.42';
$port = 3306;
$database = 'horaires';
$username = 'admin_ferrovia';
$password = 'Mrpatator290406-#';

try {
    $dsn = "mysql:host=$host;port=$port;dbname=$database;charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Erreur de connexion : " . $e->getMessage());
}

echo "<h1>Diagnostic Gare d'Auxonne</h1>";

// 1. Trouver l'ID de la gare d'Auxonne
echo "<h2>1. Recherche de la gare 'Auxonne'</h2>";
$stmt = $pdo->prepare("SELECT id, name, region FROM stations WHERE name LIKE '%Auxonne%'");
$stmt->execute();
$auxonne = $stmt->fetch();

if ($auxonne) {
    echo "<p>✅ Gare trouvée : ID = {$auxonne['id']}, Nom = {$auxonne['name']}, Région = {$auxonne['region']}</p>";
    $stationId = $auxonne['id'];
} else {
    die("<p>❌ Gare Auxonne non trouvée</p>");
}

// 2. Vérifier les trains où Auxonne est gare de départ
echo "<h2>2. Trains au départ d'Auxonne (gare de départ)</h2>";
$stmt = $pdo->prepare("
    SELECT id, train_number, train_type, departure_time, arrival_time, days_mask,
           (SELECT name FROM stations WHERE id = departure_station_id) as dep_station,
           (SELECT name FROM stations WHERE id = arrival_station_id) as arr_station
    FROM sillons 
    WHERE departure_station_id = :stationId
    ORDER BY departure_time
");
$stmt->execute([':stationId' => $stationId]);
$departures = $stmt->fetchAll();
echo "<p>Nombre de trains au départ : " . count($departures) . "</p>";
if (count($departures) > 0) {
    echo "<table border='1' cellpadding='5'><tr><th>ID</th><th>Train</th><th>Type</th><th>Départ</th><th>Arrivée</th><th>Vers</th><th>Days Mask</th></tr>";
    foreach ($departures as $train) {
        echo "<tr>";
        echo "<td>{$train['id']}</td>";
        echo "<td>{$train['train_number']}</td>";
        echo "<td>{$train['train_type']}</td>";
        echo "<td>{$train['departure_time']}</td>";
        echo "<td>{$train['arrival_time']}</td>";
        echo "<td>{$train['arr_station']}</td>";
        echo "<td>{$train['days_mask']}</td>";
        echo "</tr>";
    }
    echo "</table>";
}

// 3. Vérifier les trains où Auxonne est gare d'arrivée
echo "<h2>3. Trains à l'arrivée à Auxonne (gare d'arrivée)</h2>";
$stmt = $pdo->prepare("
    SELECT id, train_number, train_type, departure_time, arrival_time, days_mask,
           (SELECT name FROM stations WHERE id = departure_station_id) as dep_station,
           (SELECT name FROM stations WHERE id = arrival_station_id) as arr_station
    FROM sillons 
    WHERE arrival_station_id = :stationId
    ORDER BY arrival_time
");
$stmt->execute([':stationId' => $stationId]);
$arrivals = $stmt->fetchAll();
echo "<p>Nombre de trains à l'arrivée : " . count($arrivals) . "</p>";
if (count($arrivals) > 0) {
    echo "<table border='1' cellpadding='5'><tr><th>ID</th><th>Train</th><th>Type</th><th>Départ</th><th>Arrivée</th><th>Depuis</th><th>Days Mask</th></tr>";
    foreach ($arrivals as $train) {
        echo "<tr>";
        echo "<td>{$train['id']}</td>";
        echo "<td>{$train['train_number']}</td>";
        echo "<td>{$train['train_type']}</td>";
        echo "<td>{$train['departure_time']}</td>";
        echo "<td>{$train['arrival_time']}</td>";
        echo "<td>{$train['dep_station']}</td>";
        echo "<td>{$train['days_mask']}</td>";
        echo "</tr>";
    }
    echo "</table>";
}

// 4. Vérifier les arrêts intermédiaires à Auxonne
echo "<h2>4. Trains passant par Auxonne (arrêts intermédiaires)</h2>";
$stmt = $pdo->prepare("
    SELECT DISTINCT
        s.id, s.train_number, s.train_type, s.days_mask,
        st.arrival_time, st.departure_time,
        (SELECT name FROM stations WHERE id = s.departure_station_id) as dep_station,
        (SELECT name FROM stations WHERE id = s.arrival_station_id) as arr_station
    FROM schedule_stops st
    JOIN sillons s ON s.id = st.schedule_id
    WHERE st.station_id = :stationId
    AND s.departure_station_id != :stationId
    AND s.arrival_station_id != :stationId
    ORDER BY st.departure_time
");
$stmt->execute([':stationId' => $stationId]);
$stops = $stmt->fetchAll();
echo "<p>Nombre de trains en arrêt : " . count($stops) . "</p>";
if (count($stops) > 0) {
    echo "<table border='1' cellpadding='5'><tr><th>ID Sillon</th><th>Train</th><th>Type</th><th>Arrivée</th><th>Départ</th><th>De</th><th>Vers</th><th>Days Mask</th></tr>";
    foreach ($stops as $train) {
        echo "<tr>";
        echo "<td>{$train['id']}</td>";
        echo "<td>{$train['train_number']}</td>";
        echo "<td>{$train['train_type']}</td>";
        echo "<td>" . ($train['arrival_time'] ?? 'NULL') . "</td>";
        echo "<td>" . ($train['departure_time'] ?? 'NULL') . "</td>";
        echo "<td>{$train['dep_station']}</td>";
        echo "<td>{$train['arr_station']}</td>";
        echo "<td>{$train['days_mask']}</td>";
        echo "</tr>";
    }
    echo "</table>";
}

// 5. Test de la requête API pour les départs (comme l'app le fait)
echo "<h2>5. Test requête API Départs (date du jour)</h2>";
$date = date('Y-m-d');
$dayOfWeek = date('N', strtotime($date));
$dayMask = 1 << ($dayOfWeek - 1);
if ($dayOfWeek == 7) {
    $dayMask = 64;
}

echo "<p>Date : $date<br>Jour de la semaine : $dayOfWeek<br>Day Mask : $dayMask</p>";

$sql = "
    SELECT 
        s.id,
        s.train_number,
        s.train_type,
        s.rolling_stock,
        DATE_FORMAT(s.departure_time, '%H:%i') as departure_time,
        DATE_FORMAT(s.arrival_time, '%H:%i') as arrival_time,
        s.days_mask,
        ds.name as departure_station,
        ast.name as arrival_station
    FROM sillons s
    JOIN stations ds ON ds.id = s.departure_station_id
    JOIN stations ast ON ast.id = s.arrival_station_id
    WHERE s.departure_station_id = :stationId
    AND (s.days_mask & :dayMask) > 0
    
    UNION
    
    SELECT 
        s.id,
        s.train_number,
        s.train_type,
        s.rolling_stock,
        DATE_FORMAT(st.departure_time, '%H:%i') as departure_time,
        DATE_FORMAT(st.arrival_time, '%H:%i') as arrival_time,
        s.days_mask,
        ds.name as departure_station,
        ast.name as arrival_station
    FROM sillons s
    JOIN stations ds ON ds.id = s.departure_station_id
    JOIN stations ast ON ast.id = s.arrival_station_id
    JOIN schedule_stops st ON st.schedule_id = s.id AND st.station_id = :stationId
    WHERE s.departure_station_id != :stationId
    AND s.arrival_station_id != :stationId
    AND st.departure_time IS NOT NULL
    AND st.arrival_time IS NOT NULL
    AND (s.days_mask & :dayMask) > 0
    
    ORDER BY departure_time ASC
";

$stmt = $pdo->prepare($sql);
$stmt->execute([
    ':stationId' => $stationId,
    ':dayMask' => $dayMask
]);
$apiResults = $stmt->fetchAll();

echo "<p><strong>Résultats de la requête API : " . count($apiResults) . " train(s)</strong></p>";
if (count($apiResults) > 0) {
    echo "<table border='1' cellpadding='5'><tr><th>ID</th><th>Train</th><th>Type</th><th>Départ</th><th>Arrivée</th><th>De</th><th>Vers</th><th>Days Mask</th></tr>";
    foreach ($apiResults as $train) {
        echo "<tr>";
        echo "<td>{$train['id']}</td>";
        echo "<td>{$train['train_number']}</td>";
        echo "<td>{$train['train_type']}</td>";
        echo "<td>{$train['departure_time']}</td>";
        echo "<td>{$train['arrival_time']}</td>";
        echo "<td>{$train['departure_station']}</td>";
        echo "<td>{$train['arrival_station']}</td>";
        echo "<td>{$train['days_mask']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color:red;'>❌ Aucun train trouvé avec cette requête</p>";
}

// 6. Analyse des days_mask
echo "<h2>6. Analyse des jours de circulation</h2>";
echo "<p>Days mask actuel pour aujourd'hui : $dayMask</p>";
echo "<ul>";
echo "<li>Bit 0 (1) = Lundi</li>";
echo "<li>Bit 1 (2) = Mardi</li>";
echo "<li>Bit 2 (4) = Mercredi</li>";
echo "<li>Bit 3 (8) = Jeudi</li>";
echo "<li>Bit 4 (16) = Vendredi</li>";
echo "<li>Bit 5 (32) = Samedi</li>";
echo "<li>Bit 6 (64) = Dimanche</li>";
echo "</ul>";
echo "<p>Exemple : days_mask = 31 = circulation du lundi au vendredi (1+2+4+8+16)</p>";

?>

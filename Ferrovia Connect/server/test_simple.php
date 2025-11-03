<?php
header('Content-Type: application/json; charset=utf-8');

$host = '72.61.96.42';
$port = 3306;
$database = 'horaires';
$username = 'admin_ferrovia';
$password = 'Mrpatator290406-#';

try {
    $pdo = new PDO("mysql:host=$host;port=$port;dbname=$database;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Trouver Auxonne
    $stmt = $pdo->query("SELECT id, name FROM stations WHERE name LIKE '%Auxonne%' LIMIT 1");
    $auxonne = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$auxonne) {
        echo json_encode(['error' => 'Auxonne not found']);
        exit;
    }
    
    $stationId = $auxonne['id'];
    
    // Test simple : compter les trains
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as total FROM sillons WHERE departure_station_id = :id
    ");
    $stmt->execute([':id' => $stationId]);
    $depCount = $stmt->fetch()['total'];
    
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as total FROM sillons WHERE arrival_station_id = :id
    ");
    $stmt->execute([':id' => $stationId]);
    $arrCount = $stmt->fetch()['total'];
    
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as total FROM schedule_stops WHERE station_id = :id
    ");
    $stmt->execute([':id' => $stationId]);
    $stopCount = $stmt->fetch()['total'];
    
    // Lister quelques exemples
    $stmt = $pdo->prepare("
        SELECT s.id, s.train_number, s.days_mask, 
               DATE_FORMAT(st.departure_time, '%H:%i') as dep_time,
               DATE_FORMAT(st.arrival_time, '%H:%i') as arr_time
        FROM schedule_stops st
        JOIN sillons s ON s.id = st.schedule_id
        WHERE st.station_id = :id
        LIMIT 5
    ");
    $stmt->execute([':id' => $stationId]);
    $examples = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'station' => $auxonne,
        'counts' => [
            'as_departure' => $depCount,
            'as_arrival' => $arrCount,
            'as_stop' => $stopCount
        ],
        'examples' => $examples,
        'today' => date('Y-m-d'),
        'dayOfWeek' => date('N'),
        'dayMask' => 1 << (date('N') - 1)
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>

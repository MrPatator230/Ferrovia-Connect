<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

// Configuration de la base de données
$host = '72.61.96.42';
$port = 3306;
$database = 'horaires';
$username = 'admin_ferrovia';
$password = 'Mrpatator290406-#';

try {
    $dsn = "mysql:host=$host;port=$port;dbname=$database;charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Erreur de connexion à la base de données: ' . $e->getMessage()
    ]);
    exit;
}

// Récupérer les paramètres
$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        case 'getTrainDetails':
            $trainNumber = $_GET['trainNumber'] ?? '';
            $date = $_GET['date'] ?? date('Y-m-d');
            getTrainDetails($pdo, $trainNumber, $date);
            break;
        
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Action non reconnue. Actions disponibles: getTrainDetails'
            ]);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}

function getTrainDetails($pdo, $trainNumber, $date) {
    if (empty($trainNumber)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Numéro de train requis'
        ]);
        return;
    }
    
    // Calculer le jour de la semaine (1=Lundi, 7=Dimanche)
    $dayOfWeek = date('N', strtotime($date));
    
    // Convertir en bitmask (bit0=Lundi, bit1=Mardi, ..., bit6=Dimanche)
    $dayMask = 1 << ($dayOfWeek - 1);
    if ($dayOfWeek == 7) { // Dimanche
        $dayMask = 64;
    }
    
    // Récupérer les informations du train
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
            ds.id as departure_station_id,
            ast.name as arrival_station,
            ast.id as arrival_station_id,
            s.stops_json,
            v.type as variant_type,
            v.delay_minutes,
            v.cause as delay_cause
        FROM sillons s
        JOIN stations ds ON ds.id = s.departure_station_id
        JOIN stations ast ON ast.id = s.arrival_station_id
        LEFT JOIN schedule_daily_variants v ON v.schedule_id = s.id AND v.date = :date
        WHERE s.train_number = :trainNumber
        AND (
            (s.days_mask & :dayMask) > 0
            OR EXISTS (SELECT 1 FROM schedule_custom_include WHERE schedule_id = s.id AND date = :date)
        )
        AND NOT EXISTS (SELECT 1 FROM schedule_custom_exclude WHERE schedule_id = s.id AND date = :date)
        AND (v.type IS NULL OR v.type != 'suppression')
        LIMIT 1
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':trainNumber' => $trainNumber,
        ':date' => $date,
        ':dayMask' => $dayMask
    ]);
    
    $train = $stmt->fetch();
    
    if (!$train) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Train non trouvé'
        ]);
        return;
    }
    
    // Récupérer les arrêts du train
    $sqlStops = "
        SELECT 
            st.stop_order,
            s.name as station_name,
            s.id as station_id,
            DATE_FORMAT(st.arrival_time, '%H:%i') as arrival_time,
            DATE_FORMAT(st.departure_time, '%H:%i') as departure_time,
            CASE
                WHEN st.arrival_time IS NULL OR st.departure_time IS NULL THEN NULL
                ELSE GREATEST(0, (TIME_TO_SEC(st.departure_time) - TIME_TO_SEC(st.arrival_time)) DIV 60)
            END as dwell_minutes,
            p.platform
        FROM schedule_stops st
        JOIN stations s ON s.id = st.station_id
        LEFT JOIN schedule_platforms p ON p.schedule_id = st.schedule_id AND p.station_id = st.station_id
        WHERE st.schedule_id = :scheduleId
        ORDER BY st.stop_order ASC
    ";
    
    $stmtStops = $pdo->prepare($sqlStops);
    $stmtStops->execute([':scheduleId' => $train['id']]);
    $stops = $stmtStops->fetchAll();
    
    // Récupérer les quais pour les gares de départ et d'arrivée
    $sqlPlatforms = "
        SELECT 
            station_id,
            platform
        FROM schedule_platforms
        WHERE schedule_id = :scheduleId
        AND station_id IN (:departureStationId, :arrivalStationId)
    ";
    
    $stmtPlatforms = $pdo->prepare($sqlPlatforms);
    $stmtPlatforms->execute([
        ':scheduleId' => $train['id'],
        ':departureStationId' => $train['departure_station_id'],
        ':arrivalStationId' => $train['arrival_station_id']
    ]);
    $platforms = $stmtPlatforms->fetchAll(PDO::FETCH_KEY_PAIR);
    
    $train['departure_platform'] = $platforms[$train['departure_station_id']] ?? null;
    $train['arrival_platform'] = $platforms[$train['arrival_station_id']] ?? null;
    $train['stops'] = $stops;
    
    echo json_encode([
        'success' => true,
        'data' => $train
    ]);
}
?>

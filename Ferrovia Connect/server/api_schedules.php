<?php
/**
 * API Schedules - Gestion des horaires de trains
 *
 * Cette API récupère les horaires de trains pour une gare donnée.
 * Elle gère 3 types de gares :
 * 1. Gare d'ORIGINE (departure_station_id) - trains qui partent de cette gare
 * 2. Gare DÉSSERVIE (schedule_stops) - trains qui s'arrêtent à cette gare en cours de trajet
 * 3. Gare TERMINUS (arrival_station_id) - trains qui terminent à cette gare
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

// Configuration de la base de données
$host = 'localhost';
$port = 3306;
$database = 'horaires';
$username = 'admin_ferrovia';
$password = 'Mrpatator290406-#';

// Connexion à la base de données
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
        case 'getSchedules':
            $stationId = intval($_GET['stationId'] ?? 0);
            $date = $_GET['date'] ?? date('Y-m-d');
            $isDeparture = ($_GET['isDeparture'] ?? 'true') === 'true';
            getSchedules($pdo, $stationId, $date, $isDeparture);
            break;
        
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Action non reconnue. Actions disponibles: getSchedules'
            ]);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Erreur serveur: ' . $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}

/**
 * Calcule le masque de jour pour un jour donné
 * Lundi = 1 (bit 0), Mardi = 2 (bit 1), ..., Dimanche = 64 (bit 6)
 */
function calculateDayMask($date) {
    $dayOfWeek = date('N', strtotime($date)); // 1=Lundi, 7=Dimanche
    $dayMask = 1 << ($dayOfWeek - 1);
    return ['dayOfWeek' => $dayOfWeek, 'dayMask' => $dayMask];
}

/**
 * Vérifie si un train circule un jour donné
 */
function isTrainRunning($pdo, $scheduleId, $date, $dayMask) {
    // Vérifier les exclusions (priorité haute)
    $stmt = $pdo->prepare("SELECT 1 FROM schedule_custom_exclude WHERE schedule_id = ? AND date = ? LIMIT 1");
    $stmt->execute([$scheduleId, $date]);
    if ($stmt->fetch()) {
        return false; // Train exclu ce jour
    }
    
    // Vérifier les inclusions (priorité moyenne)
    $stmt = $pdo->prepare("SELECT 1 FROM schedule_custom_include WHERE schedule_id = ? AND date = ? LIMIT 1");
    $stmt->execute([$scheduleId, $date]);
    if ($stmt->fetch()) {
        return true; // Train inclus spécifiquement ce jour
    }
    
    // Vérifier le masque de jours (priorité basse)
    $stmt = $pdo->prepare("SELECT days_mask FROM sillons WHERE id = ? LIMIT 1");
    $stmt->execute([$scheduleId]);
    $result = $stmt->fetch();
    if ($result) {
        return ($result['days_mask'] & $dayMask) > 0;
    }
    
    return false;
}

/**
 * Récupère les horaires pour une gare donnée
 * Gère 3 types de gares :
 * - ORIGINE : la gare est le point de départ du train (departure_station_id)
 * - DÉSSERVIE : la gare est un arrêt intermédiaire (schedule_stops)
 * - TERMINUS : la gare est le point d'arrivée du train (arrival_station_id)
 */
function getSchedules($pdo, $stationId, $date, $isDeparture) {
    if ($stationId <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'ID de station invalide'
        ]);
        return;
    }
    
    // Calculer le jour de la semaine et le masque
    $dayInfo = calculateDayMask($date);
    $dayOfWeek = $dayInfo['dayOfWeek'];
    $dayMask = $dayInfo['dayMask'];
    
    $allSchedules = [];
    
    if ($isDeparture) {
        // =====================================================================
        // MODE DÉPARTS : Afficher les trains qui PARTENT de cette gare
        // =====================================================================
        
        // CAS 1 : Gare d'ORIGINE (le train part de cette gare)
        $sql1 = "
            SELECT 
                s.id,
                s.train_number,
                s.train_type,
                s.rolling_stock,
                DATE_FORMAT(s.departure_time, '%H:%i') as departure_time,
                DATE_FORMAT(s.arrival_time, '%H:%i') as arrival_time,
                s.days_mask,
                ds.name as departure_station,
                ast.name as arrival_station,
                s.stops_json,
                p.platform,
                v.type as variant_type,
                v.delay_minutes,
                v.cause as delay_cause,
                'origin' as stop_type
            FROM sillons s
            JOIN stations ds ON ds.id = s.departure_station_id
            JOIN stations ast ON ast.id = s.arrival_station_id
            LEFT JOIN schedule_daily_variants v ON v.schedule_id = s.id AND v.date = :date
            LEFT JOIN schedule_platforms p ON p.schedule_id = s.id AND p.station_id = :stationId
            WHERE s.departure_station_id = :stationId
        ";
        
        $stmt1 = $pdo->prepare($sql1);
        $stmt1->execute([':stationId' => $stationId, ':date' => $date]);
        $originTrains = $stmt1->fetchAll();
        
        foreach ($originTrains as $train) {
            if (!isTrainRunning($pdo, $train['id'], $date, $dayMask)) {
                continue;
            }
            if ($train['variant_type'] === 'suppression') {
                continue;
            }
            $allSchedules[] = $train;
        }
        
        // CAS 2 : Gare DÉSSERVIE (le train s'arrête à cette gare et en repart)
        $sql2 = "
            SELECT 
                s.id,
                s.train_number,
                s.train_type,
                s.rolling_stock,
                COALESCE(DATE_FORMAT(st.departure_time, '%H:%i'), DATE_FORMAT(st.arrival_time, '%H:%i'), DATE_FORMAT(s.departure_time, '%H:%i')) as departure_time,
                COALESCE(DATE_FORMAT(st.arrival_time, '%H:%i'), DATE_FORMAT(st.departure_time, '%H:%i'), DATE_FORMAT(s.arrival_time, '%H:%i')) as arrival_time,
                s.days_mask,
                ds.name as departure_station,
                ast.name as arrival_station,
                s.stops_json,
                p.platform,
                v.type as variant_type,
                v.delay_minutes,
                v.cause as delay_cause,
                'intermediate' as stop_type
            FROM schedule_stops st
            JOIN sillons s ON s.id = st.schedule_id
            JOIN stations ds ON ds.id = s.departure_station_id
            JOIN stations ast ON ast.id = s.arrival_station_id
            LEFT JOIN schedule_daily_variants v ON v.schedule_id = s.id AND v.date = :date
            LEFT JOIN schedule_platforms p ON p.schedule_id = s.id AND p.station_id = :stationId
            WHERE st.station_id = :stationId
            AND (st.departure_time IS NOT NULL OR st.arrival_time IS NOT NULL)
            AND s.departure_station_id != :stationId
            AND s.arrival_station_id != :stationId
        ";
        
        $stmt2 = $pdo->prepare($sql2);
        $stmt2->execute([':stationId' => $stationId, ':date' => $date]);
        $intermediateTrains = $stmt2->fetchAll();
        
        foreach ($intermediateTrains as $train) {
            if (!isTrainRunning($pdo, $train['id'], $date, $dayMask)) {
                continue;
            }
            if ($train['variant_type'] === 'suppression') {
                continue;
            }
            $allSchedules[] = $train;
        }
        
        // Trier par heure de départ
        usort($allSchedules, function($a, $b) {
            return strcmp($a['departure_time'], $b['departure_time']);
        });
        
    } else {
        // =====================================================================
        // MODE ARRIVÉES : Afficher les trains qui ARRIVENT à cette gare
        // =====================================================================
        
        // CAS 1 : Gare TERMINUS (le train termine à cette gare)
        $sql1 = "
            SELECT 
                s.id,
                s.train_number,
                s.train_type,
                s.rolling_stock,
                DATE_FORMAT(s.departure_time, '%H:%i') as departure_time,
                DATE_FORMAT(s.arrival_time, '%H:%i') as arrival_time,
                s.days_mask,
                ds.name as departure_station,
                ast.name as arrival_station,
                s.stops_json,
                p.platform,
                v.type as variant_type,
                v.delay_minutes,
                v.cause as delay_cause,
                'terminus' as stop_type
            FROM sillons s
            JOIN stations ds ON ds.id = s.departure_station_id
            JOIN stations ast ON ast.id = s.arrival_station_id
            LEFT JOIN schedule_daily_variants v ON v.schedule_id = s.id AND v.date = :date
            LEFT JOIN schedule_platforms p ON p.schedule_id = s.id AND p.station_id = :stationId
            WHERE s.arrival_station_id = :stationId
        ";
        
        $stmt1 = $pdo->prepare($sql1);
        $stmt1->execute([':stationId' => $stationId, ':date' => $date]);
        $terminusTrains = $stmt1->fetchAll();
        
        foreach ($terminusTrains as $train) {
            if (!isTrainRunning($pdo, $train['id'], $date, $dayMask)) {
                continue;
            }
            if ($train['variant_type'] === 'suppression') {
                continue;
            }
            $allSchedules[] = $train;
        }
        
        // CAS 2 : Gare DÉSSERVIE (le train s'arrête à cette gare en cours de trajet)
        $sql2 = "
            SELECT 
                s.id,
                s.train_number,
                s.train_type,
                s.rolling_stock,
                COALESCE(DATE_FORMAT(st.departure_time, '%H:%i'), DATE_FORMAT(st.arrival_time, '%H:%i'), DATE_FORMAT(s.departure_time, '%H:%i')) as departure_time,
                COALESCE(DATE_FORMAT(st.arrival_time, '%H:%i'), DATE_FORMAT(st.departure_time, '%H:%i'), DATE_FORMAT(s.arrival_time, '%H:%i')) as arrival_time,
                s.days_mask,
                ds.name as departure_station,
                ast.name as arrival_station,
                s.stops_json,
                p.platform,
                v.type as variant_type,
                v.delay_minutes,
                v.cause as delay_cause,
                'intermediate' as stop_type
            FROM schedule_stops st
            JOIN sillons s ON s.id = st.schedule_id
            JOIN stations ds ON ds.id = s.departure_station_id
            JOIN stations ast ON ast.id = s.arrival_station_id
            LEFT JOIN schedule_daily_variants v ON v.schedule_id = s.id AND v.date = :date
            LEFT JOIN schedule_platforms p ON p.schedule_id = s.id AND p.station_id = :stationId
            WHERE st.station_id = :stationId
            AND (st.arrival_time IS NOT NULL OR st.departure_time IS NOT NULL)
            AND s.departure_station_id != :stationId
            AND s.arrival_station_id != :stationId
        ";
        
        $stmt2 = $pdo->prepare($sql2);
        $stmt2->execute([':stationId' => $stationId, ':date' => $date]);
        $intermediateTrains = $stmt2->fetchAll();
        
        foreach ($intermediateTrains as $train) {
            if (!isTrainRunning($pdo, $train['id'], $date, $dayMask)) {
                continue;
            }
            if ($train['variant_type'] === 'suppression') {
                continue;
            }
            $allSchedules[] = $train;
        }
        
        // Trier par heure d'arrivée
        usort($allSchedules, function($a, $b) {
            return strcmp($a['arrival_time'], $b['arrival_time']);
        });
    }
    
    // Supprimer les doublons
    $uniqueSchedules = [];
    $seenIds = [];
    foreach ($allSchedules as $schedule) {
        $key = $schedule['id'] . '_' . $schedule['stop_type'];
        if (!isset($seenIds[$key])) {
            $seenIds[$key] = true;
            $uniqueSchedules[] = $schedule;
        }
    }
    
    // Log pour débogage
    error_log(sprintf(
        "API Schedules - Station: %d, Date: %s, Type: %s, DayMask: %d, Results: %d",
        $stationId,
        $date,
        $isDeparture ? 'DÉPARTS' : 'ARRIVÉES',
        $dayMask,
        count($uniqueSchedules)
    ));
    
    // Réponse JSON
    echo json_encode([
        'success' => true,
        'data' => $uniqueSchedules,
        'count' => count($uniqueSchedules),
        'stationId' => $stationId,
        'date' => $date,
        'isDeparture' => $isDeparture,
        'debug' => [
            'dayOfWeek' => $dayOfWeek,
            'dayMask' => $dayMask,
            'dayName' => ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'][$dayOfWeek]
        ]
    ], JSON_PRETTY_PRINT);
}
?>

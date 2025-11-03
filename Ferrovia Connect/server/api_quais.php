<?php
/**
 * API Quais - Gestion des quais (platforms) depuis la BDD horaires
 * 
 * Cette API gère les quais attribués aux trains pour chaque gare
 * Table : schedule_platforms
 * Structure :
 * - id : BIGINT UNSIGNED (clé primaire)
 * - schedule_id : INT UNSIGNED (référence au train/sillon)
 * - station_id : INT UNSIGNED (référence à la gare)
 * - platform : VARCHAR(40) (numéro du quai)
 * - created_at / updated_at : TIMESTAMP
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

// Configuration de la base de données
$host = 'localhost';
$port = 3306;
$database = 'horaires';
$username = 'admin_ferrovia';
$password = 'Mrpatator290406-#';

// Connexion à la base de données 'horaires'
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

// Récupérer l'action demandée
$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        case 'getAllPlatforms':
            getAllPlatforms($pdo);
            break;
        
        case 'getPlatformsBySchedule':
            $scheduleId = intval($_GET['schedule_id'] ?? 0);
            getPlatformsBySchedule($pdo, $scheduleId);
            break;
        
        case 'getPlatformsByStation':
            $stationId = intval($_GET['station_id'] ?? 0);
            getPlatformsByStation($pdo, $stationId);
            break;
        
        case 'getPlatform':
            $scheduleId = intval($_GET['schedule_id'] ?? 0);
            $stationId = intval($_GET['station_id'] ?? 0);
            getPlatform($pdo, $scheduleId, $stationId);
            break;
        
        case 'createPlatform':
            $data = json_decode(file_get_contents('php://input'), true);
            createPlatform($pdo, $data);
            break;
        
        case 'updatePlatform':
            $data = json_decode(file_get_contents('php://input'), true);
            updatePlatform($pdo, $data);
            break;
        
        case 'deletePlatform':
            $scheduleId = intval($_GET['schedule_id'] ?? $_POST['schedule_id'] ?? 0);
            $stationId = intval($_GET['station_id'] ?? $_POST['station_id'] ?? 0);
            deletePlatform($pdo, $scheduleId, $stationId);
            break;
        
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Action non reconnue. Actions disponibles: getAllPlatforms, getPlatformsBySchedule, getPlatformsByStation, getPlatform, createPlatform, updatePlatform, deletePlatform'
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

/**
 * Récupère tous les quais de la BDD
 */
function getAllPlatforms($pdo) {
    $stmt = $pdo->prepare("
        SELECT 
            sp.id,
            sp.schedule_id,
            sp.station_id,
            sp.platform,
            s.train_number,
            st.name as station_name,
            sp.created_at,
            sp.updated_at
        FROM schedule_platforms sp
        JOIN sillons s ON s.id = sp.schedule_id
        JOIN stations st ON st.id = sp.station_id
        ORDER BY sp.created_at DESC
    ");
    $stmt->execute();
    $platforms = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $platforms,
        'count' => count($platforms)
    ]);
}

/**
 * Récupère les quais pour un train/horaire spécifique
 */
function getPlatformsBySchedule($pdo, $scheduleId) {
    if ($scheduleId <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'ID de schedule invalide'
        ]);
        return;
    }
    
    $stmt = $pdo->prepare("
        SELECT 
            sp.id,
            sp.schedule_id,
            sp.station_id,
            sp.platform,
            st.name as station_name,
            sp.created_at,
            sp.updated_at
        FROM schedule_platforms sp
        JOIN stations st ON st.id = sp.station_id
        WHERE sp.schedule_id = :scheduleId
        ORDER BY st.name ASC
    ");
    $stmt->execute([':scheduleId' => $scheduleId]);
    $platforms = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $platforms,
        'count' => count($platforms)
    ]);
}

/**
 * Récupère les quais pour une gare spécifique
 */
function getPlatformsByStation($pdo, $stationId) {
    if ($stationId <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'ID de station invalide'
        ]);
        return;
    }
    
    $stmt = $pdo->prepare("
        SELECT 
            sp.id,
            sp.schedule_id,
            sp.station_id,
            sp.platform,
            s.train_number,
            DATE_FORMAT(s.departure_time, '%H:%i') as departure_time,
            DATE_FORMAT(s.arrival_time, '%H:%i') as arrival_time,
            sp.created_at,
            sp.updated_at
        FROM schedule_platforms sp
        JOIN sillons s ON s.id = sp.schedule_id
        WHERE sp.station_id = :stationId
        ORDER BY s.departure_time ASC
    ");
    $stmt->execute([':stationId' => $stationId]);
    $platforms = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $platforms,
        'count' => count($platforms)
    ]);
}

/**
 * Récupère un quai spécifique pour un train et une gare
 */
function getPlatform($pdo, $scheduleId, $stationId) {
    if ($scheduleId <= 0 || $stationId <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'IDs de schedule et station invalides'
        ]);
        return;
    }
    
    $stmt = $pdo->prepare("
        SELECT 
            sp.id,
            sp.schedule_id,
            sp.station_id,
            sp.platform,
            s.train_number,
            st.name as station_name,
            sp.created_at,
            sp.updated_at
        FROM schedule_platforms sp
        JOIN sillons s ON s.id = sp.schedule_id
        JOIN stations st ON st.id = sp.station_id
        WHERE sp.schedule_id = :scheduleId AND sp.station_id = :stationId
        LIMIT 1
    ");
    $stmt->execute([
        ':scheduleId' => $scheduleId,
        ':stationId' => $stationId
    ]);
    $platform = $stmt->fetch();
    
    if ($platform) {
        echo json_encode([
            'success' => true,
            'data' => $platform
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Quai non trouvé'
        ]);
    }
}

/**
 * Crée un nouveau quai
 */
function createPlatform($pdo, $data) {
    // Validation des données
    if (empty($data['schedule_id']) || empty($data['station_id']) || empty($data['platform'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Données manquantes. Requis: schedule_id, station_id, platform'
        ]);
        return;
    }
    
    $scheduleId = intval($data['schedule_id']);
    $stationId = intval($data['station_id']);
    $platform = trim($data['platform']);
    
    // Vérifier si le quai existe déjà
    $checkStmt = $pdo->prepare("
        SELECT id FROM schedule_platforms 
        WHERE schedule_id = :scheduleId AND station_id = :stationId
    ");
    $checkStmt->execute([
        ':scheduleId' => $scheduleId,
        ':stationId' => $stationId
    ]);
    
    if ($checkStmt->fetch()) {
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'error' => 'Un quai existe déjà pour ce train et cette gare'
        ]);
        return;
    }
    
    // Insérer le nouveau quai
    $stmt = $pdo->prepare("
        INSERT INTO schedule_platforms (schedule_id, station_id, platform)
        VALUES (:scheduleId, :stationId, :platform)
    ");
    
    $stmt->execute([
        ':scheduleId' => $scheduleId,
        ':stationId' => $stationId,
        ':platform' => $platform
    ]);
    
    $newId = $pdo->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'message' => 'Quai créé avec succès',
        'data' => [
            'id' => $newId,
            'schedule_id' => $scheduleId,
            'station_id' => $stationId,
            'platform' => $platform
        ]
    ]);
}

/**
 * Met à jour un quai existant
 */
function updatePlatform($pdo, $data) {
    // Validation des données
    if (empty($data['schedule_id']) || empty($data['station_id']) || empty($data['platform'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Données manquantes. Requis: schedule_id, station_id, platform'
        ]);
        return;
    }
    
    $scheduleId = intval($data['schedule_id']);
    $stationId = intval($data['station_id']);
    $platform = trim($data['platform']);
    
    // Vérifier si le quai existe
    $checkStmt = $pdo->prepare("
        SELECT id FROM schedule_platforms 
        WHERE schedule_id = :scheduleId AND station_id = :stationId
    ");
    $checkStmt->execute([
        ':scheduleId' => $scheduleId,
        ':stationId' => $stationId
    ]);
    
    if (!$checkStmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Quai non trouvé'
        ]);
        return;
    }
    
    // Mettre à jour le quai
    $stmt = $pdo->prepare("
        UPDATE schedule_platforms 
        SET platform = :platform
        WHERE schedule_id = :scheduleId AND station_id = :stationId
    ");
    
    $stmt->execute([
        ':platform' => $platform,
        ':scheduleId' => $scheduleId,
        ':stationId' => $stationId
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Quai mis à jour avec succès',
        'data' => [
            'schedule_id' => $scheduleId,
            'station_id' => $stationId,
            'platform' => $platform
        ]
    ]);
}

/**
 * Supprime un quai
 */
function deletePlatform($pdo, $scheduleId, $stationId) {
    if ($scheduleId <= 0 || $stationId <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'IDs de schedule et station invalides'
        ]);
        return;
    }
    
    // Vérifier si le quai existe
    $checkStmt = $pdo->prepare("
        SELECT id FROM schedule_platforms 
        WHERE schedule_id = :scheduleId AND station_id = :stationId
    ");
    $checkStmt->execute([
        ':scheduleId' => $scheduleId,
        ':stationId' => $stationId
    ]);
    
    if (!$checkStmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Quai non trouvé'
        ]);
        return;
    }
    
    // Supprimer le quai
    $stmt = $pdo->prepare("
        DELETE FROM schedule_platforms 
        WHERE schedule_id = :scheduleId AND station_id = :stationId
    ");
    
    $stmt->execute([
        ':scheduleId' => $scheduleId,
        ':stationId' => $stationId
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Quai supprimé avec succès'
    ]);
}
?>

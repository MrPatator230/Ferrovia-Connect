<?php
/**
 * API Stations - Gestion des gares depuis la BDD horaires
 * 
 * Cette API récupère les gares depuis la base de données 'horaires'
 * Structure de la table stations :
 * - id : INT UNSIGNED (clé primaire)
 * - name : VARCHAR(190) (nom de la gare)
 * - slug : VARCHAR(190) (généré automatiquement)
 * - region : VARCHAR(120) (région, nullable)
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
$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        case 'getAllStations':
            getAllStations($pdo);
            break;
        
        case 'searchStations':
            $query = $_GET['query'] ?? '';
            searchStations($pdo, $query);
            break;
        
        case 'getStation':
            $id = intval($_GET['id'] ?? 0);
            getStation($pdo, $id);
            break;
        
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Action non reconnue. Actions disponibles: getAllStations, searchStations, getStation'
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
 * Récupère toutes les gares de la BDD horaires
 */
function getAllStations($pdo) {
    $stmt = $pdo->prepare("
        SELECT id, name, slug, region
        FROM stations
        ORDER BY name ASC
    ");
    $stmt->execute();
    $stations = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $stations,
        'count' => count($stations)
    ]);
}

/**
 * Recherche des gares par nom ou slug
 */
function searchStations($pdo, $query) {
    if (empty($query)) {
        getAllStations($pdo);
        return;
    }
    
    // Normaliser la recherche
    $normalizedQuery = strtolower($query);
    $normalizedQuery = str_replace(' ', '-', $normalizedQuery);
    $normalizedQuery = str_replace('"', '', $normalizedQuery);
    
    $searchPattern = '%' . strtolower($query) . '%';
    $searchPatternSlug = '%' . $normalizedQuery . '%';
    $startPattern = strtolower($query) . '%';
    
    $stmt = $pdo->prepare("
        SELECT 
            id,
            name,
            slug,
            region
        FROM stations
        WHERE 
            LOWER(name) LIKE :searchPattern
            OR slug LIKE :searchPatternSlug
        ORDER BY 
            CASE 
                WHEN LOWER(name) = :exactLower THEN 1
                WHEN LOWER(name) LIKE :startPattern THEN 2
                ELSE 3
            END,
            name ASC
        LIMIT 50
    ");
    
    $stmt->execute([
        ':searchPattern' => $searchPattern,
        ':searchPatternSlug' => $searchPatternSlug,
        ':exactLower' => strtolower($query),
        ':startPattern' => $startPattern
    ]);
    
    $stations = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $stations,
        'count' => count($stations),
        'query' => $query
    ]);
}

/**
 * Récupère une gare spécifique par son ID
 */
function getStation($pdo, $id) {
    if ($id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'ID de station invalide'
        ]);
        return;
    }
    
    $stmt = $pdo->prepare("
        SELECT id, name, slug, region
        FROM stations
        WHERE id = :id
        LIMIT 1
    ");
    $stmt->execute([':id' => $id]);
    $station = $stmt->fetch();
    
    if ($station) {
        echo json_encode([
            'success' => true,
            'data' => $station
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Station non trouvée'
        ]);
    }
}
?>

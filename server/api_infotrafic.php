<?php
/**
 * API InfoTrafic - lecture des infos_trafics depuis la base ferrovia_bfc
 * Mode opératoire similaire à api_quais.php : PDO, actions, JSON structuré
 *
 * Actions disponibles (GET/POST param `action`):
 * - getByRegion  (param `region`, défaut: 'Bourgogne-Franche-Comté')
 * - getAll       (liste toutes les infos)
 * - get          (param `id`)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuration DB (reprendre les identifiants utilisés ailleurs dans l'API)
$host = 'localhost';
$port = 3306;
$database = 'ferrovia_bfc';
$username = 'admin_ferrovia';
$password = 'Mrpatator290406-#';

try {
    $dsn = "mysql:host=$host;port=$port;dbname=$database;charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Erreur de connexion à la base de données: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        case 'getByRegion':
            $region = $_GET['region'] ?? $_POST['region'] ?? 'Bourgogne-Franche-Comté';
            getByRegion($pdo, $region);
            break;

        case 'getAll':
            getAll($pdo);
            break;

        case 'get':
            $id = intval($_GET['id'] ?? $_POST['id'] ?? 0);
            getById($pdo, $id);
            break;

        default:
            // If no action provided, default to getByRegion for Bourgogne-Franche-Comté
            if ($action === '') {
                $region = $_GET['region'] ?? 'Bourgogne-Franche-Comté';
                getByRegion($pdo, $region);
                break;
            }

            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Action non reconnue. Actions disponibles: getByRegion, getAll, get']);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Erreur serveur: ' . $e->getMessage()]);
}

/**
 * Récupère les infos trafic pour une région donnée (ou fallback via LIKE si pas de colonne 'region')
 */
function getByRegion(PDO $pdo, string $region) {
    // check table exists
    $tbl = $pdo->query("SHOW TABLES LIKE 'infos_trafics'")->fetch();
    if (!$tbl) {
        echo json_encode(['success' => true, 'data' => []]);
        return;
    }

    // detect region column
    $colStmt = $pdo->prepare("SHOW COLUMNS FROM infos_trafics LIKE 'region'");
    $colStmt->execute();
    $hasRegion = ($colStmt->fetch() !== false);

    if ($hasRegion) {
        $sql = "SELECT id, titre, contenu, DATE_FORMAT(updated_at, '%d/%m/%Y à %H:%i') as updated_at FROM infos_trafics WHERE region = :region ORDER BY updated_at DESC";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':region' => $region]);
    } else {
        // fallback: search title or content
        $like = '%' . $region . '%';
        $sql = "SELECT id, titre, contenu, DATE_FORMAT(updated_at, '%d/%m/%Y à %H:%i') as updated_at FROM infos_trafics WHERE titre LIKE :like OR contenu LIKE :like ORDER BY updated_at DESC";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':like' => $like]);
    }

    $rows = $stmt->fetchAll();
    $out = [];
    foreach ($rows as $r) {
        $out[] = [
            'id' => (string)$r['id'],
            'title' => $r['titre'],
            'content' => $r['contenu'],
            'updated_at' => $r['updated_at']
        ];
    }

    echo json_encode(['success' => true, 'data' => $out], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}

/**
 * Récupère toutes les infos_trafics
 */
function getAll(PDO $pdo) {
    $tbl = $pdo->query("SHOW TABLES LIKE 'infos_trafics'")->fetch();
    if (!$tbl) {
        echo json_encode(['success' => true, 'data' => []]);
        return;
    }

    $sql = "SELECT id, titre, contenu, DATE_FORMAT(updated_at, '%d/%m/%Y à %H:%i') as updated_at FROM infos_trafics ORDER BY updated_at DESC";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();

    $rows = $stmt->fetchAll();
    $out = [];
    foreach ($rows as $r) {
        $out[] = [
            'id' => (string)$r['id'],
            'title' => $r['titre'],
            'content' => $r['contenu'],
            'updated_at' => $r['updated_at']
        ];
    }

    echo json_encode(['success' => true, 'data' => $out], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}

/**
 * Récupère une info par id
 */
function getById(PDO $pdo, int $id) {
    if ($id <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'ID invalide']);
        return;
    }

    $tbl = $pdo->query("SHOW TABLES LIKE 'infos_trafics'")->fetch();
    if (!$tbl) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Table infos_trafics introuvable']);
        return;
    }

    $sql = "SELECT id, titre, contenu, DATE_FORMAT(updated_at, '%d/%m/%Y à %H:%i') as updated_at FROM infos_trafics WHERE id = :id LIMIT 1";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([':id' => $id]);
    $r = $stmt->fetch();
    if (!$r) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Info trafic non trouvée']);
        return;
    }

    $out = [
        'id' => (string)$r['id'],
        'title' => $r['titre'],
        'content' => $r['contenu'],
        'updated_at' => $r['updated_at']
    ];

    echo json_encode(['success' => true, 'data' => $out], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}

?>

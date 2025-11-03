# Système SQL pour Ferrovia Connect

## Vue d'ensemble

Le système d'API a été remplacé par un système de requêtes SQL directes basé sur le schéma `horaires_scheme.sql`.

## Fichiers créés/modifiés

### Nouveaux fichiers:
1. **DatabaseService.swift** - Service principal pour toutes les requêtes SQL
2. **ScheduleService.swift** - Service pour gérer les horaires de trains
3. **StationDetailsView.swift** - Vue pour afficher les détails d'une gare et ses horaires

### Fichiers modifiés:
1. **Station.swift** - Modèle mis à jour (id: Int au lieu de String, ajout de region et slug)
2. **TrainSchedule.swift** - Modèle étendu pour correspondre au schéma SQL
3. **StationService.swift** - Utilise maintenant DatabaseService au lieu d'appels API

## Structure de la base de données

D'après le schéma SQL analysé:

### Tables principales:
- **stations** - Liste des gares (id, name, region, slug)
- **sillons** (schedules) - Horaires des trains
- **schedule_stops** - Arrêts intermédiaires
- **schedule_daily_variants** - Variantes quotidiennes (retards, suppressions)
- **schedule_platforms** - Attribution des voies
- **lines** - Lignes de train

### Requêtes implémentées dans DatabaseService:

1. **fetchStations()** - Récupère toutes les stations
2. **searchStations(query:)** - Recherche de stations par nom
3. **fetchSchedulesForStation(stationId:date:isDeparture:)** - Horaires pour une gare
4. **getScheduleDetails(scheduleId:date:)** - Détails d'un horaire
5. **getScheduleStops(scheduleId:)** - Arrêts d'un train
6. **fetchLines()** - Liste des lignes

## IMPORTANT: Implémentation de la connexion MySQL

⚠️ **Action requise:** Le fichier `DatabaseService.swift` contient une méthode `executeQuery()` qui doit être implémentée.

### Options d'implémentation:

#### Option 1: Utiliser une bibliothèque MySQL native (MySQLNIO)

```swift
// Ajouter à votre Package.swift ou via SPM:
dependencies: [
    .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0")
]
```

#### Option 2: Créer une API REST intermédiaire

Créer un serveur Node.js/PHP/Python qui:
- Se connecte à MySQL
- Expose des endpoints REST
- L'app iOS fait des requêtes HTTP vers ce serveur

#### Option 3: Utiliser une bibliothèque tierce

Exemple avec MySQL Connector:
```bash
# Ajouter via Swift Package Manager
https://github.com/mysql/mysql-connector-swift
```

## Configuration de la connexion

Dans `DatabaseService.swift`, mettre à jour:

```swift
struct DatabaseConfig {
    static let host = "VOTRE_HOST" // ex: "localhost" ou "192.168.1.100"
    static let port = 3306
    static let database = "horaires"
    static let username = "VOTRE_USERNAME"
    static let password = "VOTRE_PASSWORD"
}
```

## Exemple d'implémentation avec une API REST

Si vous créez un serveur intermédiaire, voici un exemple Node.js:

```javascript
// server.js
const express = require('express');
const mysql = require('mysql2/promise');
const app = express();

const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'horaires'
});

app.get('/api/stations', async (req, res) => {
  const [rows] = await pool.query('SELECT id, name, region, slug FROM stations ORDER BY name ASC');
  res.json(rows);
});

app.get('/api/schedules/:stationId', async (req, res) => {
  const { stationId } = req.params;
  const { date, isDeparture } = req.query;
  
  // Requête SQL comme dans DatabaseService.swift
  const query = isDeparture 
    ? `SELECT s.*, ... FROM sillons s WHERE s.departure_station_id = ?`
    : `SELECT s.*, ... FROM sillons s WHERE s.arrival_station_id = ?`;
    
  const [rows] = await pool.query(query, [stationId]);
  res.json(rows);
});

app.listen(3000);
```

Puis modifier `DatabaseService.swift` pour faire des appels REST.

## Utilisation dans l'application

### Récupérer les stations:
```swift
let stations = try await DatabaseService.shared.fetchStations()
```

### Récupérer les horaires:
```swift
let scheduleService = ScheduleService()
await scheduleService.fetchSchedulesForStation(stationId: 1, date: Date(), isDeparture: true)
```

### Afficher les détails d'une gare:
```swift
NavigationLink(destination: StationDetailsView(station: station)) {
    Text(station.name)
}
```

## Avantages du système SQL

1. ✅ Pas de dépendance à une API externe
2. ✅ Données structurées selon le schéma SQL
3. ✅ Support des variantes quotidiennes (retards, suppressions)
4. ✅ Gestion des arrêts intermédiaires
5. ✅ Attribution des voies (platforms)
6. ✅ Filtrage par jour de la semaine (days_mask)

## Prochaines étapes

1. Choisir et implémenter la méthode de connexion MySQL
2. Tester les requêtes avec des données réelles
3. Remplir la base de données avec les horaires
4. Configurer les credentials de connexion
5. Tester l'application complète

## Note sur AuthService

Le fichier `AuthService.swift` n'est plus nécessaire pour les requêtes de données (puisque nous utilisons SQL directement), mais peut être conservé si vous souhaitez implémenter une authentification utilisateur pour d'autres fonctionnalités.

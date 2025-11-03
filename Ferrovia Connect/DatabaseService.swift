//
//  DatabaseService.swift
//  Ferrovia Connect
//
//  Service pour gérer les connexions et requêtes SQL à la base de données MySQL
//

import Foundation
import Combine

// Configuration de la base de données
struct DatabaseConfig {
    static var host: String { "72.61.96.42" }
    static var port: Int { 3306 }
    static var database: String { "horaires" }
    static var username: String { "admin_ferrovia" }
    static var password: String { "Mrpatator290406-#" }
}

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Stations
    
    /// Récupère toutes les stations
    func fetchStations() async throws -> [Station] {
        let query = """
        SELECT id, name, region, slug
        FROM stations
        ORDER BY name ASC
        """
        
        return try await executeQuery(query, parseAs: Station.self)
    }
    
    /// Recherche des stations par nom
    func searchStations(query: String) async throws -> [Station] {
        let searchQuery = """
        SELECT id, name, region, slug
        FROM stations
        WHERE name LIKE ?
        OR slug LIKE ?
        ORDER BY 
            CASE 
                WHEN name LIKE ? THEN 1
                WHEN name LIKE ? THEN 2
                ELSE 3
            END,
            name ASC
        LIMIT 50
        """
        
        let searchPattern = "%\(query)%"
        let startPattern = "\(query)%"
        
        return try await executeQuery(
            searchQuery,
            parameters: [searchPattern, searchPattern, startPattern, searchPattern],
            parseAs: Station.self
        )
    }
    
    /// Récupère une station par ID
    func getStation(id: Int) async throws -> Station? {
        let query = """
        SELECT id, name, region, slug
        FROM stations
        WHERE id = ?
        """
        
        let results: [Station] = try await executeQuery(query, parameters: [id], parseAs: Station.self)
        return results.first
    }
    
    // MARK: - Horaires (Sillons/Schedules)
    
    /// Récupère les horaires pour une gare donnée à une date spécifique
    func fetchSchedulesForStation(stationId: Int, date: Date, isDeparture: Bool = true) async throws -> [TrainSchedule] {
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        let dayMask = dayOfWeekToBitmask(dayOfWeek)
        let dateString = formatDate(date)
        
        let query: String
        if isDeparture {
            query = """
            SELECT 
                s.id,
                s.train_number,
                s.train_type,
                s.rolling_stock,
                s.departure_time,
                s.arrival_time,
                s.days_mask,
                s.stops_json,
                ds.name as departure_station,
                ast.name as arrival_station,
                v.type as variant_type,
                v.delay_minutes,
                v.cause as delay_cause,
                p.platform
            FROM sillons s
            JOIN stations ds ON ds.id = s.departure_station_id
            JOIN stations ast ON ast.id = s.arrival_station_id
            LEFT JOIN schedule_daily_variants v ON v.schedule_id = s.id AND v.date = ?
            LEFT JOIN schedule_platforms p ON p.schedule_id = s.id AND p.station_id = ?
            WHERE s.departure_station_id = ?
            AND (
                (s.days_mask & ?) > 0
                OR EXISTS (SELECT 1 FROM schedule_custom_include WHERE schedule_id = s.id AND date = ?)
            )
            AND NOT EXISTS (SELECT 1 FROM schedule_custom_exclude WHERE schedule_id = s.id AND date = ?)
            AND (v.type IS NULL OR v.type != 'suppression')
            ORDER BY s.departure_time ASC
            """
        } else {
            query = """
            SELECT 
                s.id,
                s.train_number,
                s.train_type,
                s.rolling_stock,
                s.departure_time,
                s.arrival_time,
                s.days_mask,
                s.stops_json,
                ds.name as departure_station,
                ast.name as arrival_station,
                v.type as variant_type,
                v.delay_minutes,
                v.cause as delay_cause,
                p.platform
            FROM sillons s
            JOIN stations ds ON ds.id = s.departure_station_id
            JOIN stations ast ON ast.id = s.arrival_station_id
            LEFT JOIN schedule_daily_variants v ON v.schedule_id = s.id AND v.date = ?
            LEFT JOIN schedule_platforms p ON p.schedule_id = s.id AND p.station_id = ?
            WHERE s.arrival_station_id = ?
            AND (
                (s.days_mask & ?) > 0
                OR EXISTS (SELECT 1 FROM schedule_custom_include WHERE schedule_id = s.id AND date = ?)
            )
            AND NOT EXISTS (SELECT 1 FROM schedule_custom_exclude WHERE schedule_id = s.id AND date = ?)
            AND (v.type IS NULL OR v.type != 'suppression')
            ORDER BY s.arrival_time ASC
            """
        }
        
        return try await executeQuery(
            query,
            parameters: [dateString, stationId, stationId, dayMask, dateString, dateString],
            parseAs: TrainSchedule.self
        )
    }
    
    /// Récupère les détails d'un horaire spécifique
    func getScheduleDetails(scheduleId: Int, date: Date? = nil) async throws -> ScheduleDetail? {
        let dateString = date.map { formatDate($0) } ?? ""
        
        let query = """
        SELECT 
            s.id,
            s.train_number,
            s.train_type,
            s.rolling_stock,
            s.departure_time,
            s.arrival_time,
            s.days_mask,
            s.stops_json,
            ds.name as departure_station,
            ast.name as arrival_station,
            v.type as variant_type,
            v.delay_minutes,
            v.cause as delay_cause,
            v.mod_departure_time,
            v.mod_arrival_time,
            v.removed_stops,
            v.snapshot_modified
        FROM sillons s
        JOIN stations ds ON ds.id = s.departure_station_id
        JOIN stations ast ON ast.id = s.arrival_station_id
        LEFT JOIN schedule_daily_variants v ON v.schedule_id = s.id AND v.date = ?
        WHERE s.id = ?
        """
        
        let results: [ScheduleDetail] = try await executeQuery(
            query,
            parameters: [dateString, scheduleId],
            parseAs: ScheduleDetail.self
        )
        return results.first
    }
    
    /// Récupère les arrêts d'un horaire
    func getScheduleStops(scheduleId: Int) async throws -> [StopInfo] {
        let query = """
        SELECT 
            st.stop_order,
            s.name as station_name,
            st.arrival_time,
            st.departure_time,
            CASE
                WHEN st.arrival_time IS NULL OR st.departure_time IS NULL THEN NULL
                ELSE GREATEST(0, (TIME_TO_SEC(st.departure_time) - TIME_TO_SEC(st.arrival_time)) DIV 60)
            END as dwell_minutes,
            p.platform
        FROM schedule_stops st
        JOIN stations s ON s.id = st.station_id
        LEFT JOIN schedule_platforms p ON p.schedule_id = st.schedule_id AND p.station_id = st.station_id
        WHERE st.schedule_id = ?
        ORDER BY st.stop_order ASC
        """
        
        return try await executeQuery(query, parameters: [scheduleId], parseAs: StopInfo.self)
    }
    
    // MARK: - Lignes
    
    /// Récupère toutes les lignes
    func fetchLines() async throws -> [Line] {
        let query = """
        SELECT 
            l.id,
            l.code,
            l.depart_station_id,
            l.arrivee_station_id,
            ds.name as depart_station_name,
            ast.name as arrivee_station_name
        FROM `lines` l
        JOIN stations ds ON ds.id = l.depart_station_id
        JOIN stations ast ON ast.id = l.arrivee_station_id
        ORDER BY l.code ASC
        """
        
        return try await executeQuery(query, parseAs: Line.self)
    }
    
    // MARK: - Utilitaires
    
    private func dayOfWeekToBitmask(_ dayOfWeek: Int) -> Int {
        // Calendar.weekday: 1=Dimanche, 2=Lundi, ..., 7=Samedi
        // Bitmask: bit0=Lundi, bit1=Mardi, ..., bit6=Dimanche
        switch dayOfWeek {
        case 1: return 64  // Dimanche
        case 2: return 1   // Lundi
        case 3: return 2   // Mardi
        case 4: return 4   // Mercredi
        case 5: return 8   // Jeudi
        case 6: return 16  // Vendredi
        case 7: return 32  // Samedi
        default: return 0
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Exécution de requêtes (à implémenter avec une bibliothèque MySQL)
    
    private func executeQuery<T: Decodable>(_ query: String, parameters: [Any] = [], parseAs type: T.Type) async throws -> [T] {
        // IMPORTANT: Cette méthode doit être implémentée avec une bibliothèque MySQL
        // comme MySQLNIO ou via une API REST qui communique avec MySQL
        
        // Pour l'instant, on simule avec des données de test
        print("📊 Exécution de la requête SQL:")
        print(query)
        print("Paramètres:", parameters)
        
        // Retourner des données de test
        return []
    }
}

// MARK: - Modèles de données étendus

struct StopInfo: Codable, Identifiable {
    let id = UUID()
    let stopOrder: Int
    let stationName: String
    let arrivalTime: String?
    let departureTime: String?
    let dwellMinutes: Int?
    let platform: String?
    
    enum CodingKeys: String, CodingKey {
        case stopOrder = "stop_order"
        case stationName = "station_name"
        case arrivalTime = "arrival_time"
        case departureTime = "departure_time"
        case dwellMinutes = "dwell_minutes"
        case platform
    }
}

struct ScheduleDetail: Codable, Identifiable {
    let id: Int
    let trainNumber: String?
    let trainType: String?
    let rollingStock: String?
    let departureTime: String
    let arrivalTime: String
    let daysMask: Int
    let stopsJson: String?
    let departureStation: String
    let arrivalStation: String
    let variantType: String?
    let delayMinutes: Int?
    let delayCause: String?
    let modDepartureTime: String?
    let modArrivalTime: String?
    let removedStops: String?
    let snapshotModified: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case trainNumber = "train_number"
        case trainType = "train_type"
        case rollingStock = "rolling_stock"
        case departureTime = "departure_time"
        case arrivalTime = "arrival_time"
        case daysMask = "days_mask"
        case stopsJson = "stops_json"
        case departureStation = "departure_station"
        case arrivalStation = "arrival_station"
        case variantType = "variant_type"
        case delayMinutes = "delay_minutes"
        case delayCause = "delay_cause"
        case modDepartureTime = "mod_departure_time"
        case modArrivalTime = "mod_arrival_time"
        case removedStops = "removed_stops"
        case snapshotModified = "snapshot_modified"
    }
}

struct Line: Codable, Identifiable {
    let id: Int
    let code: String?
    let departStationId: Int
    let arriveeStationId: Int
    let departStationName: String
    let arriveeStationName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case departStationId = "depart_station_id"
        case arriveeStationId = "arrivee_station_id"
        case departStationName = "depart_station_name"
        case arriveeStationName = "arrivee_station_name"
    }
}

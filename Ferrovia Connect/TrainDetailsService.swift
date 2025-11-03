//
//  TrainDetailsService.swift
//  Ferrovia Connect
//
//  Service pour récupérer les détails d'un train par son numéro
//

import Foundation
import Combine

class TrainDetailsService: ObservableObject {
    static let shared = TrainDetailsService()
    
    // URL de l'API
    private let apiBaseURL = "https://mr-patator.fr/api_train_details.php"
    private let rollingStockAPIURL = "https://mr-patator.fr/api_rolling_stock.php"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var trainDetails: TrainDetails?
    
    private init() {}
    
    // MARK: - Modèles de réponse API
    
    private struct APIResponse<T: Decodable>: Decodable {
        let success: Bool
        let data: T?
        let error: String?
    }
    
    /// Récupère les détails complets d'un train par son numéro
    func getTrainDetails(trainNumber: String, date: Date = Date()) async throws -> TrainDetails {
        // Formater la date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        // Construire l'URL avec les paramètres
        guard var urlComponents = URLComponents(string: apiBaseURL) else {
            throw TrainDetailsError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "getTrainDetails"),
            URLQueryItem(name: "trainNumber", value: trainNumber),
            URLQueryItem(name: "date", value: dateString)
        ]
        
        guard let url = urlComponents.url else {
            throw TrainDetailsError.invalidURL
        }
        
        print("📡 Requête détails train: \(url.absoluteString)")
        
        // Effectuer la requête HTTP
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrainDetailsError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            throw TrainDetailsError.trainNotFound
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TrainDetailsError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Décoder la réponse JSON
        let apiResponse = try JSONDecoder().decode(APIResponse<TrainDetails>.self, from: data)
        
        if apiResponse.success, var trainDetails = apiResponse.data {
            print("✅ Détails train récupérés: \(trainDetails.trainNumber ?? "")")
            
            // Récupérer les informations du matériel roulant si disponible
            if let rollingStock = trainDetails.rollingStock, !rollingStock.isEmpty {
                do {
                    let rollingStockInfo = try await getRollingStockInfo(serialNumber: rollingStock)
                    trainDetails.rollingStockInfo = rollingStockInfo
                    print("✅ Matériel roulant récupéré: \(rollingStockInfo.name)")
                } catch {
                    print("⚠️ Impossible de récupérer les infos du matériel roulant: \(error.localizedDescription)")
                    // Continue sans les infos du matériel roulant
                }
            }
            
            return trainDetails
        } else {
            throw TrainDetailsError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }
    
    /// Récupère les informations du matériel roulant par son numéro de série
    func getRollingStockInfo(serialNumber: String) async throws -> RollingStockInfo {
        guard var urlComponents = URLComponents(string: rollingStockAPIURL) else {
            throw TrainDetailsError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "getRollingStock"),
            URLQueryItem(name: "serialNumber", value: serialNumber)
        ]
        
        guard let url = urlComponents.url else {
            throw TrainDetailsError.invalidURL
        }
        
        print("📡 Requête matériel roulant: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrainDetailsError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            throw TrainDetailsError.serverError(message: "Matériel roulant non trouvé")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TrainDetailsError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<RollingStockInfo>.self, from: data)
        
        if apiResponse.success, let rollingStockInfo = apiResponse.data {
            return rollingStockInfo
        } else {
            throw TrainDetailsError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }
    
    /// Récupère les détails complets d'un train par son numéro
    func fetchDetails(for trainNumber: String) {
        self.isLoading = true
        self.errorMessage = nil
        Task {
            do {
                let details = try await getTrainDetails(trainNumber: trainNumber)
                DispatchQueue.main.async {
                    self.trainDetails = details
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Modèle de données

struct TrainDetails: Codable, Identifiable {
    let id: Int
    let trainNumber: String?
    let trainType: String?
    let rollingStock: String?
    let departureTime: String
    let arrivalTime: String
    let departureStation: String
    let arrivalStation: String
    let departurePlatform: String?
    let arrivalPlatform: String?
    let daysMask: Int
    let stopsJson: String?
    let stops: [TrainStop]
    
    // Variantes quotidiennes
    let variantType: String?
    let delayMinutes: Int?
    let delayCause: String?
    
    // Info matériel roulant (optionnel, chargé séparément)
    var rollingStockInfo: RollingStockInfo?
    
    enum CodingKeys: String, CodingKey {
        case id
        case trainNumber = "train_number"
        case trainType = "train_type"
        case rollingStock = "rolling_stock"
        case departureTime = "departure_time"
        case arrivalTime = "arrival_time"
        case departureStation = "departure_station"
        case arrivalStation = "arrival_station"
        case departurePlatform = "departure_platform"
        case arrivalPlatform = "arrival_platform"
        case daysMask = "days_mask"
        case stopsJson = "stops_json"
        case stops
        case variantType = "variant_type"
        case delayMinutes = "delay_minutes"
        case delayCause = "delay_cause"
    }
}

struct RollingStockInfo: Codable {
    let id: Int
    let name: String
    let technicalName: String
    let trainType: String
    let serialNumber: String
    let capacity: Int
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case technicalName = "technical_name"
        case trainType = "train_type"
        case serialNumber = "serial_number"
        case capacity
        case imageUrl = "image_url"
    }
}

struct TrainStop: Codable, Identifiable {
    let id = UUID()
    let stopOrder: Int
    let stationName: String
    let stationId: Int
    let arrivalTime: String?
    let departureTime: String?
    let dwellMinutes: Int?
    let platform: String?
    
    enum CodingKeys: String, CodingKey {
        case stopOrder = "stop_order"
        case stationName = "station_name"
        case stationId = "station_id"
        case arrivalTime = "arrival_time"
        case departureTime = "departure_time"
        case dwellMinutes = "dwell_minutes"
        case platform
    }
}

// MARK: - Erreurs

enum TrainDetailsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case serverError(message: String)
    case trainNotFound
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .httpError(let statusCode):
            return "Erreur HTTP: \(statusCode)"
        case .serverError(let message):
            return "Erreur serveur: \(message)"
        case .trainNotFound:
            return "Train non trouvé"
        case .decodingError:
            return "Erreur de décodage des données"
        }
    }
}

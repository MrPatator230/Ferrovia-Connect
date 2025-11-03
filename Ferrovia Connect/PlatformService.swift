//
//  PlatformService.swift
//  Ferrovia Connect
//
//  Service pour gérer les quais (platforms) via l'API
//

import Foundation
import Combine

class PlatformService: ObservableObject {
    @Published var platforms: [Platform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // URL de l'API - À MODIFIER avec l'URL de votre serveur
    private let apiBaseURL = "https://mr-patator.fr/api_quais.php"
    
    // MARK: - Modèles de réponse API
    
    private struct APIResponse<T: Decodable>: Decodable {
        let success: Bool
        let data: T?
        let error: String?
        let count: Int?
        let message: String?
    }
    
    // MARK: - Récupération des quais
    
    /// Récupère tous les quais
    func fetchAllPlatforms() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            guard let url = URL(string: "\(apiBaseURL)?action=getAllPlatforms") else {
                throw PlatformError.invalidURL
            }
            
            print("📡 Requête tous les quais: \(url.absoluteString)")
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlatformError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw PlatformError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse<[Platform]>.self, from: data)
            
            if apiResponse.success, let fetchedPlatforms = apiResponse.data {
                print("✅ Quais récupérés: \(fetchedPlatforms.count)")
                await MainActor.run {
                    platforms = fetchedPlatforms
                    isLoading = false
                }
            } else {
                throw PlatformError.serverError(message: apiResponse.error ?? "Erreur inconnue")
            }
        } catch {
            print("❌ Erreur lors de la récupération des quais: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                platforms = []
                isLoading = false
            }
        }
    }
    
    /// Récupère les quais pour un train spécifique
    func fetchPlatformsBySchedule(scheduleId: Int) async throws -> [Platform] {
        guard var urlComponents = URLComponents(string: apiBaseURL) else {
            throw PlatformError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "getPlatformsBySchedule"),
            URLQueryItem(name: "schedule_id", value: String(scheduleId))
        ]
        
        guard let url = urlComponents.url else {
            throw PlatformError.invalidURL
        }
        
        print("📡 Requête quais pour schedule \(scheduleId): \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlatformError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlatformError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<[Platform]>.self, from: data)
        
        if apiResponse.success, let fetchedPlatforms = apiResponse.data {
            return fetchedPlatforms
        } else {
            throw PlatformError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }
    
    /// Récupère les quais pour une gare spécifique
    func fetchPlatformsByStation(stationId: Int) async throws -> [Platform] {
        guard var urlComponents = URLComponents(string: apiBaseURL) else {
            throw PlatformError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "getPlatformsByStation"),
            URLQueryItem(name: "station_id", value: String(stationId))
        ]
        
        guard let url = urlComponents.url else {
            throw PlatformError.invalidURL
        }
        
        print("📡 Requête quais pour station \(stationId): \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlatformError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlatformError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<[Platform]>.self, from: data)
        
        if apiResponse.success, let fetchedPlatforms = apiResponse.data {
            return fetchedPlatforms
        } else {
            throw PlatformError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }
    
    /// Récupère un quai spécifique pour un train et une gare
    func fetchPlatform(scheduleId: Int, stationId: Int) async throws -> Platform {
        guard var urlComponents = URLComponents(string: apiBaseURL) else {
            throw PlatformError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "getPlatform"),
            URLQueryItem(name: "schedule_id", value: String(scheduleId)),
            URLQueryItem(name: "station_id", value: String(stationId))
        ]
        
        guard let url = urlComponents.url else {
            throw PlatformError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlatformError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlatformError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Platform>.self, from: data)
        
        if apiResponse.success, let platform = apiResponse.data {
            return platform
        } else {
            throw PlatformError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }
    
    // MARK: - Création, mise à jour, suppression
    
    /// Crée un nouveau quai
    func createPlatform(scheduleId: Int, stationId: Int, platform: String) async throws {
        guard let url = URL(string: apiBaseURL) else {
            throw PlatformError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "action": "createPlatform",
            "schedule_id": scheduleId,
            "station_id": stationId,
            "platform": platform
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlatformError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlatformError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Platform>.self, from: data)
        
        if !apiResponse.success {
            throw PlatformError.serverError(message: apiResponse.error ?? "Erreur lors de la création")
        }
        
        print("✅ Quai créé avec succès")
    }
    
    /// Met à jour un quai existant
    func updatePlatform(scheduleId: Int, stationId: Int, platform: String) async throws {
        guard let url = URL(string: apiBaseURL) else {
            throw PlatformError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "action": "updatePlatform",
            "schedule_id": scheduleId,
            "station_id": stationId,
            "platform": platform
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlatformError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlatformError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Platform>.self, from: data)
        
        if !apiResponse.success {
            throw PlatformError.serverError(message: apiResponse.error ?? "Erreur lors de la mise à jour")
        }
        
        print("✅ Quai mis à jour avec succès")
    }
    
    /// Supprime un quai
    func deletePlatform(scheduleId: Int, stationId: Int) async throws {
        guard var urlComponents = URLComponents(string: apiBaseURL) else {
            throw PlatformError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "deletePlatform"),
            URLQueryItem(name: "schedule_id", value: String(scheduleId)),
            URLQueryItem(name: "station_id", value: String(stationId))
        ]
        
        guard let url = urlComponents.url else {
            throw PlatformError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlatformError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlatformError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<Platform>.self, from: data)
        
        if !apiResponse.success {
            throw PlatformError.serverError(message: apiResponse.error ?? "Erreur lors de la suppression")
        }
        
        print("✅ Quai supprimé avec succès")
    }
}

// MARK: - Modèle Platform

struct Platform: Codable, Identifiable {
    let id: Int
    let scheduleId: Int
    let stationId: Int
    let platform: String
    let trainNumber: String?
    let stationName: String?
    let departureTime: String?
    let arrivalTime: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case scheduleId = "schedule_id"
        case stationId = "station_id"
        case platform
        case trainNumber = "train_number"
        case stationName = "station_name"
        case departureTime = "departure_time"
        case arrivalTime = "arrival_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Erreurs

enum PlatformError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case serverError(message: String)
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
        case .decodingError:
            return "Erreur de décodage des données"
        }
    }
}

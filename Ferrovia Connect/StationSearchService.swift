//
//  StationSearchService.swift
//  Ferrovia Connect
//
//  Service optimisé pour la recherche de gares basé sur le schéma SQL horaires
//

import Foundation

class StationSearchService {
    static let shared = StationSearchService()
    
    // URL de l'API - À MODIFIER avec l'URL de votre serveur où se trouve api_stations.php
    private let apiBaseURL = "https://mr-patator.fr/api_stations.php"
    
    private init() {}
    
    // MARK: - Modèles de réponse API
    
    private struct APIResponse<T: Decodable>: Decodable {
        let success: Bool
        let data: T?
        let error: String?
        let count: Int?
        let query: String?
    }
    
    // MARK: - Méthodes publiques
    
    /// Recherche de stations basée sur le schéma SQL horaires
    /// Utilise les colonnes: id, name, slug, region
    func searchStations(query: String) async throws -> [Station] {
        guard !query.isEmpty else {
            return try await fetchAllStations()
        }
        
        // Construire l'URL avec les paramètres
        guard var urlComponents = URLComponents(string: apiBaseURL) else {
            throw StationSearchError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "searchStations"),
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let url = urlComponents.url else {
            throw StationSearchError.invalidURL
        }
        
        // Effectuer la requête HTTP
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StationSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StationSearchError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Décoder la réponse JSON
        let apiResponse = try JSONDecoder().decode(APIResponse<[Station]>.self, from: data)
        
        if apiResponse.success, let stations = apiResponse.data {
            print("✅ Recherche '\(query)': \(stations.count) gare(s) trouvée(s)")
            return stations
        } else {
            throw StationSearchError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }
    
    /// Récupère toutes les stations (pour affichage initial)
    func fetchAllStations() async throws -> [Station] {
        guard let url = URL(string: "\(apiBaseURL)?action=getAllStations") else {
            throw StationSearchError.invalidURL
        }
        
        // Effectuer la requête HTTP
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StationSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StationSearchError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Décoder la réponse JSON
        let apiResponse = try JSONDecoder().decode(APIResponse<[Station]>.self, from: data)
        
        if apiResponse.success, let stations = apiResponse.data {
            print("✅ Récupération de toutes les stations: \(stations.count) gare(s)")
            return stations
        } else {
            throw StationSearchError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }
    
    /// Récupère une station par ID
    func getStationById(id: Int) async throws -> Station? {
        guard let url = URL(string: "\(apiBaseURL)?action=getStation&id=\(id)") else {
            throw StationSearchError.invalidURL
        }
        
        // Effectuer la requête HTTP
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StationSearchError.invalidResponse
        }
        
        // Si station non trouvée, retourner nil
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StationSearchError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Décoder la réponse JSON
        let apiResponse = try JSONDecoder().decode(APIResponse<Station>.self, from: data)
        
        if apiResponse.success {
            return apiResponse.data
        } else {
            throw StationSearchError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }
    
    /// Recherche de stations par région
    func searchStationsByRegion(region: String) async throws -> [Station] {
        // Récupérer toutes les stations et filtrer par région localement
        let allStations = try await fetchAllStations()
        return allStations.filter { $0.region == region }
    }
}

// MARK: - Erreurs

enum StationSearchError: LocalizedError {
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

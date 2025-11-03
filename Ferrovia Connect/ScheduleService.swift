//
//  ScheduleService.swift
//  Ferrovia Connect
//
//  Service pour gérer les horaires de trains via requêtes SQL
//

import Foundation
import Combine

class ScheduleService: ObservableObject {
    @Published var schedules: [TrainSchedule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // URL de l'API - À MODIFIER avec l'URL de votre serveur où se trouve api_schedules.php
    private let apiBaseURL = "https://mr-patator.fr/api_schedules.php"
    
    // MARK: - Modèles de réponse API
    
    private struct APIResponse<T: Decodable>: Decodable {
        let success: Bool
        let data: T?
        let error: String?
        let count: Int?
    }
    
    /// Récupère les horaires pour une gare donnée depuis la BDD MySQL
    func fetchSchedulesForStation(stationId: Int, date: Date = Date(), isDeparture: Bool = true) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Formater la date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            
            // Construire l'URL avec les paramètres
            guard var urlComponents = URLComponents(string: apiBaseURL) else {
                throw ScheduleError.invalidURL
            }
            
            urlComponents.queryItems = [
                URLQueryItem(name: "action", value: "getSchedules"),
                URLQueryItem(name: "stationId", value: String(stationId)),
                URLQueryItem(name: "date", value: dateString),
                URLQueryItem(name: "isDeparture", value: isDeparture ? "true" : "false")
            ]
            
            guard let url = urlComponents.url else {
                throw ScheduleError.invalidURL
            }
            
            print("📡 Requête horaires: \(url.absoluteString)")
            
            // Effectuer la requête HTTP
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ScheduleError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw ScheduleError.httpError(statusCode: httpResponse.statusCode)
            }

            // Debug: print raw JSON response for troubleshooting
            if let raw = String(data: data, encoding: .utf8) {
                print("📥 API raw response:\n\(raw)")
            } else {
                print("📥 API returned non-UTF8 data")
            }

            // Décoder la réponse JSON
            let apiResponse = try JSONDecoder().decode(APIResponse<[TrainSchedule]>.self, from: data)

            if apiResponse.success, let fetchedSchedules = apiResponse.data {
                print("✅ Horaires récupérés: \(fetchedSchedules.count) train(s)")
                await MainActor.run {
                    schedules = fetchedSchedules
                    isLoading = false
                }
            } else {
                throw ScheduleError.serverError(message: apiResponse.error ?? "Erreur inconnue")
            }
        } catch {
            print("❌ Erreur lors de la récupération des horaires: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                schedules = []
                isLoading = false
            }
        }
    }
    
    /// Récupère les horaires pour une gare donnée depuis la BDD MySQL (retourne les données sans modifier l'état interne)
    func fetchSchedulesForStationRaw(stationId: Int, date: Date = Date(), isDeparture: Bool = true) async throws -> [TrainSchedule] {
        // Formater la date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        // Construire l'URL avec les paramètres
        guard var urlComponents = URLComponents(string: apiBaseURL) else {
            throw ScheduleError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "getSchedules"),
            URLQueryItem(name: "stationId", value: String(stationId)),
            URLQueryItem(name: "date", value: dateString),
            URLQueryItem(name: "isDeparture", value: isDeparture ? "true" : "false")
        ]

        guard let url = urlComponents.url else {
            throw ScheduleError.invalidURL
        }

        print("📡 (raw) Requête horaires: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScheduleError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ScheduleError.httpError(statusCode: httpResponse.statusCode)
        }

        // Debug: print raw JSON response for troubleshooting
        if let raw = String(data: data, encoding: .utf8) {
            print("📥 (raw) API raw response:\n\(raw)")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<[TrainSchedule]>.self, from: data)

        if apiResponse.success, let fetchedSchedules = apiResponse.data {
            return fetchedSchedules
        } else {
            throw ScheduleError.serverError(message: apiResponse.error ?? "Erreur inconnue")
        }
    }

    /// Récupère les horaires pour les départs et les arrivées d'une gare donnée
    func fetchSchedulesForStationBoth(stationId: Int, date: Date = Date()) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            async let departures = fetchSchedulesForStationRaw(stationId: stationId, date: date, isDeparture: true)
            async let arrivals = fetchSchedulesForStationRaw(stationId: stationId, date: date, isDeparture: false)

            let (fetchedDepartures, fetchedArrivals) = try await (departures, arrivals)

            print("✅ Départs récupérés: \(fetchedDepartures.count) train(s)")
            print("✅ Arrivées récupérées: \(fetchedArrivals.count) train(s)")

            await MainActor.run {
                schedules = fetchedDepartures + fetchedArrivals
                isLoading = false
            }
        } catch {
            print("❌ Erreur lors de la récupération des horaires: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                schedules = []
                isLoading = false
            }
        }
    }
}

// MARK: - Erreurs

enum ScheduleError: LocalizedError {
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

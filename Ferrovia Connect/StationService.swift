//
//  StationService.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import Foundation
import Combine

class StationService: ObservableObject {
    @Published var stations: [Station] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var databaseService: DatabaseService {
        DatabaseService.shared
    }
    
    private var searchService: StationSearchService {
        StationSearchService.shared
    }
    
    func fetchStations() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Utiliser le service de recherche optimisé basé sur le schéma SQL
        do {
            let fetchedStations = try await searchService.fetchAllStations()
            await MainActor.run {
                stations = fetchedStations
                isLoading = false
            }
        } catch {
            print("❌ Erreur lors de la récupération des stations: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    // ...existing code...
    
    func searchStations(query: String) -> [Station] {
        guard !query.isEmpty else { return [] }
        
        // Utiliser la recherche locale optimisée basée sur le schéma SQL
        // Cette logique reproduit le comportement de la requête SQL avec slug indexé
        let normalizedQuery = query.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "\"", with: "")
        
        return stations.filter { station in
            let nameLower = station.name.lowercased()
            let slugLower = station.slug?.lowercased() ?? ""
            let queryLower = query.lowercased()
            
            // Recherche dans le nom ou le slug (comme dans la requête SQL)
            return nameLower.contains(queryLower) ||
                   slugLower.contains(normalizedQuery) ||
                   nameLower.hasPrefix(queryLower)
        }.sorted { station1, station2 in
            let name1 = station1.name.lowercased()
            let name2 = station2.name.lowercased()
            let queryLower = query.lowercased()
            let slug1 = station1.slug?.lowercased() ?? ""
            let slug2 = station2.slug?.lowercased() ?? ""
            
            // Ordre de priorité (comme dans la requête SQL ORDER BY)
            // 1. Correspondance exacte du nom
            if name1 == queryLower { return true }
            if name2 == queryLower { return false }
            
            // 2. Correspondance exacte du slug
            if slug1 == normalizedQuery { return true }
            if slug2 == normalizedQuery { return false }
            
            // 3. Commence par la recherche
            let starts1 = name1.hasPrefix(queryLower)
            let starts2 = name2.hasPrefix(queryLower)
            
            if starts1 && !starts2 { return true }
            if !starts1 && starts2 { return false }
            
            // 4. Ordre alphabétique
            return station1.name < station2.name
        }
    }
    
    /// Recherche asynchrone des stations via SQL (pour usage futur)
    func searchStationsAsync(query: String) async -> [Station] {
        guard !query.isEmpty else { return [] }
        
        do {
            // Utiliser le service de recherche optimisé
            return try await searchService.searchStations(query: query)
        } catch {
            print("❌ Erreur lors de la recherche de stations: \(error.localizedDescription)")
            // Fallback sur la recherche locale
            return searchStations(query: query)
        }
    }
    
    /// Récupère une station par ID
    func getStation(id: Int) async -> Station? {
        do {
            return try await searchService.getStationById(id: id)
        } catch {
            print("❌ Erreur lors de la récupération de la station: \(error.localizedDescription)")
            return stations.first { $0.id == id }
        }
    }
}

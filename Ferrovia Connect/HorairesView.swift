//
//  HorairesView.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import SwiftUI

struct HorairesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @StateObject private var stationService = StationService()
    @State private var filteredStations: [Station] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.13, blue: 0.18)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header avec bouton retour
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Horaires en gare")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Bouton de rafraîchissement
                        Button(action: {
                            Task {
                                await stationService.fetchStations()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    // Search Bar
                    HStack {
                        TextField("Rechercher une gare, un arrêt...", text: $searchText)
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                            .onChange(of: searchText) {
                                // Recherche en temps réel dans la base de données
                                Task {
                                    await performSearch(query: searchText)
                                }
                            }
                        
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 0.4, green: 0.6, blue: 0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(30)
                    .padding(.horizontal)
                    
                    // Contenu principal
                    if stationService.isLoading || isSearching {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Spacer()
                    } else if !searchText.isEmpty && !filteredStations.isEmpty {
                        // Liste des résultats de recherche
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(filteredStations) { station in
                                    NavigationLink(destination: StationDetailsView(station: station)
                                        .navigationBarBackButtonHidden(true)) {
                                        HStack {
                                            Image(systemName: "building.2")
                                                .font(.system(size: 20))
                                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
                                            
                                            Text(station.name)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color(red: 0.15, green: 0.17, blue: 0.23))
                                    }
                                    
                                    if station.id != filteredStations.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                    } else if !searchText.isEmpty && filteredStations.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Aucune gare trouvée")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    } else {
                        Spacer()
                        
                        // Train illustration (contenu par défaut)
                        VStack(spacing: 40) {
                            Image(systemName: "tram.fill")
                                .font(.system(size: 120))
                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
                                .opacity(0.3)
                            
                            VStack(alignment: .leading, spacing: 30) {
                                Text("Consultez les horaires de tous les trains et transports en commun")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 24) {
                                    HStack(alignment: .top, spacing: 16) {
                                        Image(systemName: "building.2")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .frame(width: 40)
                                        
                                        Text("Recherchez la gare, la station ou l'arrêt qui vous intéresse.")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    HStack(alignment: .top, spacing: 16) {
                                        Image(systemName: "arrow.triangle.branch")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .frame(width: 40)
                                        
                                        Text("Retrouvez les horaires de tous les trains mais aussi des bus, du tramway, du métro...")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    HStack(alignment: .top, spacing: 16) {
                                        Image(systemName: "tram.fill.tunnel")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .frame(width: 40)
                                        
                                        Text("Trains grandes lignes : choisissez d'afficher les trains au départ ou à l'arrivée de la gare.")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 40)
                        
                        Spacer()
                    }
                }
                .task {
                    await stationService.fetchStations()
                }
            }
        }
    }
    
    // MARK: - Fonctions de recherche
    
    /// Effectue une recherche asynchrone dans la base de données
    private func performSearch(query: String) async {
        // Annuler si la recherche est vide
        guard !query.isEmpty else {
            await MainActor.run {
                filteredStations = []
                isSearching = false
            }
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        // Petite pause pour éviter trop de requêtes (debouncing simple)
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 secondes
        
        // Vérifier que le texte n'a pas changé entre-temps
        guard query == searchText else { return }
        
        // Effectuer la recherche dans la base de données
        let results = await stationService.searchStationsAsync(query: query)
        
        await MainActor.run {
            filteredStations = results
            isSearching = false
        }
    }
}

#Preview {
    HorairesView()
        .environmentObject(SavedTimetablesManager())
}

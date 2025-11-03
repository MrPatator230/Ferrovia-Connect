//
//  HomeView.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var savedTimetablesManager: SavedTimetablesManager
    @State private var searchText = ""
    @State private var showHoraires = false
    @State private var navigateToTrainDetails = false
    @State private var selectedTrainNumber = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.13, blue: 0.18)
                    .ignoresSafeArea()

                ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Text("Bonjour !")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Où souhaitez-vous aller ?", text: $searchText)
                            .foregroundColor(.black)
                            .onSubmit {
                                handleSearch()
                            }

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }

                        Image(systemName: "mic.fill")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(25)
                    .padding(.horizontal)

                    // Services Grid
                    VStack(spacing: 0) {
                        // First Row
                        HStack(spacing: 1) {
                            NavigationLink {
                                TrainsSearchView()
                                    .navigationBarBackButtonHidden(true)
                            } label: {
                                ServiceButton(iconName: "tram.fill", title: "Trains (DEV)")
                            }
                            Color(red: 0.2, green: 0.22, blue: 0.28).frame(width: 1)
                            Button(action: {}) {
                                ServiceButton(iconName: "creditcard.fill", title: "Titres urbains et\nrégionaux (INACTIF)")
                            }
                            Color(red: 0.2, green: 0.22, blue: 0.28).frame(width: 1)
                            NavigationLink {
                                HorairesView()
                                    .navigationBarBackButtonHidden(true)
                            } label: {
                                ServiceButton(iconName: "clock", title: "Horaires")
                            }
                            Color(red: 0.2, green: 0.22, blue: 0.28).frame(width: 1)
                            NavigationLink {
                                TrafficInfoView()
                                    .navigationBarBackButtonHidden(true)
                            } label: {
                                ServiceButton(iconName: "info.circle", title: "Info trafic (DEV)")
                            }
                        }

                        Color(red: 0.2, green: 0.22, blue: 0.28).frame(height: 1)

                        // Second Row
                        HStack(spacing: 1) {
                            Button(action: {}) {
                                ServiceButton(iconName: "percent", title: "Cartes de\nréduction (INACTIF)")
                            }
                            Color(red: 0.2, green: 0.22, blue: 0.28).frame(width: 1)
                            Button(action: {}) {
                                ServiceButton(iconName: "car.fill", title: "Location de\nvoiture(INACTIF)", hasExternalLink: true)
                            }
                            Color(red: 0.2, green: 0.22, blue: 0.28).frame(width: 1)
                            Button(action: {}) {
                                ServiceButton(iconName: "bed.double.fill", title: "Hôtels (INACTIF)", hasExternalLink: true)
                            }
                            Color(red: 0.2, green: 0.22, blue: 0.28).frame(width: 1)
                            Button(action: {}) {
                                ServiceButton(iconName: "square.grid.2x2", title: "+ de services (INACTIF)")
                            }
                        }
                    }
                    .background(Color(red: 0.15, green: 0.17, blue: 0.23))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Utile au quotidien
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Utile au quotidien")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
                            Text("Rechercher un trajet à enregistrer")
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
                            }
                        }
                        .padding()
                        .background(Color(red: 0.15, green: 0.17, blue: 0.23))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Horaires enregistrés
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Horaires enregistrés")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        if savedTimetablesManager.items.isEmpty {
                            VStack {
                                Text("Aucun tableau enregistré")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.15, green: 0.17, blue: 0.23))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            // Horizontal scrollable cards for each saved timetable
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(savedTimetablesManager.items) { saved in
                                        VStack(spacing: 0) {
                                            // Header (station name + type + delete)
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(saved.stationName)
                                                        .font(.system(size: 18, weight: .semibold))
                                                        .foregroundColor(.white)
                                                    Text(saved.isDeparture ? "Départs" : "Arrivées")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white.opacity(0.7))
                                                }

                                                Spacer()

                                                Button(action: {
                                                    savedTimetablesManager.remove(saved)
                                                }) {
                                                    Image(systemName: "trash")
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding()
                                            .frame(height: 64)
                                            // Utiliser le même fond que les lignes de `StationDetailsView`
                                            .background(Color(red: 0.12, green: 0.14, blue: 0.19))

                                            // Card body using ScheduleRowView (same design as station details)
                                            VStack(spacing: 0) {
                                                ForEach(Array(saved.schedules.enumerated()), id: \.offset) { index, schedule in
                                                    NavigationLink(destination: TrainDetailsView(trainNumber: schedule.trainNumber ?? "")
                                                        .navigationBarBackButtonHidden(true)) {
                                                        // Create a lightweight Station so ScheduleRowView can decide about platform display.
                                                        let previewStation = Station(id: saved.stationId, name: saved.stationName)
                                                        ScheduleRowView(schedule: schedule, isDeparture: saved.isDeparture, station: previewStation, scheduleDate: Date(), isTomorrow: false)
                                                            .padding(.vertical, 8)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())

                                                    if index < saved.schedules.count - 1 {
                                                        SeparatorRow(dotted: false)
                                                    }
                                                }
                                            }
                                            .background(Color(red: 0.12, green: 0.14, blue: 0.19))
                                        }
                                        .frame(width: 320)
                                        .background(Color(red: 0.12, green: 0.14, blue: 0.19))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        .padding(.vertical)
                                        .padding(.leading, savedTimetablesManager.items.first?.id == saved.id ? 16 : 0)
                                        .padding(.trailing, savedTimetablesManager.items.last?.id == saved.id ? 16 : 0)
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
            }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToTrainDetails) {
                TrainDetailsView(trainNumber: selectedTrainNumber)
            }
        }
    }

    // MARK: - Fonctions

    /// Détecte si la recherche est un numéro de train et navigue vers les détails
    private func handleSearch() {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)

        // Vérifier si c'est un numéro de train (6 chiffres typiquement)
        if trimmedSearch.count >= 5 && trimmedSearch.allSatisfy({ $0.isNumber }) {
            selectedTrainNumber = trimmedSearch
            navigateToTrainDetails = true
            searchText = "" // Nettoyer la barre de recherche
        } else {
            // Si ce n'est pas un numéro de train, on peut gérer d'autres types de recherche ici
            print("Recherche: \(trimmedSearch)")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SavedTimetablesManager())
}

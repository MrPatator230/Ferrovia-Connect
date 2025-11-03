import SwiftUI

struct StationTimesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var searchResults: [Station] = []
    @State private var isSearching = false
    @State private var selectedStation: Station?
    @State private var navigateToDetails = false

    // Same palette as ContentView
    let background = Color(red: 15/255, green: 22/255, blue: 38/255)
    let cardBackground = Color(red: 22/255, green: 29/255, blue: 44/255)
    let accentCyan = Color(red: 92/255, green: 203/255, blue: 219/255)

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Top bar: back button + centered title
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(cardBackground)
                                .frame(width: 48, height: 48)
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Text("Horaires en gare")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, -12)

                // Large search bar with circular cyan search button
                HStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Rechercher une gare, un arrêt...", text: $query)
                            .foregroundColor(.black)
                            .onChange(of: query) { newValue in
                                if newValue.count >= 2 {
                                    Task {
                                        await searchStations()
                                    }
                                } else if newValue.isEmpty {
                                    searchResults = []
                                }
                            }
                    }
                    .padding(.vertical, 16)
                    .padding(.leading, 20)

                    Button(action: {
                        Task {
                            await searchStations()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(accentCyan.opacity(0.98))
                                .frame(width: 64, height: 64)
                            Image(systemName: isSearching ? "hourglass" : "magnifyingglass")
                                .foregroundColor(.black)
                                .font(.title3)
                        }
                        .padding(8)
                    }
                    .disabled(isSearching)
                }
                .background(Color.white.opacity(0.95))
                .cornerRadius(36)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 6)

                // Show search results or empty state
                if !searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(searchResults) { station in
                                Button(action: {
                                    selectedStation = station
                                    navigateToDetails = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "building.2.fill")
                                            .foregroundColor(accentCyan)
                                            .font(.title2)
                                            .frame(width: 40)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(station.name)
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .medium))
                                            
                                            if let region = station.region {
                                                Text(region)
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .font(.system(size: 14))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 14))
                                    }
                                    .padding()
                                    .background(cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if isSearching {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentCyan))
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    // Empty state
                    Spacer().frame(height: 18)

                    Image(systemName: "train.side.front.car.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .foregroundColor(accentCyan)
                        .padding(.horizontal, 24)
                        .opacity(0.9)

                    // Title and description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Consultez les horaires de tous les trains et transports en commun")
                            .foregroundColor(.white)
                            .font(.title3.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentCyan, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "house")
                                        .foregroundColor(.white)
                                }

                                Text("Recherchez la gare, la station ou l'arrêt qui vous intéresse.")
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentCyan, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "arrow.uturn.left")
                                        .foregroundColor(.white)
                                }

                                Text("Retrouvez les horaires de tous les trains mais aussi des bus, du tramway, du métro...")
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentCyan, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "train.side.front.car")
                                        .foregroundColor(.white)
                                }

                                Text("Trains grandes lignes : choisissez d'afficher les trains au départ ou à l'arrivée de la gare.")
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .font(.body)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .padding(.top, 8)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToDetails) {
            if let station = selectedStation {
                StationDetailsView(station: station)
            }
        }
    }
    
    // MARK: - Search Functions
    
    func searchStations() async {
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
            }
            return
        }

        await MainActor.run {
            isSearching = true
        }

        do {
            let results = try await StationSearchService.shared.searchStations(query: query)

            // Fetch schedules for each station in the results
            let stationsWithSchedules = try await withThrowingTaskGroup(of: (Station, [TrainSchedule]).self) { group in
                for station in results {
                    group.addTask {
                        let schedules = try await ScheduleService().fetchSchedulesForStationRaw(stationId: station.id, date: Date(), isDeparture: true)
                        return (station, schedules)
                    }
                }

                var enrichedResults: [(Station, [TrainSchedule])] = []
                for try await result in group {
                    enrichedResults.append(result)
                }
                return enrichedResults
            }

            await MainActor.run {
                searchResults = stationsWithSchedules.map { $0.0 } // Update searchResults with stations only
                // Optionally, store schedules in a separate dictionary if needed for display
                isSearching = false
            }
        } catch {
            print("❌ Erreur de recherche: \(error.localizedDescription)")
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
        }
    }
}

struct StationTimesView_Previews: PreviewProvider {
    static var previews: some View {
        StationTimesView()
            .previewDevice("iPhone 14 Pro")
    }
}

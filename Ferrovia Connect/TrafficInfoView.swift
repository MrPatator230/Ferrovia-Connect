import SwiftUI

struct TrafficInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTabIndex: Int = 1 // Par région selected by default
    @State private var selectedRegion = "Bourgogne-Franche-Comté"

    // Full regions list for "Par région" (used by the dropdown/menu)
    private let regions = [
        "Auvergne-Rhône-Alpes",
        "Bourgogne-Franche-Comté",
        "Bretagne",
        "Centre-Val de Loire",
        "Corse",
        "Grand Est",
        "Hauts-de-France",
        "Île-de-France",
        "Normandie",
        "Nouvelle-Aquitaine",
        "Occitanie",
        "Pays de la Loire",
        "Provence-Alpes-Côte d'Azur",
        "Guadeloupe",
        "Martinique",
        "Guyane",
        "La Réunion",
        "Mayotte"
    ]

    private let tabs = ["Île-de-France", "Par région", "Grandes lignes"]

    // Data loaded from API
    @State private var items: [TrafficInfoItem] = []
    @State private var isLoading = false
    @State private var loadError: String? = nil
    @State private var rawResponse: String? = nil
    @State private var showRawSheet: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.11)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                // Tabs
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                            Button(action: {
                                withAnimation { selectedTabIndex = index }
                                // If switching away from "Par région" we may clear or reload
                                if index == 1 { loadForSelectedRegion() }
                            }) {
                                Text(title)
                                    .font(.system(size: 16, weight: selectedTabIndex == index ? .semibold : .regular))
                                    .foregroundColor(selectedTabIndex == index ? Color(red: 0.2, green: 0.7, blue: 0.9) : Color.white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)

                    // Indicator
                    HStack(spacing: 0) {
                        Capsule()
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 3)
                            .overlay(
                                GeometryReader { geo in
                                    let total = geo.size.width
                                    let segment = total / CGFloat(tabs.count)
                                    // indicator roughly 60% of segment width, min 28 for the look
                                    let indicatorWidth = max(28, segment * 0.6)
                                    Capsule()
                                        .fill(Color(red: 0.2, green: 0.7, blue: 0.9))
                                        .frame(width: indicatorWidth, height: 3)
                                        .offset(x: segment * CGFloat(selectedTabIndex) + (segment - indicatorWidth) / 2)
                                        .animation(.easeInOut(duration: 0.22), value: selectedTabIndex)
                                }
                            )
                            .padding(.horizontal, 22)
                    }
                }
                .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Region selector (only for "Par région")
                        if selectedTabIndex == 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Région")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.leading, 16)

                                // Menu styled to look like the screenshot
                                Menu {
                                    ForEach(regions, id: \.self) { region in
                                        Button(action: {
                                            selectedRegion = region
                                            loadForSelectedRegion()
                                        }) {
                                            Text(region)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedRegion)
                                            .foregroundColor(.white)
                                            .font(.system(size: 16))
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.9))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)

                            // Plans button
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "map")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .padding(.leading, 16)

                                    Text("Plans des réseaux et lignes")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.trailing, 16)
                                }
                                .padding(.vertical, 18)
                                .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                                .cornerRadius(14)
                                .padding(.horizontal)
                            }
                        }

                        // Content list (for region or other tabs we can adapt later)
                        VStack(spacing: 18) {
                            if isLoading {
                                HStack { Spacer(); ProgressView().tint(Color(red: 0.2, green: 0.7, blue: 0.9)); Spacer() }
                            } else if let error = loadError {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(error)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal)

                                    HStack(spacing: 12) {
                                        Button(action: {
                                            // retry
                                            loadForSelectedRegion()
                                        }) {
                                            Text("Réessayer")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 20)
                                                .background(Color(red: 0.15, green: 0.17, blue: 0.23))
                                                .cornerRadius(10)
                                        }

                                        Button(action: {
                                            // fetch raw body and show sheet
                                            Task {
                                                do {
                                                    let raw = try await TrafficInfoService.fetchRaw(region: selectedRegion)
                                                    await MainActor.run {
                                                        rawResponse = raw
                                                        showRawSheet = true
                                                    }
                                                } catch {
                                                    await MainActor.run {
                                                        rawResponse = "Erreur lors du fetchRaw: \(error.localizedDescription)"
                                                        showRawSheet = true
                                                    }
                                                }
                                            }
                                        }) {
                                            Text("Voir la réponse brute")
                                                .font(.system(size: 15, weight: .regular))
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                             } else if items.isEmpty {
                                // Fallback static example (if nothing from API)
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange)
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "triangle.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .bold))
                                        }

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Info Travaux")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)

                                            Text("Dernière mise à jour le 16/10/2025 à 12:00")
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }

                                    Text("Le trafic sera interrompu entre Laroche et Auxerre en semaine de 9h30 à 16h30 du 17 novembre au 28 novembre.\n\nLimitations des TRAINS Mobigo et mise en place de substitution autocar entre Laroche et Auxerre.\n\nVérifiez vos horaires sur les applications habituelles.")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(6)
                                        .padding(.leading, 48)
                                }
                                .padding(.horizontal)
                            } else {
                                ForEach(items) { item in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(alignment: .top, spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.orange)
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "triangle.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 16, weight: .bold))
                                            }

                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(item.title)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.white)

                                                Text(item.updatedAt)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                        }

                                        Text(item.content)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineSpacing(6)
                                            .padding(.leading, 48)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            // initial load for default region when opening the tab
            if selectedTabIndex == 1 { loadForSelectedRegion() }
        }
        .onChange(of: selectedRegion) { _ in loadForSelectedRegion() }
        .sheet(isPresented: $showRawSheet) {
            NavigationView {
                ScrollView {
                    Text(rawResponse ?? "(vide)")
                        .padding()
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle("Réponse brute")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { showRawSheet = false }
                    }
                }
            }
        }
 }

 private func loadForSelectedRegion() {
        guard selectedTabIndex == 1 else { return }
        isLoading = true
        loadError = nil
        items = []

        Task {
            do {
                let fetched = try await TrafficInfoService.fetch(region: selectedRegion)
                await MainActor.run {
                    items = fetched
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Show the actual error message from the service to help debugging
                    loadError = error.localizedDescription
                     isLoading = false
                }
            }
        }
    }

 private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.11))
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Text("Infos trafic et réseaux")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // placeholder for right-side icon to keep title centered
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 44)
    }
}

struct TrafficInfoView_Previews: PreviewProvider {
    static var previews: some View {
        TrafficInfoView()
            .previewDevice("iPhone 14 Pro")
    }
}

//
//  StationDetailsView.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import SwiftUI
import Combine

struct StationDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var scheduleService = ScheduleService()
    @EnvironmentObject var savedTimetablesManager: SavedTimetablesManager

    // Provide an explicit initializer to avoid exposing synthesized init involving property wrappers
    let station: Station

    init(dismiss: Environment<DismissAction>, station: Station) {
        self._dismiss = dismiss
        self.station = station
    }

    init(station: Station) {
        self.station = station
    }

    // Cancellable for the periodic refresh timer
    @State private var timerCancellable: AnyCancellable? = nil

    @State private var selectedDate = Date()
    @State private var departures: [TrainSchedule] = []
    @State private var arrivals: [TrainSchedule] = []
    // Annotated arrays containing the schedule plus its associated calendar date
    @State private var departuresWithDate: [(schedule: TrainSchedule, date: Date)] = []
    @State private var arrivalsWithDate: [(schedule: TrainSchedule, date: Date)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isDeparture: Bool = true
    @State private var searchText: String = ""

    // Alert for save confirmation
    @State private var showSavedAlert = false
    @State private var savedAlertMessage = ""

    // Helper to compute the exact Date (day + time) for a schedule at this station
    private func scheduledDate(for schedule: TrainSchedule, on date: Date, isDeparture: Bool) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)

        let timeString = isDeparture ? schedule.departureTime : schedule.arrivalTime
        guard let time = timeString, !time.isEmpty, time != "-" else { return nil }
        let parts = time.split(separator:":").compactMap { Int($0) }
        guard parts.count >= 1 else { return nil }
        components.hour = parts[0]
        components.minute = parts.count > 1 ? parts[1] : 0

        return calendar.date(from: components)
    }

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Regional transport button
                Button(action: {}) {
                    HStack {
                        Image(systemName: "train.side.front.car")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.12, green: 0.14, blue: 0.19))

                        Text("Grandes lignes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.12, green: 0.14, blue: 0.19))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.6, green: 0.8, blue: 0.9))
                    .cornerRadius(25)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Tabs for Departures and Arrivals
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        tabButton(title: "Départs", isSelected: isDeparture) {
                            isDeparture = true
                        }

                        tabButton(title: "Arrivées", isSelected: !isDeparture) {
                            isDeparture = false
                        }
                    }

                    // Tab indicator
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(red: 0.4, green: 0.6, blue: 0.8))
                                .frame(width: geometry.size.width / 2, height: 3)
                                .offset(x: isDeparture ? 0 : geometry.size.width / 2)
                                .animation(.easeInOut(duration: 0.3), value: isDeparture)

                            Spacer()
                        }
                    }
                    .frame(height: 3)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Search bar
                HStack(spacing: 12) {
                    HStack {
                        Text("Vers")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)

                        Text("Toutes les gares")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color(red: 0.12, green: 0.14, blue: 0.19))
                    .cornerRadius(25)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Save schedule button
                Button(action: saveCurrentTable) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))

                        Text(isDeparture ? "Enregistrer ce tableau des départs" : "Enregistrer ce tableau des arrivées")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
                    }
                    .padding(.leading, 20)
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .alert(isPresented: $showSavedAlert) {
                    Alert(title: Text("Tableau enregistré"), message: Text(savedAlertMessage), dismissButton: .default(Text("OK")))
                }

                // Schedule List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Use annotated schedule arrays for correct day separation and ordering
                            let currentSchedules = isDeparture ? departuresWithDate : arrivalsWithDate
                            // Filter out schedules whose time at this station has already passed
                            let now = Date()
                            let displaySchedules = currentSchedules.filter { pair in
                                if let sd = scheduledDate(for: pair.schedule, on: pair.date, isDeparture: isDeparture) {
                                    return sd >= now
                                }
                                return false
                            }

                            // If the first visible schedule belongs to tomorrow, show a banner like on HomeView
                            if let firstVisible = displaySchedules.first,
                               !Calendar.current.isDate(firstVisible.date, inSameDayAs: selectedDate) {
                                TomorrowBanner(isDeparture: isDeparture)
                                SeparatorRow(dotted: true, fullWidth: true)
                            }

                            ForEach(Array(displaySchedules.enumerated()), id: \.offset) { index, item in
                                let schedule = item.schedule
                                NavigationLink(destination: TrainDetailsView(trainNumber: schedule.trainNumber ?? "")
                                    .navigationBarBackButtonHidden(true)) {
                                    // Pass the annotated date so the row can decide when to show the platform
                                    ScheduleRowView(schedule: schedule, isDeparture: isDeparture, station: station, scheduleDate: item.date, isTomorrow: !Calendar.current.isDate(item.date, inSameDayAs: selectedDate))
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Vérifier si on doit afficher un séparateur (en se basant sur la liste visible)
                                if index < displaySchedules.count - 1 {
                                    // Détecter changement de jour entre l'élément courant et le suivant
                                    let nextItem = displaySchedules[index + 1]
                                    if !Calendar.current.isDate(item.date, inSameDayAs: nextItem.date) {
                                         // Séparateur en pointillé pour le changement de jour (plein largeur)
                                           SeparatorRow(dotted: true, fullWidth: true)
                                    } else {
                                         // Séparateur normal
                                           SeparatorRow(dotted: false)
                                     }
                                }
                              }
                         }
                         .background(Color(red: 0.12, green: 0.14, blue: 0.19))
                         .cornerRadius(12)
                         .padding(.horizontal)
                         .padding(.top, 20)
                     }
                     .refreshable {
                         await fetchSchedulesForBoth()
                     }
                 }
             }
         }
         .onAppear {
             // Start a timer that refreshes schedules every 60 seconds.
             // Avoid firing if a fetch is already running (isLoading).
             timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
                 .autoconnect()
                 .sink { _ in
                     if !isLoading {
                         Task { await fetchSchedulesForBoth() }
                     }
                 }
         }
         .onDisappear {
             timerCancellable?.cancel()
             timerCancellable = nil
         }
         .task {
             await fetchSchedulesForBoth()
         }
     }

     private func fetchSchedulesForBoth() async {
        print("🔍 StationDetailsView - Fetching schedules for station: \(station.name) (ID: \(station.id))")

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        do {
            // Calculer la date du lendemain
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate

            // Récupérer les horaires du jour
            async let fetchedDeparturesToday = scheduleService.fetchSchedulesForStationRaw(stationId: station.id, date: selectedDate, isDeparture: true)
            async let fetchedArrivalsToday = scheduleService.fetchSchedulesForStationRaw(stationId: station.id, date: selectedDate, isDeparture: false)

            // Récupérer les horaires du lendemain
            async let fetchedDeparturesTomorrow = scheduleService.fetchSchedulesForStationRaw(stationId: station.id, date: tomorrow, isDeparture: true)
            async let fetchedArrivalsTomorrow = scheduleService.fetchSchedulesForStationRaw(stationId: station.id, date: tomorrow, isDeparture: false)

            let departuresToday = try await fetchedDeparturesToday
            let arrivalsToday = try await fetchedArrivalsToday
            var departuresTomorrow = try await fetchedDeparturesTomorrow
            var arrivalsTomorrow = try await fetchedArrivalsTomorrow

            print("📊 Departures tomorrow fetched: \(departuresTomorrow.count)")
            print("📊 Arrivals tomorrow fetched: \(arrivalsTomorrow.count)")
            for (index, schedule) in departuresTomorrow.enumerated() {
                print("   Tomorrow departure [\(index)]: \(schedule.departureTime ?? "nil") to \(schedule.arrivalStation)")
            }

            // Garder uniquement les horaires du lendemain qui sont tôt le matin (par ex. avant 07:00)
            func isEarlyMorningOrEqual(_ time: String) -> Bool {
                let comps = time.split(separator: ":").compactMap { Int($0) }
                guard comps.count >= 1 else { return false }
                return comps[0] < 23
            }

            // Appliquer le filtre aux listes de demain
            departuresTomorrow = departuresTomorrow.filter { schedule in
                if let t = schedule.departureTime {
                    let keep = isEarlyMorningOrEqual(t)
                    print("   Filter tomorrow departure \(t): \(keep ? "KEEP" : "REMOVE")")
                    return keep
                }
                return false
            }
            arrivalsTomorrow = arrivalsTomorrow.filter { schedule in
                if let t = schedule.arrivalTime {
                    let keep = isEarlyMorningOrEqual(t)
                    print("   Filter tomorrow arrival \(t): \(keep ? "KEEP" : "REMOVE")")
                    return keep
                }
                return false
            }

            print("📊 After early-morning filtering - Departures tomorrow: \(departuresTomorrow.count)")
            print("📊 After early-morning filtering - Arrivals tomorrow: \(arrivalsTomorrow.count)")

            // Annoter les horaires avec leur date (selectedDate ou tomorrow)
            var annotatedDepartures: [(TrainSchedule, Date)] = []
            var annotatedArrivals: [(TrainSchedule, Date)] = []
            annotatedDepartures += departuresToday.map { ($0, selectedDate) }
            annotatedDepartures += departuresTomorrow.map { ($0, tomorrow) }
            annotatedArrivals += arrivalsToday.map { ($0, selectedDate) }
            annotatedArrivals += arrivalsTomorrow.map { ($0, tomorrow) }

            // Filtrer les éléments qui n'ont pas d'heure valide (optionnel)
            annotatedDepartures = annotatedDepartures.filter { schedule, date in
                let time = schedule.departureTime ?? ""
                return !time.isEmpty && time != "-"
            }
            annotatedArrivals = annotatedArrivals.filter { schedule, date in
                let time = schedule.arrivalTime ?? ""
                return !time.isEmpty && time != "-"
            }

            // Dédupliquer les entrées annotées pour éviter les doublons visibles
            func deduplicateAnnotated(_ list: [(TrainSchedule, Date)], isDeparture: Bool) -> [(TrainSchedule, Date)] {
                var seen = Set<String>()
                var out: [(TrainSchedule, Date)] = []
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                for (schedule, date) in list {
                    let dateStr = formatter.string(from: date)
                    let train = schedule.trainNumber ?? ""
                    let time = isDeparture ? (schedule.departureTime ?? "") : (schedule.arrivalTime ?? "")
                    let key = "\(dateStr)-\(schedule.id)-\(train)-\(time)"
                    if (!seen.contains(key)) {
                        seen.insert(key)
                        out.append((schedule, date))
                    }
                }
                return out
            }

            annotatedDepartures = deduplicateAnnotated(annotatedDepartures, isDeparture: true)
            annotatedArrivals = deduplicateAnnotated(annotatedArrivals, isDeparture: false)

             // Fonction utilitaire pour obtenir un Date à partir du schedule et de sa date
             func dateFor(schedule: TrainSchedule, date: Date, isDeparture: Bool) -> Date? {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

                if isDeparture {
                    // Pour les départs, on utilise l'heure de départ
                    if let hour = Int(schedule.departureTime?.split(separator: ":").first ?? ""),
                       let minute = Int(schedule.departureTime?.split(separator: ":").last ?? "") {
                        components.hour = hour
                        components.minute = minute
                    }
                } else {
                    // Pour les arrivées, on utilise l'heure d'arrivée
                    if let hour = Int(schedule.arrivalTime?.split(separator: ":").first ?? ""),
                       let minute = Int(schedule.arrivalTime?.split(separator: ":").last ?? "") {
                        components.hour = hour
                        components.minute = minute
                    }
                }

                return calendar.date(from: components)
            }

            let sortedAnnotatedDepartures = annotatedDepartures.sorted { a, b in
                let da = dateFor(schedule: a.0, date: a.1, isDeparture: true) ?? Date.distantFuture
                let db = dateFor(schedule: b.0, date: b.1, isDeparture: true) ?? Date.distantFuture
                return da < db
            }
            let sortedAnnotatedArrivals = annotatedArrivals.sorted { a, b in
                let da = dateFor(schedule: a.0, date: a.1, isDeparture: false) ?? Date.distantFuture
                let db = dateFor(schedule: b.0, date: b.1, isDeparture: false) ?? Date.distantFuture
                return da < db
            }

            // Limiter les horaires du lendemain aux 20 premiers (préserver tous les horaires du jour)
            func limitTomorrow(_ list: [(TrainSchedule, Date)]) -> [(TrainSchedule, Date)] {
                let todayList = list.filter { Calendar.current.isDate($0.1, inSameDayAs: selectedDate) }
                let tomorrowList = list.filter { !Calendar.current.isDate($0.1, inSameDayAs: selectedDate) }
                let limitedTomorrow = Array(tomorrowList.prefix(20))
                return todayList + limitedTomorrow
            }

            let limitedSortedAnnotatedDepartures = limitTomorrow(sortedAnnotatedDepartures)
            let limitedSortedAnnotatedArrivals = limitTomorrow(sortedAnnotatedArrivals)

             await MainActor.run {
                 // Reset before assigning to avoid accumulation si la fonction est appelée plusieurs fois
                 departures = departuresToday + departuresTomorrow
                 arrivals = arrivalsToday + arrivalsTomorrow
                 departuresWithDate = []
                 arrivalsWithDate = []
                departuresWithDate = limitedSortedAnnotatedDepartures.map { (schedule: $0.0, date: $0.1) }
                arrivalsWithDate = limitedSortedAnnotatedArrivals.map { (schedule: $0.0, date: $0.1) }
             }
         } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Erreur lors de la récupération des horaires. Veuillez réessayer."
                print("❌ Error fetching schedules: \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Text(station.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button(action: {}) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .padding(.top, 40)
    }

    private func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        if isSelected {
                            Color(red: 0.4, green: 0.6, blue: 0.8)
                                .cornerRadius(25)
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Small row view for a schedule (used in the list)
struct ScheduleRowView: View {
    let schedule: TrainSchedule
    let isDeparture: Bool
    let station: Station
    let scheduleDate: Date
    let isTomorrow: Bool

    // Compute the full Date (day + time) for this schedule row
    private func scheduledDateTime() -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: scheduleDate)
        let timeString = isDeparture ? schedule.departureTime : schedule.arrivalTime
        guard let time = timeString, !time.isEmpty, time != "-" else { return nil }
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 1 else { return nil }
        components.hour = parts[0]
        components.minute = parts.count > 1 ? parts[1] : 0
        return calendar.date(from: components)
    }

    // Determine if the platform should be visible based on station type and schedule time
    private func shouldShowPlatform() -> Bool {
        guard let platform = schedule.platform, !platform.isEmpty else { return false }
        guard let schedDate = scheduledDateTime() else { return false }
        let now = Date()

        // Determine threshold: for .ville show 30 minutes before, for .urbaine show 12 hours before
        let thresholdInterval: TimeInterval
        if let type = station.stationType {
            switch type {
            case .ville:
                thresholdInterval = 30 * 60 // 30 minutes
            case .urbaine:
                thresholdInterval = 12 * 60 * 60 // 12 hours
            }
        } else {
            // Default to city behavior if unknown
            thresholdInterval = 30 * 60
        }

        // Show platform if now is within [schedDate - threshold, schedDate]
        let earliest = schedDate.addingTimeInterval(-thresholdInterval)
        return now >= earliest && now <= schedDate
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Time + optional "Demain" label
                VStack(alignment: .leading, spacing: 4) {
                    Text(isDeparture ? (schedule.departureTime ?? "-") : (schedule.arrivalTime ?? "-"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 80, alignment: .leading)

                    if isTomorrow {
                        Text("Demain")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
                            .frame(width: 80, alignment: .leading)
                    }
                }

                // Destination and train info
                VStack(alignment: .leading, spacing: 8) {
                    Text(isDeparture ? schedule.arrivalStation : schedule.departureStation)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Image(systemName: "tram.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)

                        Text(schedule.trainType ?? "TER")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        if let trainNumber = schedule.trainNumber {
                            Text(trainNumber)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                // Platform badge - only show if within the configured threshold
                if shouldShowPlatform(), let platform = schedule.platform {
                    VStack(spacing: 4) {
                        Text("Voie")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                        Text(platform)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.12, green: 0.14, blue: 0.19))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
        }
        .background(Color(red: 0.12, green: 0.14, blue: 0.19))
    }
}

// New separator view: solid or dotted with same color/padding
struct SeparatorRow: View {
    let dotted: Bool
    let fullWidth: Bool

    init(dotted: Bool, fullWidth: Bool = false) {
        self.dotted = dotted
        self.fullWidth = fullWidth
    }

    var body: some View {
        if dotted {
            if fullWidth {
                // Full width dashed line using stroke style
                Capsule()
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                // Dotted separator that visually matches the color and leading inset of the solid separator
                HStack(spacing: 6) {
                    ForEach(0..<18, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 1)
                    }
                    Spacer()
                }
                .padding(.leading, 20)
            }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.leading, 20)
        }
    }
}

// Banner shown when the displayed schedules are from tomorrow
struct TomorrowBanner: View {
    let isDeparture: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
            Text(isDeparture ? "Les prochains départs affichés sont ceux du lendemain." : "Les prochaines arrivées affichées sont celles du lendemain.")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
            Spacer()
        }
        .padding()
        .background(Color(red: 0.12, green: 0.15, blue: 0.22))
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
}

// Save current displayed schedules
extension StationDetailsView {
    private func saveCurrentTable() {
        let currentSchedules = isDeparture ? departuresWithDate : arrivalsWithDate
        let now = Date()
        // Determine visible schedules (same logic as in the list)
        let visible = currentSchedules.filter { pair in
            if let sd = scheduledDate(for: pair.schedule, on: pair.date, isDeparture: isDeparture) {
                return sd >= now
            }
            return false
        }

        let schedulesToSave = visible.map { $0.schedule }
        if schedulesToSave.isEmpty {
            savedAlertMessage = "Aucun horaire récent à enregistrer."
            showSavedAlert = true
            return
        }

        savedTimetablesManager.addSavedTimetable(stationId: station.id, stationName: station.name, isDeparture: isDeparture, schedules: schedulesToSave)
        savedAlertMessage = "Les prochains \(min(3, schedulesToSave.count)) horaires ont été enregistrés."
        showSavedAlert = true
    }
}

struct StationDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        StationDetailsView(station: Station(id: 1, name: "Auxonne", region: "Région", slug: "auxonne", stationType: .ville, latitude: nil, longitude: nil))
            .environmentObject(SavedTimetablesManager())
    }
}

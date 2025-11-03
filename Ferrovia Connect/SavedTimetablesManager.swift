import Foundation
import Combine

struct SavedTimetable: Codable, Identifiable, Equatable {
    let id: UUID
    let stationId: Int
    let stationName: String
    let isDeparture: Bool
    let savedAt: Date
    let schedules: [TrainSchedule]

    init(id: UUID = UUID(), stationId: Int, stationName: String, isDeparture: Bool, savedAt: Date = Date(), schedules: [TrainSchedule]) {
        self.id = id
        self.stationId = stationId
        self.stationName = stationName
        self.isDeparture = isDeparture
        self.savedAt = savedAt
        self.schedules = schedules
    }
}

@MainActor
final class SavedTimetablesManager: ObservableObject {
    @Published private(set) var items: [SavedTimetable] = []

    private let userDefaultsKey = "savedTimetables_v1"

    init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            items = []
            return
        }
        do {
            let decoded = try JSONDecoder().decode([SavedTimetable].self, from: data)
            items = decoded
        } catch {
            print("❌ Failed to decode saved timetables: \(error)")
            items = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("❌ Failed to encode saved timetables: \(error)")
        }
    }

    func addSavedTimetable(stationId: Int, stationName: String, isDeparture: Bool, schedules: [TrainSchedule]) {
        // store up to 3 schedules
        let toSave = Array(schedules.prefix(3))
        let item = SavedTimetable(stationId: stationId, stationName: stationName, isDeparture: isDeparture, schedules: toSave)
        items.append(item)
        persist()
    }

    func remove(_ item: SavedTimetable) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func clearAll() {
        items.removeAll()
        persist()
    }
}

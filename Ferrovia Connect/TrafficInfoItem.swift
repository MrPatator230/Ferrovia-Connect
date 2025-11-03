import Foundation

struct TrafficInfoItem: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case updatedAt = "updated_at"
    }
}

//
//  Station.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import Foundation

struct Station: Codable, Identifiable {
    let id: Int
    let name: String
    let region: String?
    let slug: String?
    let stationType: StationType?
    
    // Pour compatibilité avec les coordonnées GPS (optionnel)
    var latitude: Double?
    var longitude: Double?
    
    enum StationType: String, Codable {
        case ville = "ville"        // Gare de ville : afficher quai 30min avant
        case urbaine = "urbaine"    // Gare interurbaine : afficher quai 12h avant
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case region
        case slug
        case stationType = "station_type"
        case latitude
        case longitude
    }
    
    init(id: Int, name: String, region: String? = nil, slug: String? = nil, stationType: StationType? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.region = region
        self.slug = slug
        self.stationType = stationType
        self.latitude = latitude
        self.longitude = longitude
    }
}

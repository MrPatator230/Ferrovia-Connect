//
//  TrainSchedule.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import Foundation

struct TrainSchedule: Codable, Identifiable, Equatable {
    let id: Int
    let trainNumber: String?
    let trainType: String?
    let rollingStock: String?
    // Make departureTime/arrivalTime optional because API may return null for intermediate stops
    let departureTime: String?
    let arrivalTime: String?
    let departureStation: String
    let arrivalStation: String
    let daysMask: Int
    let stopsJson: String?
    let platform: String?

    // Variantes quotidiennes (retards, suppressions, etc.)
    let variantType: String?
    let delayMinutes: Int?
    let delayCause: String?

    enum CodingKeys: String, CodingKey {
        case id
        case trainNumber = "train_number"
        case trainType = "train_type"
        case rollingStock = "rolling_stock"
        case departureTime = "departure_time"
        case arrivalTime = "arrival_time"
        case departureStation = "departure_station"
        case arrivalStation = "arrival_station"
        case daysMask = "days_mask"
        case stopsJson = "stops_json"
        case platform
        case variantType = "variant_type"
        case delayMinutes = "delay_minutes"
        case delayCause = "delay_cause"
    }

    // Propriétés calculées pour compatibilité avec l'ancien modèle
    var time: String {
        return departureTime ?? "-"
    }

    var destination: String {
        return arrivalStation
    }

    var trainCourt: String {
        return trainType ?? "TER"
    }

    var when: String {
        if let delayMinutes = delayMinutes, delayMinutes > 0 {
            return "Retard \(delayMinutes) min"
        } else if variantType == "suppression" {
            return "Supprimé"
        } else {
            return "À l'heure"
        }
    }

    // Initialiseur pour créer des instances manuellement
    init(id: Int = 0, trainNumber: String? = nil, trainType: String? = nil,
         rollingStock: String? = nil, departureTime: String? = nil, arrivalTime: String? = nil,
         departureStation: String = "", arrivalStation: String = "", daysMask: Int = 127,
         stopsJson: String? = nil, platform: String? = nil, variantType: String? = nil,
         delayMinutes: Int? = nil, delayCause: String? = nil) {
        self.id = id
        self.trainNumber = trainNumber
        self.trainType = trainType
        self.rollingStock = rollingStock
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.departureStation = departureStation
        self.arrivalStation = arrivalStation
        self.daysMask = daysMask
        self.stopsJson = stopsJson
        self.platform = platform
        self.variantType = variantType
        self.delayMinutes = delayMinutes
        self.delayCause = delayCause
    }
}

extension TrainSchedule {
    // Retourne l'arrêt correspondant à une gare donnée (par nom)
    func stopInfo(for stationName: String) -> StopInfo? {
        guard let stopsJson = stopsJson,
              let data = stopsJson.data(using: .utf8) else { return nil }
        let stops = (try? JSONDecoder().decode([StopInfo].self, from: data)) ?? []
        return stops.first { $0.stationName.caseInsensitiveCompare(stationName) == .orderedSame }
    }
    // Retourne l'heure d'arrivée/départ pour une gare donnée
    func arrivalTime(for stationName: String) -> String? {
        if let stop = stopInfo(for: stationName) {
            return stop.arrivalTime
        }
        // fallback sur l'arrivée principale si la gare est la gare d'arrivée
        if arrivalStation.caseInsensitiveCompare(stationName) == .orderedSame {
            return arrivalTime
        }
        return nil
    }
    func departureTime(for stationName: String) -> String? {
        if let stop = stopInfo(for: stationName) {
            return stop.departureTime
        }
        // fallback sur le départ principal si la gare est la gare de départ
        if departureStation.caseInsensitiveCompare(stationName) == .orderedSame {
            return departureTime
        }
        return nil
    }
    
    // Détermine si le quai doit être affiché selon le type de gare et le contexte
    func shouldShowPlatform(for stationType: String?, trainTime: String?, isDeparture: Bool) -> Bool {
        // Afficher le quai uniquement si :
        // 1. Il y a un numéro de quai
        guard platform != nil else { return false }
        
        // 2. Le train a un horaire valide (pas vide, pas "-")
        guard let t = trainTime, !t.isEmpty && t != "-" else { return false }
        
        // 3. Selon le type de gare et le contexte (départ/arrivée)
        if let type = stationType {
            switch type.lowercased() {
            case "origin":
                // Gare d'origine : afficher le quai seulement pour les départs
                return isDeparture
            case "terminus":
                // Gare terminus : afficher le quai seulement pour les arrivées
                return !isDeparture
            case "intermediate", "served":
                // Gare intermédiaire : toujours afficher le quai
                return true
            default:
                return true
            }
        }
        
        // Par défaut, afficher le quai
        return true
    }
}

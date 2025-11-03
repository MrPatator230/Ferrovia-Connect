//
//  Ferrovia_ConnectApp.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import SwiftUI

@main
struct Ferrovia_ConnectApp: App {
    @StateObject private var savedTimetablesManager = SavedTimetablesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(savedTimetablesManager)
        }
    }
}

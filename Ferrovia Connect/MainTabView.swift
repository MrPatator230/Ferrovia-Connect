//
//  MainTabView.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Accueil")
                }
            
            Text("Billets")
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Billets")
                }
            
            Text("Offres")
                .tabItem {
                    Image(systemName: "ticket.fill")
                    Text("Offres")
                }
            
            Text("Compte")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Compte")
                }
        }
        .accentColor(Color(red: 0.4, green: 0.6, blue: 0.8))
    }
}

#Preview {
    MainTabView()
        .environmentObject(SavedTimetablesManager())
}

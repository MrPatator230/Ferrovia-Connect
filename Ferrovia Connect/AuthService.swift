//
//  AuthService.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import Foundation
import Combine

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let user: User?
    
    struct User: Codable {
        let id: String
        let email: String
        let name: String?
    }
}

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var authToken: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let tokenKey = ""
    
    private init() {
        // Charger le token sauvegardé
        loadToken()
    }
    
    func login(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let url = URL(string: "https://ter-bfc.mr-patator.fr/api/auth/login") else {
            await MainActor.run {
                errorMessage = "URL invalide"
                isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let loginData = LoginRequest(email: email, password: password)
        
        do {
            request.httpBody = try JSONEncoder().encode(loginData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Code de réponse login: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    
                    await MainActor.run {
                        self.authToken = loginResponse.token
                        self.isAuthenticated = true
                        self.isLoading = false
                        saveToken(loginResponse.token)
                        print("✅ Connexion réussie")
                    }
                } else {
                    // Essayer de décoder le message d'erreur
                    if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                       let error = errorResponse["error"] {
                        await MainActor.run {
                            self.errorMessage = error
                            self.isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            self.errorMessage = "Échec de l'authentification"
                            self.isLoading = false
                        }
                    }
                }
            }
        } catch {
            print("❌ Erreur de connexion: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Erreur de connexion: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        authToken = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: tokenKey)
        print("🔓 Déconnexion réussie")
    }
    
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    private func loadToken() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            self.authToken = token
            self.isAuthenticated = true
            print("🔑 Token chargé depuis le stockage")
        }
    }
}

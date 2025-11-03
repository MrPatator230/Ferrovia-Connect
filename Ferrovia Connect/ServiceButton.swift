//
//  ServiceButton.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import SwiftUI

struct ServiceButton: View {
    let iconName: String
    let title: String
    let hasExternalLink: Bool
    
    init(iconName: String, title: String, hasExternalLink: Bool = false) {
        self.iconName = iconName
        self.title = title
        self.hasExternalLink = hasExternalLink
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 32))
                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
            
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if hasExternalLink {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}

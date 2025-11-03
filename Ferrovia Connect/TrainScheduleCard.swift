//
//  TrainScheduleCard.swift
//  Ferrovia Connect
//
//  Created by Mathis GRILLOT on 31/10/2025.
//

import SwiftUI

struct TrainScheduleCard: View {
    let schedule: TrainSchedule
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.time)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(schedule.when)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 8) {
                Image(systemName: "tram.fill")
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.destination)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text("\(schedule.trainNumber) - \(schedule.trainCourt)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(red: 0.15, green: 0.17, blue: 0.25))
        .cornerRadius(12)
    }
}

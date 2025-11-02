import SwiftUI

// Helper struct for displaying stops uniformly
struct StopDisplayInfo: Identifiable {
    let id = UUID()
    let stationName: String
    let time: String
    let platform: String?
    let dwellMinutes: Int?
    let isOrigin: Bool
    let isTerminus: Bool
}

struct TrainDetailsView: View {
    let trainNumber: String
    @ObservedObject var service = TrainDetailsService.shared
    @Environment(\.presentationMode) private var presentationMode

    private var titleText: String {
        if let type = service.trainDetails?.trainType, !type.isEmpty {
            return "Train \(type) \(trainNumber)"
        } else {
            return "Train \(trainNumber)"
        }
    }
    
    // Computed property to build complete stops list including departure and arrival
    private var completeStops: [StopDisplayInfo] {
        guard let details = service.trainDetails else { return [] }
        
        var displayStops: [StopDisplayInfo] = []
        
        // Add departure station (origin)
        displayStops.append(StopDisplayInfo(
            stationName: details.departureStation,
            time: details.departureTime,
            platform: details.departurePlatform,
            dwellMinutes: nil,
            isOrigin: true,
            isTerminus: false
        ))
        
        // Add intermediate stops (excluding first and last if they match origin/terminus)
        for stop in details.stops {
            // Skip if this stop is the same as origin or terminus
            if stop.stationName != details.departureStation && stop.stationName != details.arrivalStation {
                displayStops.append(StopDisplayInfo(
                    stationName: stop.stationName,
                    time: stop.arrivalTime ?? stop.departureTime ?? "–",
                    platform: stop.platform,
                    dwellMinutes: stop.dwellMinutes,
                    isOrigin: false,
                    isTerminus: false
                ))
            }
        }
        
        // Add arrival station (terminus)
        displayStops.append(StopDisplayInfo(
            stationName: details.arrivalStation,
            time: details.arrivalTime,
            platform: details.arrivalPlatform,
            dwellMinutes: nil,
            isOrigin: false,
            isTerminus: true
        ))
        
        return displayStops
    }

    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.035, green: 0.047, blue: 0.082, alpha: 1))
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(#colorLiteral(red: 0.035, green: 0.047, blue: 0.082, alpha: 1)))
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    Spacer()
                    Text(titleText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    // keep space for symmetry
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Train card
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(#colorLiteral(red: 0.078, green: 0.098, blue: 0.14, alpha: 1)))
                                .frame(height: 160)
                            // small label top-left
                            Text("Train court")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.clear)
                                .offset(x: 16, y: 12)

                            HStack {
                                Spacer()
                                // Image placeholder - if you have an asset with the train graphic, replace the name
                                Image("train_placeholder")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .clipped()
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .padding(.trailing, 16)
                            }
                        }
                        .padding(.horizontal)

                        // Info pill (Voie)
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(#colorLiteral(red: 0.111, green: 0.349, blue: 0.976, alpha: 0.12)))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "info.circle")
                                    .foregroundColor(Color(#colorLiteral(red: 0.111, green: 0.349, blue: 0.976, alpha: 1)))
                            }

                            Text("Voie \(service.trainDetails?.departurePlatform ?? "–")")
                                .foregroundColor(.white)
                                .font(.subheadline)

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(#colorLiteral(red: 0.052, green: 0.062, blue: 0.086, alpha: 1)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(#colorLiteral(red: 0.111, green: 0.349, blue: 0.976, alpha: 1)), lineWidth: 2)
                                )
                        )
                        .padding(.horizontal)

                        // Services
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Services à bord de ce train")
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .padding(.horizontal)

                            HStack(spacing: 20) {
                                // use SF Symbols for icons; if you have custom icons, replace
                                Image(systemName: "fanblades")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                Image(systemName: "powerplug")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                Image(systemName: "bicycle")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                Spacer()
                            }
                            .padding(.horizontal)

                            Text(service.trainDetails != nil ? descriptionText(from: service.trainDetails!) : "")
                                .font(.footnote)
                                .foregroundColor(Color(#colorLiteral(red: 0.616, green: 0.639, blue: 0.666, alpha: 1)))
                                .padding(.horizontal)
                        }

                        // thin black progress bar
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 6)
                            .padding(.horizontal)

                        // Destination block
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Destination \(service.trainDetails?.arrivalStation ?? "–")")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text("Opéré par SNCF Voyageurs — \(service.trainDetails?.id.description ?? "–")")
                                .foregroundColor(Color(#colorLiteral(red: 0.518, green: 0.541, blue: 0.565, alpha: 1)))
                                .font(.subheadline)
                        }
                        .padding(.horizontal)

                        // Timeline - using complete stops including departure and arrival
                        if service.trainDetails != nil {
                            let stops = completeStops
                            VStack(spacing: 0) {
                                ForEach(Array(stops.enumerated()), id: \ .element.id) { index, stop in
                                    let currentHeight: CGFloat = index == 0 ? 80 : (index == stops.count - 1 ? 60 : 70)
                                    let nextHeight: CGFloat = index < stops.count - 1 ? 
                                        (index + 1 == stops.count - 1 ? 60 : 70) : 0
                                    let lineHeight = currentHeight / 2 + nextHeight / 2
                                    
                                    HStack(alignment: .center, spacing: 14) {
                                        // Time capsule
                                        Text(stop.time)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 7)
                                            .padding(.horizontal, 13)
                                            .background(Color(#colorLiteral(red: 0.596, green: 0.306, blue: 0.914, alpha: 1)))
                                            .clipShape(Capsule())
                                            .frame(width: 68, alignment: .center)
                                        
                                        // Circle marker with vertical line
                                        ZStack {
                                            // Vertical line passing through the circle - dynamic height
                                            if index != stops.count - 1 {
                                                Rectangle()
                                                    .fill(Color(#colorLiteral(red: 0.596, green: 0.306, blue: 0.914, alpha: 1)))
                                                    .frame(width: 5, height: lineHeight)
                                                    .offset(y: lineHeight / 2)
                                            }
                                            
                                            // Circle marker on top of the line
                                            if stop.isOrigin {
                                                // First stop: train icon in white circle
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 42, height: 42)
                                                    .overlay(
                                                        Image(systemName: "train.side.front.car")
                                                            .foregroundColor(Color(#colorLiteral(red: 0.035, green: 0.047, blue: 0.082, alpha: 1)))
                                                            .font(.system(size: 20, weight: .medium))
                                                    )
                                            } else if stop.isTerminus {
                                                // Last stop: empty circle (outline only)
                                                Circle()
                                                    .strokeBorder(Color(#colorLiteral(red: 0.596, green: 0.306, blue: 0.914, alpha: 1)), lineWidth: 5)
                                                    .background(Circle().fill(Color(#colorLiteral(red: 0.035, green: 0.047, blue: 0.082, alpha: 1))))
                                                    .frame(width: 22, height: 22)
                                            } else {
                                                // Middle stops: small filled circle with thick border
                                                Circle()
                                                    .fill(Color(#colorLiteral(red: 0.596, green: 0.306, blue: 0.914, alpha: 1)))
                                                    .frame(width: 16, height: 16)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color(#colorLiteral(red: 0.035, green: 0.047, blue: 0.082, alpha: 1)), lineWidth: 5)
                                                    )
                                            }
                                        }
                                        .frame(width: 42, height: 42)
                                        
                                        // Station info
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(stop.stationName)
                                                .foregroundColor(.white)
                                                .font(.system(size: stop.isOrigin || stop.isTerminus ? 18 : 17, weight: stop.isOrigin || stop.isTerminus ? .semibold : .regular))
                                                .lineLimit(1)
                                            
                                            // Additional info row
                                            if stop.isOrigin {
                                                if let platform = stop.platform {
                                                    Text("Voie \(platform)")
                                                        .foregroundColor(Color(#colorLiteral(red: 0.596, green: 0.306, blue: 0.914, alpha: 1)))
                                                        .font(.system(size: 14, weight: .medium))
                                                }
                                            } else if !stop.isTerminus {
                                                if let dwell = stop.dwellMinutes, dwell > 0 {
                                                    Text("\(dwell) min d'arrêt")
                                                        .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.573, blue: 0.596, alpha: 1)))
                                                        .font(.system(size: 13))
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, index == 0 ? 8 : 6)
                                    .frame(height: currentHeight)
                                }
                            }
                            .padding(.top, 12)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear { service.fetchDetails(for: trainNumber) }
        .overlay(
            Group {
                if service.isLoading {
                    Color.black.opacity(0.45).edgesIgnoringSafeArea(.all)
                    ProgressView()
                } else if let err = service.errorMessage {
                    VStack {
                        Text(err)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                        Button("Fermer") { service.errorMessage = nil }
                            .padding(.top, 8)
                    }
                }
            }
        )
    }

    private func descriptionText(from details: TrainDetails) -> String {
        var parts: [String] = []
        if let rolling = details.rollingStock {
            parts.append("1 train « \(rolling) »")
        }
        // Use number of cars if available in rollingStockInfo or fallback to stops.count
        if let cars = details.rollingStockInfo?.carsCount {
            parts.append("\(cars) voitures")
        } else {
            parts.append("\(max(1, details.stops.count)) voitures")
        }
        parts.append("220 places")
        return parts.joined(separator: " - ")
    }
}

struct TrainDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TrainDetailsView(trainNumber: "894229")
            .preferredColorScheme(.dark)
    }
}

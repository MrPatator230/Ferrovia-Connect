import SwiftUI

struct StationTimesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    // Same palette as ContentView
    let background = Color(red: 15/255, green: 22/255, blue: 38/255)
    let cardBackground = Color(red: 22/255, green: 29/255, blue: 44/255)
    let accentCyan = Color(red: 92/255, green: 203/255, blue: 219/255)

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Top bar: back button + centered title
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(cardBackground)
                                .frame(width: 48, height: 48)
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Text("Horaires en gare")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, -12)

                // Large search bar with circular cyan search button
                HStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Rechercher une gare, un arrêt...", text: $query)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 16)
                    .padding(.leading, 20)

                    Button(action: { /* search action */ }) {
                        ZStack {
                            Circle()
                                .fill(accentCyan.opacity(0.98))
                                .frame(width: 64, height: 64)
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.black)
                                .font(.title3)
                        }
                        .padding(8)
                    }
                }
                .background(Color.white.opacity(0.95))
                .cornerRadius(36)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 6)

                Spacer().frame(height: 18)

                // Illustration of train
                Image(systemName: "train.side.front.car.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .foregroundColor(accentCyan)
                    .padding(.horizontal, 24)
                    .opacity(0.9)

                // Title and description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Consultez les horaires de tous les trains et transports en commun")
                        .foregroundColor(.white)
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentCyan, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "house")
                                    .foregroundColor(.white)
                            }

                            Text("Recherchez la gare, la station ou l’arrêt qui vous intéresse.")
                                .foregroundColor(.white.opacity(0.9))
                        }

                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentCyan, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "arrow.uturn.left")
                                    .foregroundColor(.white)
                            }

                            Text("Retrouvez les horaires de tous les trains mais aussi des bus, du tramway, du métro...")
                                .foregroundColor(.white.opacity(0.9))
                        }

                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentCyan, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "train.side.front.car")
                                    .foregroundColor(.white)
                            }

                            Text("Trains grandes lignes : choisissez d'afficher les trains au départ ou à l'arrivée de la gare.")
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .font(.body)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationBarHidden(true)
    }
}

struct StationTimesView_Previews: PreviewProvider {
    static var previews: some View {
        StationTimesView()
            .previewDevice("iPhone 14 Pro")
    }
}

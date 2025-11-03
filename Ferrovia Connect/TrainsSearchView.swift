// filepath: /Users/mgrillot/Desktop/App MAC/Ferrovia Connect/Ferrovia Connect/TrainsSearchView.swift
//
//  TrainsSearchView.swift
//  Ferrovia Connect
//
//  Created by AI assistant on request
//

import SwiftUI

struct TrainsSearchView: View {
    // Simple binding/state to simulate inputs
    @Environment(\.presentationMode) private var presentationMode
    // Dynamic state
    @State private var fromText: String = ""
    @State private var toText: String = ""
    @State private var date: Date = Date()
    @State private var isReturnAdded: Bool = false

    // UI state for modals / sheets
    @State private var showFromEditor: Bool = false
    @State private var showToEditor: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showAddCodeSheet: Bool = false

    // Filters and selections
    @State private var filters: [String] = ["Trajets directs", "Trajets via", "Temps de correspondance"]
    @State private var selectedFilters: Set<String> = []
    @State private var travelerOptions: [String] = ["Voyageur", "Animal", "Vélo"]
    @State private var selectedTraveler: String = "Voyageur"
    @State private var codes: [String] = []

    private var dateText: String { DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short) }

    // Colors used to match the design
    private let background = Color(red: 0.06, green: 0.08, blue: 0.12)
    private let cardBg = Color(red: 0.15, green: 0.17, blue: 0.23)
    private let cardInner = Color(red: 0.18, green: 0.2, blue: 0.27)
    private let accent = Color(red: 0.52, green: 0.92, blue: 0.98)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with custom back circle and title
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(cardBg)
                                .frame(width: 52, height: 52)
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .semibold))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Text("Recherche")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // From / To card (editable)
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Départ : ")
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(fromText.isEmpty ? "D'où partons-nous ?" : fromText)
                                        .foregroundColor(.white.opacity(0.75))
                                }
                                Spacer()
                                // swap button
                                Button(action: { swap(&fromText, &toText) }) {
                                    ZStack {
                                        Circle()
                                            .fill(cardInner)
                                            .frame(width: 52, height: 52)
                                        Image(systemName: "arrow.up.arrow.down")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding()

                            Divider().background(Color.black.opacity(0.2))

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Arrivée : ")
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(toText.isEmpty ? "Où allons-nous ?" : toText)
                                        .foregroundColor(.white.opacity(0.75))
                                }
                                Spacer()
                            }
                            .padding()
                        }
                        .background(cardBg)
                        .cornerRadius(14)
                        .padding(.horizontal)
                        // Make the whole card tappable to edit
                        .onTapGesture {
                            // open a simple editor sheet to edit both fields
                            showFromEditor = true
                        }

                        // Date row (opens date picker)
                        Button(action: { showDatePicker = true }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.white.opacity(0.8))
                                Text("Aller : ")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.system(size: 16, weight: .semibold))
                                Text(dateText)
                                    .foregroundColor(.white.opacity(0.75))
                                Spacer()
                            }
                            .padding()
                            .background(cardBg)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Add return
                        HStack {
                            Spacer()
                            Button(action: { isReturnAdded.toggle() }) {
                                HStack(spacing: 12) {
                                    Text(isReturnAdded ? "Retour ajouté" : "Ajouter le retour")
                                        .foregroundColor(isReturnAdded ? .white : accent)
                                    ZStack {
                                        Circle()
                                            .fill(isReturnAdded ? Color.white.opacity(0.12) : accent)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(cardBg)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Filter chips
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Filtrer par :")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .semibold))
                                Spacer()
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(filters, id: \.self) { f in
                                        filterChip(text: f)
                                            .onTapGesture {
                                                if selectedFilters.contains(f) { selectedFilters.remove(f) }
                                                else { selectedFilters.insert(f) }
                                            }
                                            .overlay(
                                                Group {
                                                    if selectedFilters.contains(f) {
                                                        RoundedRectangle(cornerRadius: 999).stroke(accent, lineWidth: 2)
                                                    }
                                                }
                                            )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Who travels
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Qui voyage ?")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                ForEach(travelerOptions, id: \.self) { opt in
                                    optionCard(icon: iconForTraveler(opt), title: opt)
                                        .onTapGesture { selectedTraveler = opt }
                                        .overlay(
                                            Group {
                                                if selectedTraveler == opt {
                                                    RoundedRectangle(cornerRadius: 12).stroke(accent, lineWidth: 2)
                                                }
                                            }
                                        )
                                }
                            }
                            .padding(.horizontal)

                            // profile card
                            HStack {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 56, height: 56)
                                    .overlay(Text("MG").foregroundColor(.white).bold())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Mathis Grillot")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Sans carte de réduction")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.system(size: 13))
                                    Text("Sans carte de fidélité")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.system(size: 13))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(accent)
                            }
                            .padding()
                            .background(cardBg)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Codes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Codes")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)

                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Ajouter un code")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Code avantage SNCF ou bon d'achat.")
                                        .foregroundColor(.white.opacity(0.75))
                                        .font(.system(size: 13))
                                }
                                Spacer()
                                Button(action: { showAddCodeSheet = true }) {
                                    ZStack {
                                        Circle()
                                            .fill(accent)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "plus")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding()
                            .background(cardBg)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // show added codes
                        if !codes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(codes.enumerated()), id: \.offset) { idx, code in
                                    HStack {
                                        Text(code)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: { codes.remove(at: idx) }) {
                                            Image(systemName: "xmark")
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    .padding()
                                    .background(cardInner)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 6)
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.top, 18)
                }
            }
        }
        .navigationBarHidden(true)
        // Sheets and modals
        .sheet(isPresented: $showFromEditor) {
            NavigationStack {
                Form {
                    Section(header: Text("Départ")) {
                        TextField("Gare de départ", text: $fromText)
                    }
                    Section(header: Text("Arrivée")) {
                        TextField("Gare d'arrivée", text: $toText)
                    }
                }
                .navigationTitle("Modifier le trajet")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("OK") { showFromEditor = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 16) {
                DatePicker("Sélectionner la date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                Button("Valider") { showDatePicker = false }
                    .padding()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddCodeSheet) {
            NavigationStack {
                AddCodeView(codes: $codes)
            }
        }
    }

    // Small helper views
    @ViewBuilder
    private func filterChip(text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
        }
        .background(cardInner)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func optionCard(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .foregroundColor(.white)
            ZStack {
                Circle()
                    .fill(Color(red: 0.62, green: 0.94, blue: 0.99))
                    .frame(width: 26, height: 26)
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 13))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // Helper for traveler icon mapping
    private func iconForTraveler(_ t: String) -> String {
        switch t {
        case "Animal": return "pawprint"
        case "Vélo": return "bicycle"
        default: return "person"
        }
    }
}

struct TrainsSearchView_Previews: PreviewProvider {
    static var previews: some View {
        TrainsSearchView()
            .previewDevice("iPhone 14 Pro")
    }
}

// Small sheet view to add a code
struct AddCodeView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var codes: [String]
    @State private var newCode: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Nouveau code")) {
                    TextField("Saisir le code", text: $newCode)
                }
            }
            .navigationTitle("Ajouter un code")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        let trimmed = newCode.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { codes.append(trimmed) }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }
}

import SwiftUI

struct FormulaDetailView: View {
    let formula: Formula
    @State private var isReferencesExpanded = false
    @StateObject private var keyboardToolbar = KeyboardToolbarState()
    @EnvironmentObject var favorites: FavoritesManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                AnimatedMeshBackground()
                
                ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(formula.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Category Badge
                HStack {
                    Text(formula.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundColor(.blue)
                        .glassEffect(.regular, in: .capsule)
                    Spacer()
                }
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    Text(formula.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Divider()

                // Calculator for each formula
                switch formula.name {
                case "Anion Gap & Delta-Delta":
                    AnionGapCalculatorView()
                case "CKD-EPI 2021":
                    CKDEPICalculatorView()
                case "Glucose Correction for Sodium":
                    GlucoseCorrectionCalculatorView()
                case "Corrected Calcium":
                    CorrectedCalciumCalculatorView()
                case "Adrogue-Madias Sodium Prediction":
                    Adrogue_MadiasCalculatorView()
                case "Free Water Deficit":
                    FreeWaterDeficitCalculatorView()
                case "Acid-Base Interpretation":
                    AcidBaseCalculatorView()
                case "Bicarbonate Deficit":
                    BicarbonateDeficitCalculatorView()
                case "Serum Osmolality & Osmolal Gap":
                    OsmolalityCalculatorView()
                case "Electrolyte-Free Water Clearance":
                    EFWCCalculatorView()
                case "Urine Osmolal Gap":
                    UrineOsmolalGapCalculatorView()
                case "Urine Anion Gap":
                    UrineAnionGapCalculatorView()
                default:
                    // Equation (if available)
                    if let equation = formula.equation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Equation")
                                .font(.headline)
                            formulaText(equation)
                                .padding()
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                        }
                    }

                    // Variables (if available)
                    if let variables = formula.variables, !variables.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Variables")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(variables, id: \.self) { variable in
                                    formulaText("• " + variable, baseFont: .body)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Placeholder for calculator
                    VStack(alignment: .center, spacing: 12) {
                        Text("Calculator Coming Soon")
                            .font(.headline)
                        Text("Add input fields and calculations for this formula")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                }

                // References (if available)
                if let references = formula.references, !references.isEmpty {
                    Divider()
                    DisclosureGroup("References", isExpanded: $isReferencesExpanded) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(references, id: \.self) { reference in
                                Text("• " + reference)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .font(.headline)
                }
            }
            .padding()
            .padding(.bottom, keyboardToolbar.isActive ? 50 : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .scrollDismissesKeyboard(.interactively)
            } // ZStack with background
        
            if keyboardToolbar.isActive {
                KeyboardNavigationToolbar(
                    isFirstField: keyboardToolbar.isFirstField,
                    isLastField: keyboardToolbar.isLastField,
                    onBack: keyboardToolbar.onBack,
                    onForward: keyboardToolbar.onForward,
                    onDismiss: keyboardToolbar.onDismiss
                )
                .padding(.bottom, 10)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: keyboardToolbar.isActive)
        .environmentObject(keyboardToolbar)
        .navigationTitle(formula.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(
                    isFavorite: favorites.isFavorite(formula),
                    action: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            favorites.toggle(formula)
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        FormulaDetailView(formula: Formula(
            name: "Sample Formula",
            category: "GFR",
            description: "This is a sample formula description"
        ))
    }
    .environmentObject(KeyboardToolbarState())
    .environmentObject(FavoritesManager())
}

import SwiftUI

struct FormulaDetailView: View {
    let formula: Formula
    @State private var isReferencesExpanded = false
    
    var body: some View {
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
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
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

                // Special calculator for Anion Gap and CKD-EPI
                if formula.name == "Anion Gap & Delta-Delta" {
                    AnionGapCalculatorView()
                } else if formula.name == "CKD-EPI 2021" {
                    CKDEPICalculatorView()
                } else if formula.name == "Glucose Correction for Sodium" {
                    GlucoseCorrectionCalculatorView()
                } else if formula.name == "Corrected Calcium" {
                    CorrectedCalciumCalculatorView()
                } else if formula.name == "Adrogue-Madias Sodium Prediction" {
                    Adrogue_MadiasCalculatorView()
                } else if formula.name == "Free Water Deficit" {
                    FreeWaterDeficitCalculatorView()
                } else if formula.name == "Acid-Base Interpretation" {
                    AcidBaseCalculatorView()
                } else if formula.name == "Bicarbonate Deficit" {
                    BicarbonateDeficitCalculatorView()
                } else {
                    // Equation (if available)
                    if let equation = formula.equation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Equation")
                                .font(.headline)
                            Text(equation)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                    }

                    // Variables (if available)
                    if let variables = formula.variables, !variables.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Variables")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(variables, id: \.self) { variable in
                                    Text("• " + variable)
                                        .font(.body)
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
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                    )
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
        }
        .navigationTitle(formula.name)
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
}

import SwiftUI

struct UrineOsmolalGapCalculatorView: View {
    @State private var urineNa: String = ""
    @State private var urineK: String = ""
    @State private var urineUrea: String = ""
    @State private var urineGlucose: String = ""
    @State private var measuredUrineOsm: String = ""
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState

    enum Field: Hashable {
        case urineNa, urineK, urineUrea, urineGlucose, measuredUrineOsm
    }

    // Calculated Urine Osm = 2(Na + K) + Urea/2.8 + Glucose/18
    private var calculatedUrineOsm: Double? {
        guard let na = Double(urineNa),
              let k = Double(urineK),
              let urea = Double(urineUrea),
              let glu = Double(urineGlucose) else {
            return nil
        }
        return 2.0 * (na + k) + urea / 2.8 + glu / 18.0
    }

    // Urine Osmolal Gap = Measured Urine Osm − Calculated Urine Osm
    private var urineOsmolalGap: Double? {
        guard let calc = calculatedUrineOsm,
              let measured = Double(measuredUrineOsm) else {
            return nil
        }
        return measured - calc
    }

    // Estimated NH₄⁺ ≈ Urine Osmolal Gap / 2
    private var estimatedNH4: Double? {
        guard let gap = urineOsmolalGap else { return nil }
        return gap / 2.0
    }

    private var gapInterpretation: (title: String, detail: String, color: Color)? {
        guard let gap = urineOsmolalGap else { return nil }
        if gap > 150 {
            return (
                "Appropriate Renal Response",
                "A urine osmolal gap > 150 mOsm/kg (estimated NH₄⁺ > 75 mEq/L) indicates robust renal ammonium excretion. The kidneys are appropriately increasing acid excretion, suggesting an extrarenal cause of metabolic acidosis such as diarrhea or other GI bicarbonate losses.",
                .green
            )
        } else if gap >= 100 && gap <= 150 {
            return (
                "Borderline / Indeterminate",
                "A urine osmolal gap of 100–150 mOsm/kg may represent a partial renal response. Clinical correlation is recommended. Consider early or mild renal tubular acidosis, or a mixed etiology.",
                .orange
            )
        } else {
            return (
                "Impaired Renal Ammonium Excretion",
                "A urine osmolal gap < 100 mOsm/kg (estimated NH₄⁺ < 50 mEq/L) suggests impaired renal ammonium excretion. This pattern is consistent with renal tubular acidosis (RTA) — the kidneys are unable to appropriately excrete acid. Consider Type 1 (distal) or Type 4 RTA.",
                .red
            )
        }
    }

    private var isLastField: Bool {
        return focusedField == .measuredUrineOsm
    }

    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }

        let fields: [Field] = [.urineNa, .urineK, .urineUrea, .urineGlucose, .measuredUrineOsm]

        if let currentIndex = fields.firstIndex(of: current) {
            switch direction {
            case .forward:
                if currentIndex < fields.count - 1 {
                    focusedField = fields[currentIndex + 1]
                } else {
                    focusedField = nil
                }
            case .back:
                if currentIndex > 0 {
                    focusedField = fields[currentIndex - 1]
                }
            }
        }
    }

    enum NavigationDirection {
        case forward, back
    }

    private func updateToolbarState() {
        keyboardToolbar.isActive = focusedField != nil
        keyboardToolbar.isFirstField = focusedField == .urineNa
        keyboardToolbar.isLastField = isLastField
        keyboardToolbar.onBack = { moveFocus(direction: .back) }
        keyboardToolbar.onForward = { moveFocus(direction: .forward) }
        keyboardToolbar.onDismiss = { focusedField = nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Input Fields
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Urine Sodium")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $urineNa)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .urineNa)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Urine Potassium")
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $urineK)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .urineK)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Urine Urea Nitrogen")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mg/dL", text: $urineUrea)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .urineUrea)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Urine Glucose")
                        .foregroundColor(.teal)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mg/dL", text: $urineGlucose)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .urineGlucose)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Measured Urine Osmolality")
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mOsm/kg", text: $measuredUrineOsm)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .measuredUrineOsm)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }

            // Results
            if let calcOsm = calculatedUrineOsm {
                VStack(alignment: .leading, spacing: 12) {

                    // Calculated Urine Osmolality
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calculated Urine Osmolality")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mOsm/kg", calcOsm))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }

                    Divider()

                    // Component breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Component Breakdown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)

                        if let na = Double(urineNa), let k = Double(urineK) {
                            HStack {
                                Text("2 × (Na + K)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f mOsm/kg", 2.0 * (na + k)))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        if let urea = Double(urineUrea) {
                            HStack {
                                Text("Urea N / 2.8")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f mOsm/kg", urea / 2.8))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        if let glu = Double(urineGlucose) {
                            HStack {
                                Text("Glucose / 18")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f mOsm/kg", glu / 18.0))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }

                    // Urine Osmolal Gap & NH₄⁺
                    if let gap = urineOsmolalGap, let nh4 = estimatedNH4, let interp = gapInterpretation {
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Urine Osmolal Gap")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                                Text(String(format: "%.1f mOsm/kg", gap))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()

                            Text(gap > 150 ? "Adequate" : gap >= 100 ? "Borderline" : "Low")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(interp.color.opacity(0.2))
                                .foregroundColor(interp.color)
                                .cornerRadius(6)
                        }

                        // Estimated NH₄⁺
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Estimated Urine NH₄⁺")
                                    .font(.subheadline)
                                    .foregroundColor(.indigo)
                                    .fontWeight(.semibold)
                                Text(String(format: "%.1f mEq/L", nh4))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()

                            Text(nh4 > 75 ? "Adequate" : nh4 >= 50 ? "Borderline" : "Low")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(interp.color.opacity(0.2))
                                .foregroundColor(interp.color)
                                .cornerRadius(6)
                        }

                        Divider()

                        // Interpretation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interpretation")
                                .font(.subheadline)
                                .foregroundColor(.indigo)
                                .fontWeight(.semibold)

                            Text(interp.title)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(interp.color)

                            Text(interp.detail)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                        }
                    }
                }
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: calculatedUrineOsm)
            }

            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formula")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("Calc Urine Osm = 2(Na + K) + Urea N/2.8 + Glucose/18")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("Urine Osmolal Gap = Measured − Calculated")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("Estimated NH₄⁺ ≈ Urine Osmolal Gap / 2")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))

            // Clinical Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Clinical Notes")
                    .font(.headline)
                    .foregroundColor(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("• More reliable than UAG when unmeasured")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("  anions are present (e.g., ketoacids, hippurate)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Gap > 150 → adequate NH₄⁺ excretion")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Gap < 100 → impaired NH₄⁺ (suspect RTA)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Estimated NH₄⁺ = urine osmolal gap / 2")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Best applied in the setting of NAGMA")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Urine glucose often negligible unless")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("  significant glycosuria is present")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Preferred over UAG in DKA and toluene")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("  ingestion where UAG may be falsely positive")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            
            // Abbreviations
            VStack(alignment: .leading, spacing: 6) {
                Text("Abbreviations")
                    .font(.headline)
                    .foregroundColor(.gray)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Osm — Osmolality")
                    Text("UAG — Urine Anion Gap")
                    Text("NAGMA — Normal Anion Gap Metabolic Acidosis")
                    Text("RTA — Renal Tubular Acidosis")
                    Text("DKA — Diabetic Ketoacidosis")
                    Text("GI — Gastrointestinal")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }
}

#Preview {
    ScrollView {
        UrineOsmolalGapCalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

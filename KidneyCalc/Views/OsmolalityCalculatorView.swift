import SwiftUI

struct OsmolalityCalculatorView: View {
    @State private var sodium: String = ""
    @State private var glucose: String = ""
    @State private var bun: String = ""
    @State private var measuredOsm: String = ""
    @State private var includeMeasured: Bool = false
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState

    enum Field: Hashable {
        case sodium, glucose, bun, measuredOsm
    }

    // Calculated Osmolality = 2(Na) + Glucose/18 + BUN/2.8
    private var calculatedOsmolality: Double? {
        guard let na = Double(sodium),
              let glu = Double(glucose),
              let bunVal = Double(bun) else {
            return nil
        }
        return 2.0 * na + glu / 18.0 + bunVal / 2.8
    }

    // Osmolal Gap = Measured Osmolality - Calculated Osmolality
    private var osmolalGap: Double? {
        guard let calc = calculatedOsmolality,
              let measured = Double(measuredOsm) else {
            return nil
        }
        return measured - calc
    }

    private var osmolalGapInterpretation: (title: String, detail: String, color: Color)? {
        guard let gap = osmolalGap else { return nil }
        if gap < 10 {
            return (
                "Normal Osmolal Gap",
                "An osmolal gap < 10 mOsm/kg is considered normal. There is no significant difference between measured and calculated osmolality, suggesting no major unmeasured osmoles are present.",
                .green
            )
        } else if gap >= 10 && gap < 15 {
            return (
                "Borderline Elevated Osmolal Gap",
                "An osmolal gap of 10–15 mOsm/kg is borderline. Consider clinical context and potential for early toxic alcohol ingestion or other unmeasured osmoles. Serial monitoring may be warranted.",
                .orange
            )
        } else {
            return (
                "Elevated Osmolal Gap",
                "An osmolal gap ≥ 15 mOsm/kg is significantly elevated and raises concern for unmeasured osmoles. Common causes include toxic alcohol ingestion (methanol, ethylene glycol, isopropanol), ethanol, propylene glycol, and acetone. Urgent evaluation and possible treatment is indicated.",
                .red
            )
        }
    }

    private var isLastField: Bool {
        if includeMeasured {
            return focusedField == .measuredOsm
        }
        return focusedField == .bun
    }

    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }

        var fields: [Field] = [.sodium, .glucose, .bun]
        if includeMeasured {
            fields.append(.measuredOsm)
        }

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
        keyboardToolbar.isFirstField = focusedField == .sodium
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
                    Text("Sodium (Na)")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $sodium)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .sodium)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Glucose")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mg/dL", text: $glucose)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .glucose)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("BUN")
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mg/dL", text: $bun)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .bun)
                }

                Toggle("Include Measured Osmolality", isOn: $includeMeasured)
                    .fontWeight(.medium)
                    .tint(.orange)

                if includeMeasured {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Measured Osmolality")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                            .font(.subheadline)
                        TextField(" mOsm/kg", text: $measuredOsm)
                            .textFieldStyle(SoftTextFieldStyle())
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .focused($focusedField, equals: .measuredOsm)
                    }
                    .transition(.opacity)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }

            // Results
            if let calcOsm = calculatedOsmolality {
                VStack(alignment: .leading, spacing: 12) {

                    // Calculated Osmolality
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calculated Osmolality")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mOsm/kg", calcOsm))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()

                        Text(calcOsm >= 275 && calcOsm <= 295 ? "Normal" : calcOsm < 275 ? "Low" : "High")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (calcOsm >= 275 && calcOsm <= 295 ? Color.green : Color.orange).opacity(0.2)
                            )
                            .foregroundColor(calcOsm >= 275 && calcOsm <= 295 ? .green : .orange)
                            .cornerRadius(6)
                    }

                    Divider()

                    // Component breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Component Breakdown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)

                        if let na = Double(sodium) {
                            HStack {
                                Text("2 × Na")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f mOsm/kg", 2.0 * na))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        if let glu = Double(glucose) {
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
                        if let bunVal = Double(bun) {
                            HStack {
                                Text("BUN / 2.8")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f mOsm/kg", bunVal / 2.8))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }

                    // Osmolal Gap (if measured provided)
                    if let gap = osmolalGap, let interp = osmolalGapInterpretation {
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Osmolal Gap")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                                Text(String(format: "%.1f mOsm/kg", gap))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()

                            Text(gap < 10 ? "Normal" : gap < 15 ? "Borderline" : "Elevated")
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
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: calculatedOsmolality)
            }

            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formula")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("Calculated Osm = 2(Na) + Glucose/18 + BUN/2.8")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("Osmolal Gap = Measured Osm − Calculated Osm")
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
                    Text("• Normal serum osmolality: 275–295 mOsm/kg")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Normal osmolal gap: < 10 mOsm/kg")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Elevated gap suggests unmeasured osmoles")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("  (toxic alcohols, ethanol, mannitol)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Ethanol correction: add EtOH (mg/dL) / 4.6")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Must use serum (not urine) values")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Measured Osm obtained via freezing-point")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("  depression method (not vapor pressure)")
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
                    Text("BUN — Blood Urea Nitrogen")
                    Text("Osm — Osmolality")
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
        OsmolalityCalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

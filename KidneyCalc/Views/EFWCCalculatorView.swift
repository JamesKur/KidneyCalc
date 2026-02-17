import SwiftUI

struct EFWCCalculatorView: View {
    @State private var urineNa: String = ""
    @State private var urineK: String = ""
    @State private var serumNa: String = ""
    @State private var urineVolume: String = ""
    @State private var volumeUnit: VolumeUnit = .lPerDay
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState

    enum Field: Hashable {
        case urineNa, urineK, serumNa, urineVolume
    }

    enum VolumeUnit: String, CaseIterable {
        case lPerDay = "L/day"
        case mlPerHr = "mL/hr"
    }

    // Urine volume in L/day for calculations
    private var urineVolumeInLPerDay: Double? {
        guard let vol = Double(urineVolume) else { return nil }
        switch volumeUnit {
        case .lPerDay:
            return vol
        case .mlPerHr:
            return vol * 24.0 / 1000.0  // mL/hr → L/day
        }
    }

    // EFWC = V × (1 − (U_Na + U_K) / S_Na)
    private var efwc: Double? {
        guard let uNa = Double(urineNa),
              let uK = Double(urineK),
              let sNa = Double(serumNa),
              let vol = urineVolumeInLPerDay,
              sNa > 0 else {
            return nil
        }
        return vol * (1.0 - (uNa + uK) / sNa)
    }

    // Urine-to-serum electrolyte ratio
    private var urineToSerumRatio: Double? {
        guard let uNa = Double(urineNa),
              let uK = Double(urineK),
              let sNa = Double(serumNa),
              sNa > 0 else {
            return nil
        }
        return (uNa + uK) / sNa
    }

    private var interpretation: (title: String, detail: String, color: Color)? {
        guard let clearance = efwc, let _ = urineToSerumRatio else { return nil }
        if clearance > 0 {
            return (
                "Positive EFWC — Net Free Water Excretion",
                "A positive electrolyte-free water clearance (ratio < 1) indicates the kidney is excreting dilute urine relative to plasma. The urine electrolyte concentration is less than the serum sodium, meaning the kidney is generating free water loss. This tends to raise the serum sodium. Seen in water diuresis and dilute urine states. In hyponatremia, a positive EFWC suggests the kidneys are appropriately correcting the sodium.",
                .blue
            )
        } else if clearance < 0 {
            return (
                "Negative EFWC — Net Free Water Reabsorption",
                "A negative electrolyte-free water clearance (ratio > 1) indicates the kidney is excreting concentrated urine relative to plasma. The urine electrolyte concentration exceeds the serum sodium, meaning the kidney is effectively retaining free water. This tends to lower the serum sodium. Commonly seen with SIADH, hypovolemia, and other states of impaired free water excretion.",
                .orange
            )
        } else {
            return (
                "Zero EFWC — Isotonic Urine",
                "An EFWC of zero (ratio = 1) means the urine electrolyte concentration equals the serum sodium. The kidney is neither generating nor retaining free water. The urine output is isotonic with respect to electrolytes and will not change the serum sodium.",
                .green
            )
        }
    }

    private var isLastField: Bool {
        return focusedField == .urineVolume
    }

    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }

        let fields: [Field] = [.urineNa, .urineK, .serumNa, .urineVolume]

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
                    Text("Serum Sodium")
                        .foregroundColor(.teal)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $serumNa)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .serumNa)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Urine Volume")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                            .font(.subheadline)
                        Spacer()
                        Picker("Unit", selection: $volumeUnit) {
                            ForEach(VolumeUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    TextField(volumeUnit == .lPerDay ? " L/day" : " mL/hr", text: $urineVolume)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .urineVolume)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }

            // Results
            if let clearance = efwc, let ratio = urineToSerumRatio, let interp = interpretation {
                VStack(alignment: .leading, spacing: 12) {

                    // EFWC Value
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Electrolyte-Free Water Clearance")
                                .font(.subheadline)
                                .foregroundColor(.cyan)
                                .fontWeight(.semibold)
                            Text(String(format: "%.2f L/day", clearance))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()

                        Text(clearance > 0 ? "Positive" : clearance < 0 ? "Negative" : "Zero")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(interp.color.opacity(0.2))
                            .foregroundColor(interp.color)
                            .cornerRadius(6)
                    }

                    Divider()

                    // Per-hour conversion
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EFWC (per hour)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mL/hr", clearance * 1000.0 / 24.0))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            formulaCaptionText("(U_Na + U_K) / S_Na")
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            Text(String(format: "%.2f", ratio))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
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
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: efwc)
            }

            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formula")
                    .font(.headline)
                    .foregroundColor(.cyan)
                formulaText("EFWC = V × [1 − (U_Na + U_K) / S_Na]")
                    .foregroundColor(.primary)
                formulaCaptionText("If (U_Na + U_K) / S_Na < 1 → positive EFWC")
                    .foregroundColor(.primary)
                formulaCaptionText("If (U_Na + U_K) / S_Na > 1 → negative EFWC")
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
                    Text("• Predicts effect of urine output on serum Na")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Positive EFWC → urine raises serum Na")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Negative EFWC → urine lowers serum Na")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    formulaCaptionText("• Key ratio: (U_Na + U_K) / S_Na")
                        .foregroundColor(.primary)
                    Text("  Ratio > 1 = concentrated urine (water retained)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("  Ratio < 1 = dilute urine (water excreted)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• More useful than total urine osmolality for")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("  predicting sodium changes (excludes urea)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Essential in managing hypo/hypernatremia")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Requires accurate urine volume measurement")
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
                    Text("EFWC — Electrolyte-Free Water Clearance")
                    Text("SIADH — Syndrome of Inappropriate Antidiuretic Hormone")
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
        EFWCCalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

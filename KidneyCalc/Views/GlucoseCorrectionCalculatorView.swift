import SwiftUI

struct GlucoseCorrectionCalculatorView: View {
    @State private var measuredSodium: String = ""
    @State private var glucose: String = ""
    @State private var useLowerCorrection: Bool = true
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState
    
    enum Field: Hashable {
        case sodium, glucose
    }
    
    private var correctedSodiumLower: Double? {
        guard let na = Double(measuredSodium),
              let gluc = Double(glucose) else {
            return nil
        }
        // Traditional correction: 1.6 mEq/L for every 100 mg/dL increase
        return na + 0.016 * (gluc - 100.0)
    }
    
    private var correctedSodiumHigher: Double? {
        guard let na = Double(measuredSodium),
              let gluc = Double(glucose) else {
            return nil
        }
        // Alternative correction: 2.4 mEq/L for every 100 mg/dL increase
        return na + 0.024 * (gluc - 100.0)
    }
    
    private var correctedSodium: Double? {
        return useLowerCorrection ? correctedSodiumLower : correctedSodiumHigher
    }
    
    private func getSodiumStatus(_ na: Double) -> (status: String, color: Color) {
        switch na {
        case ..<135:
            return ("Hyponatremia", .red)
        case 135...145:
            return ("Normal", .green)
        default:
            return ("Hypernatremia", .orange)
        }
    }
    
    private func getSeverity(_ na: Double) -> String? {
        if na < 135 {
            if na < 120 {
                return "Severe"
            } else if na < 130 {
                return "Moderate"
            } else {
                return "Mild"
            }
        }
        return nil
    }
    
    private var isLastField: Bool {
        return focusedField == .glucose
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        let fields: [Field] = [.sodium, .glucose]
            
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
                    Text("Measured Sodium")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $measuredSodium)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .sodium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glucose")
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mg/dL", text: $glucose)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .glucose)
                }
            
                // Correction factor toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Correction Factor")
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    Picker("Correction Factor", selection: $useLowerCorrection) {
                        Text("1.6 mEq/L per 100 mg/dL").tag(true)
                        Text("2.4 mEq/L per 100 mg/dL").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }
            
            // Results
            if let measuredNa = Double(measuredSodium),
               let gluc = Double(glucose),
               let correctedNa = correctedSodium {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Measured Sodium
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Measured Sodium")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mEq/L", measuredNa))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        // Status
                        VStack(alignment: .trailing, spacing: 4) {
                            let status = getSodiumStatus(measuredNa)
                            Text(status.status)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(status.color.opacity(0.2))
                                .foregroundColor(status.color)
                                .cornerRadius(6)
                            if let severity = getSeverity(measuredNa) {
                                Text(severity)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Corrected Sodium
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Corrected Sodium")
                                .font(.subheadline)
                                .foregroundColor(.teal)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mEq/L", correctedNa))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        // Status
                        VStack(alignment: .trailing, spacing: 4) {
                            let status = getSodiumStatus(correctedNa)
                            Text(status.status)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(status.color.opacity(0.2))
                                .foregroundColor(status.color)
                                .cornerRadius(6)
                            if let severity = getSeverity(correctedNa) {
                                Text(severity)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Show both corrections if glucose is elevated
                    if gluc > 100 {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Alternative Corrections")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .fontWeight(.semibold)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Using 1.6 factor:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    if let lower = correctedSodiumLower {
                                        Text(String(format: "%.1f mEq/L", lower))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Using 2.4 factor:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    if let higher = correctedSodiumHigher {
                                        Text(String(format: "%.1f mEq/L", higher))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Interpretation
                    if gluc > 100 {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Explanation")
                                .font(.subheadline)
                                .foregroundColor(.indigo)
                                .fontWeight(.semibold)
                            Text("In hyperglycemia, sodium is diluted by osmotic water shift. The corrected sodium represents the true sodium concentration after accounting for this effect.")
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
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: correctedSodium)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formulas")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("Traditional (1.6 factor):")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Corrected Na = Measured Na + 0.016 × (Glucose - 100)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                Text("Alternative (2.4 factor):")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Corrected Na = Measured Na + 0.024 × (Glucose - 100)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                Text("Note: 1.6 mEq/L per 100 mg/dL is the traditional factor. Some sources suggest 2.4 mEq/L for glucose >400 mg/dL.")
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            
            // Reference Ranges
            VStack(alignment: .leading, spacing: 8) {
                Text("Sodium Ranges")
                    .font(.headline)
                    .foregroundColor(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Normal: 135-145 mEq/L")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("Mild Hyponatremia: 130-134 mEq/L")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("Moderate Hyponatremia: 120-129 mEq/L")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("Severe Hyponatremia: <120 mEq/L")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("Hypernatremia: >145 mEq/L")
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
                    Text("DKA — Diabetic Ketoacidosis")
                    Text("HHS — Hyperosmolar Hyperglycemic State")
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
        GlucoseCorrectionCalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

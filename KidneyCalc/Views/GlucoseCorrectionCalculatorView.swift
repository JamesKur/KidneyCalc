import SwiftUI

struct GlucoseCorrectionCalculatorView: View {
    @State private var measuredSodium: String = ""
    @State private var glucose: String = ""
    @State private var useLowerCorrection: Bool = true
    @FocusState private var focusedField: Field?
    
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
    
    enum NavigationDirection {
        case forward, back
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
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.cyan.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: { moveFocus(direction: .back) }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .disabled(focusedField == .sodium)
                        
                        Divider()
                            .frame(height: 20)
                        
                        Button(action: { moveFocus(direction: .forward) }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .disabled(isLastField)
                        
                        Divider()
                            .frame(height: 20)
                        
                        Button(action: {
                            if isLastField {
                                focusedField = nil
                            } else {
                                moveFocus(direction: .forward)
                            }
                        }) {
                            Text(isLastField ? "Done" : "Next")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .padding(.leading, 6)
                }
            }
            
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
                                .background(
                                    LinearGradient(
                                        colors: [Color.indigo.opacity(0.15), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.indigo.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
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
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.08), Color.yellow.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
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
            .background(
                LinearGradient(
                    colors: [Color.pink.opacity(0.08), Color.red.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pink.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ScrollView {
        GlucoseCorrectionCalculatorView()
            .padding()
    }
}

import SwiftUI

struct AnionGapCalculatorView: View {
    @State private var sodium: String = ""
    @State private var chloride: String = ""
    @State private var bicarbonate: String = ""
    @State private var albumin: String = ""
    @State private var useAlbuminCorrection: Bool = false
    @State private var directAnionGapInput: String = ""
    @AppStorage("anionGapCalculatorMode") private var useDirectInput: Bool = false
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState
    
    enum Field: Hashable {
        case sodium, chloride, bicarbonate, albumin, directAnionGap
    }
    
    private var anionGap: Double? {
        if useDirectInput {
            // Use the direct input value
            return Double(directAnionGapInput)
        } else {
            // Calculate from electrolytes
            guard let na = Double(sodium),
                  let cl = Double(chloride),
                  let hco3 = Double(bicarbonate) else {
                return nil
            }
            return na - (cl + hco3)
        }
    }
    
    private var correctedAnionGap: Double? {
        guard let ag = anionGap,
              useAlbuminCorrection,
              let alb = Double(albumin) else {
            return nil
        }
        // Corrected AG = Observed AG + 2.5 × (4.0 - albumin)
        return ag + 2.5 * (4.0 - alb)
    }
    
    private var deltaDelta: Double? {
        guard let ag = anionGap,
              let hco3 = Double(bicarbonate) else {
            return nil
        }
        let agToUse = correctedAnionGap ?? ag
        // Only calculate delta-delta if anion gap is elevated (> 12)
        guard agToUse > 12.0 else { return nil }
        let denominator = 24.0 - hco3
        guard denominator != 0 else { return nil }
        return (agToUse - 12.0) / denominator
    }
    
    private var interpretation: String? {
        guard let dd = deltaDelta else { return "NAGMA" }
        if dd < 1.0 {
            return "HAGMA and NAGMA"
        } else if dd >= 1.0 && dd <= 2.0 {
            return "Pure NAGMA"
        } else {
            return "HAGMA and metabolic alkalosis"
        }
    }
    
    private var isLastField: Bool {
        if let currentField = focusedField {
            if useDirectInput {
                // In direct input mode, last field depends on albumin correction
                switch currentField {
                case .albumin:
                    return true
                case .bicarbonate:
                    return !useAlbuminCorrection
                default:
                    return false
                }
            } else {
                // In calculation mode
                switch currentField {
                case .albumin:
                    return true
                case .bicarbonate:
                    return !useAlbuminCorrection
                default:
                    return false
                }
            }
        }
        return false
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        // Define the sequence of fields based on the mode and toggle
        let fields: [Field]
        if useDirectInput {
            if useAlbuminCorrection {
                fields = [.directAnionGap, .bicarbonate, .albumin]
            } else {
                fields = [.directAnionGap, .bicarbonate]
            }
        } else if useAlbuminCorrection {
            fields = [.sodium, .chloride, .bicarbonate, .albumin]
        } else {
            fields = [.sodium, .chloride, .bicarbonate]
        }
            
        if let currentIndex = fields.firstIndex(of: current) {
            switch direction {
            case .forward:
                if currentIndex < fields.count - 1 {
                    focusedField = fields[currentIndex + 1]
                } else {
                    focusedField = nil // Dismiss on last field
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
        keyboardToolbar.isFirstField = focusedField == .sodium || focusedField == .directAnionGap
        keyboardToolbar.isLastField = isLastField
        keyboardToolbar.onBack = { moveFocus(direction: .back) }
        keyboardToolbar.onForward = { moveFocus(direction: .forward) }
        keyboardToolbar.onDismiss = { focusedField = nil }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Mode Toggle
            VStack(alignment: .leading, spacing: 12) {
                Text("Calculate Mode")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            useDirectInput = false
                        }
                    }) {
                        Text("From Electrolytes")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .foregroundColor(useDirectInput ? .secondary : .blue)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(useDirectInput ? Color.clear : Color.blue.opacity(0.2))
                    )
                    .glassEffect(.regular.interactive(), in: .capsule)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            useDirectInput = true
                        }
                    }) {
                        Text("Direct AG Input")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .foregroundColor(useDirectInput ? .blue : .secondary)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(useDirectInput ? Color.blue.opacity(0.2) : Color.clear)
                    )
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            
            // Input Fields
            VStack(alignment: .leading, spacing: 16) {
                
                if useDirectInput {
                    // Direct Anion Gap Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anion Gap")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                            .font(.subheadline)
                        TextField("mEq/L", text: $directAnionGapInput)
                            .textFieldStyle(SoftTextFieldStyle())
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .focused($focusedField, equals: .directAnionGap)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bicarbonate (HCO₃)")
                            .foregroundColor(.teal)
                            .fontWeight(.medium)
                            .font(.subheadline)
                        TextField(" mEq/L", text: $bicarbonate)
                            .textFieldStyle(SoftTextFieldStyle())
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .focused($focusedField, equals: .bicarbonate)
                    }
                    
                    // Albumin correction toggle and input
                    Toggle("Albumin Correction", isOn: $useAlbuminCorrection)
                        .fontWeight(.medium)
                        .tint(.purple)
                    
                    if useAlbuminCorrection {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Albumin")
                                .foregroundColor(.purple)
                                .fontWeight(.medium)
                                .font(.subheadline)
                            TextField("g/dL", text: $albumin)
                                .textFieldStyle(SoftTextFieldStyle())
                                #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                                .focused($focusedField, equals: .albumin)
                        }
                        .transition(.opacity)
                    }
                } else {
                    // Electrolyte Inputs
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
                        Text("Chloride (Cl)")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                            .font(.subheadline)
                        TextField(" mEq/L", text: $chloride)
                            .textFieldStyle(SoftTextFieldStyle())
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .focused($focusedField, equals: .chloride)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bicarbonate (HCO₃)")
                            .foregroundColor(.teal)
                            .fontWeight(.medium)
                            .font(.subheadline)
                        TextField(" mEq/L", text: $bicarbonate)
                            .textFieldStyle(SoftTextFieldStyle())
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .focused($focusedField, equals: .bicarbonate)
                    }
                
                    // Albumin correction toggle and input
                    Toggle("Albumin Correction", isOn: $useAlbuminCorrection)
                        .fontWeight(.medium)
                        .tint(.purple)
                    
                    if useAlbuminCorrection {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Albumin")
                                .foregroundColor(.purple)
                                .fontWeight(.medium)
                                .font(.subheadline)
                            TextField("g/dL", text: $albumin)
                                .textFieldStyle(SoftTextFieldStyle())
                                #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                                .focused($focusedField, equals: .albumin)
                        }
                        .transition(.opacity)
                    }
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onChange(of: useDirectInput) { _, _ in updateToolbarState() }
            .onChange(of: useAlbuminCorrection) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }
            
            // Results
            if anionGap != nil {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Anion Gap
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Anion Gap")
                                .font(.subheadline)
                                .foregroundColor(.teal)
                                .fontWeight(.semibold)
                            if let ag = anionGap {
                                Text(String(format: "%.1f mEq/L", ag))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                        Spacer()
                        
                        // Normal range indicator
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Normal: 8-12")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let ag = anionGap {
                                Text(ag >= 8 && ag <= 12 ? "Normal" : "Abnormal")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ag >= 8 && ag <= 12 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                    .foregroundColor(ag >= 8 && ag <= 12 ? .green : .red)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    // Corrected Anion Gap (if applicable)
                    if let correctedAG = correctedAnionGap {
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Albumin-Corrected AG")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                    .fontWeight(.semibold)
                                Text(String(format: "%.1f mEq/L", correctedAG))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                    }
                    
                    // Delta-Delta
                    if let dd = deltaDelta {
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Delta-Delta Ratio")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                                Text(String(format: "%.2f", dd))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        
                        // Interpretation
                        if let interp = interpretation {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Interpretation")
                                    .font(.subheadline)
                                    .foregroundColor(.indigo)
                                    .fontWeight(.semibold)
                                Text(interp)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .glassEffect(.regular, in: .rect(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: anionGap)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formulas")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("AG = Na - (Cl + HCO₃)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("Corrected AG = AG + 2.5 × (4.0 - Albumin)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("ΔΔ = (AG - 12) / (24 - HCO₃)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            
            // Abbreviations
            VStack(alignment: .leading, spacing: 6) {
                Text("Abbreviations")
                    .font(.headline)
                    .foregroundColor(.gray)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AG — Anion Gap")
                    Text("HAGMA — High Anion Gap Metabolic Acidosis")
                    Text("NAGMA — Normal Anion Gap Metabolic Acidosis")
                    Text("ΔΔ — Delta-Delta Ratio")
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
        AnionGapCalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

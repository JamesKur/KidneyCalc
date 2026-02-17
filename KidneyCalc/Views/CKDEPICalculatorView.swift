import SwiftUI

struct CKDEPICalculatorView: View {
    @State private var creatinine: String = ""
    @State private var cystatinC: String = ""
    @State private var age: String = ""
    @State private var sex: Sex = .male
    @State private var useCystatinC: Bool = false
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState
    
    enum Sex: String, CaseIterable {
        case male = "Male"
        case female = "Female"
    }
    
    enum Field: Hashable {
        case creatinine, cystatinC, age
    }
    
    private var eGFR: Double? {
        guard let scr = Double(creatinine),
              let ageValue = Double(age),
              ageValue > 0 else {
            return nil
        }
        
        if useCystatinC {
            guard let scys = Double(cystatinC) else {
                return nil
            }
            return calculateCombinedEGFR(scr: scr, scys: scys, age: ageValue, isFemale: sex == .female)
        } else {
            return calculateCreatinineEGFR(scr: scr, age: ageValue, isFemale: sex == .female)
        }
    }
    
    private var eGFRCreatinineOnly: Double? {
        guard let scr = Double(creatinine),
              let ageValue = Double(age),
              ageValue > 0 else {
            return nil
        }
        return calculateCreatinineEGFR(scr: scr, age: ageValue, isFemale: sex == .female)
    }
    
    private var eGFRCystatinOnly: Double? {
        guard useCystatinC,
              let scys = Double(cystatinC),
              let ageValue = Double(age),
              ageValue > 0 else {
            return nil
        }
        return calculateCystatinEGFR(scys: scys, age: ageValue, isFemale: sex == .female)
    }
    
    private func calculateCreatinineEGFR(scr: Double, age: Double, isFemale: Bool) -> Double {
        let kappa = isFemale ? 0.7 : 0.9
        let alpha = scr <= kappa ? -0.241 : -1.200
        let sexFactor = isFemale ? 1.012 : 1.0
        
        let eGFR = 142.0 * pow(scr / kappa, alpha) * pow(0.9938, age) * sexFactor
        return eGFR
    }
    
    private func calculateCystatinEGFR(scys: Double, age: Double, isFemale: Bool) -> Double {
        let alpha = scys <= 0.8 ? -0.499 : -1.328
        let sexFactor = isFemale ? 0.932 : 1.0
        
        let eGFR = 133.0 * pow(scys / 0.8, alpha) * pow(0.996, age) * sexFactor
        return eGFR
    }
    
    private func calculateCombinedEGFR(scr: Double, scys: Double, age: Double, isFemale: Bool) -> Double {
        let kappa = isFemale ? 0.7 : 0.9
        let alphaScr = scr <= kappa ? -0.219 : -0.544
        let alphaScys = scys <= 0.8 ? -0.323 : -0.778
        let sexFactor = isFemale ? 0.963 : 1.0
        
        let eGFR = 135.0 * pow(scr / kappa, alphaScr) * pow(scys / 0.8, alphaScys) * pow(0.9961, age) * sexFactor
        return eGFR
    }
    
    private func getCKDStage(_ gfr: Double) -> (stage: String, description: String, color: Color) {
        switch gfr {
        case 90...:
            return ("Stage 1", "Normal or high", .green)
        case 60..<90:
            return ("Stage 2", "Mildly decreased", .yellow)
        case 45..<60:
            return ("Stage 3a", "Mild to moderate", .orange)
        case 30..<45:
            return ("Stage 3b", "Moderate to severe", .orange)
        case 15..<30:
            return ("Stage 4", "Severely decreased", .red)
        default:
            return ("Stage 5", "Kidney failure", .purple)
        }
    }
    
    private var isLastField: Bool {
        if let currentField = focusedField {
            switch currentField {
            case .cystatinC:
                return true
            case .age:
                return !useCystatinC
            default:
                return false
            }
        }
        return false
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        let fields: [Field]
        if useCystatinC {
            fields = [.creatinine, .cystatinC, .age]
        } else {
            fields = [.creatinine, .age]
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
    
    private func updateToolbarState() {
        keyboardToolbar.isActive = focusedField != nil
        keyboardToolbar.isFirstField = focusedField == .creatinine
        keyboardToolbar.isLastField = isLastField
        keyboardToolbar.onBack = { moveFocus(direction: .back) }
        keyboardToolbar.onForward = { moveFocus(direction: .forward) }
        keyboardToolbar.onDismiss = { focusedField = nil }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Input Fields
            VStack(alignment: .leading, spacing: 16) {
                
                // Sex Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sex")
                        .foregroundColor(.indigo)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    Picker("Sex", selection: $sex) {
                        ForEach(Sex.allCases, id: \.self) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Creatinine (Scr)")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mg/dL", text: $creatinine)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .creatinine)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" years", text: $age)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .age)
                }
                
                // Cystatin C toggle and input
                Toggle("Include Cystatin C", isOn: $useCystatinC)
                    .fontWeight(.medium)
                    .tint(.purple)
                
                if useCystatinC {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cystatin C (Scys)")
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                            .font(.subheadline)
                        TextField(" mg/L", text: $cystatinC)
                            .textFieldStyle(SoftTextFieldStyle())
                            #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                            .focused($focusedField, equals: .cystatinC)
                    }
                    .transition(.opacity)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onChange(of: useCystatinC) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }
            
            // Results
            if let gfr = eGFR {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Main eGFR Result
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(useCystatinC ? "eGFR (Combined)" : "eGFR (Creatinine)")
                                .font(.subheadline)
                                .foregroundColor(.teal)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mL/min/1.73m²", gfr))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        // CKD Stage
                        VStack(alignment: .trailing, spacing: 4) {
                            let stage = getCKDStage(gfr)
                            Text(stage.stage)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(stage.description)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(stage.color.opacity(0.2))
                                .foregroundColor(stage.color)
                                .cornerRadius(6)
                        }
                    }
                    
                    // Individual eGFR values when using cystatin C
                    if useCystatinC {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("eGFR (Creatinine only)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                                if let crOnly = eGFRCreatinineOnly {
                                    Text(String(format: "%.1f mL/min/1.73m²", crOnly))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("eGFR (Cystatin C only)")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                    .fontWeight(.semibold)
                                if let cysOnly = eGFRCystatinOnly {
                                    Text(String(format: "%.1f mL/min/1.73m²", cysOnly))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: eGFR)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("CKD-EPI 2021 Equations")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("Creatinine:")
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("eGFR = 142 × (Scr/κ)^α × 0.9938^age [× 1.012 if female]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                Text("κ = 0.7 (female) or 0.9 (male)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("α = -0.241 (Scr ≤ κ) or -1.200 (Scr > κ)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                Text("Cystatin C:")
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("eGFR = 133 × (Scys/0.8)^α × 0.996^age [× 0.932 if female]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                Text("α = -0.499 (Scys ≤ 0.8) or -1.328 (Scys > 0.8)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                Text("Combined (Scr + Scys):")
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("eGFR = 135 × (Scr/κ)^α₁ × (Scys/0.8)^α₂ × 0.9961^age [× 0.963 if female]")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            
            // CKD Stages
            VStack(alignment: .leading, spacing: 8) {
                Text("CKD Stages")
                    .font(.headline)
                    .foregroundColor(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stage 1: ≥90 - Normal or high")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    Text("Stage 2: 60-89 - Mildly decreased")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    Text("Stage 3a: 45-59 - Mild to moderate")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    Text("Stage 3b: 30-44 - Moderate to severe")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    Text("Stage 4: 15-29 - Severely decreased")
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                    Text("Stage 5: <15 - Kidney failure")
                        .font(.system(.body, design: .default))
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
                    Text("CKD-EPI — Chronic Kidney Disease Epidemiology Collaboration")
                    Text("eGFR — Estimated Glomerular Filtration Rate")
                    Text("Scr — Serum Creatinine")
                    Text("Scys — Serum Cystatin C")
                    Text("CKD — Chronic Kidney Disease")
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
        CKDEPICalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

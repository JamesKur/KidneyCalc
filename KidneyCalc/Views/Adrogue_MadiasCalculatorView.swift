import SwiftUI

struct Adrogue_MadiasCalculatorView: View {
    @State private var currentSodium: String = ""
    @State private var infusolateSodium: String = ""
    @State private var weight: String = ""
    @State private var fluidVolume: String = ""
    @State private var volumeUnit: VolumeUnit = .liters
    @State private var sex: Sex = .male
    @State private var ageGroup: AgeGroup = .adult
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState
    
    enum Sex: String, CaseIterable {
        case male = "Male"
        case female = "Female"
    }
    
    enum AgeGroup: String, CaseIterable {
        case adult = "Adult"
        case elderly = "Elderly (>65 years)"
    }
    
    enum VolumeUnit: String, CaseIterable {
        case liters = "Liters"
        case milliliters = "mL"
    }
    
    enum Field: Hashable {
        case sodium, infusate, weight, volume
    }
    
    private var totalBodyWater: Double? {
        guard let w = Double(weight), w > 0 else {
            return nil
        }
        
        switch (sex, ageGroup) {
        case (.male, .adult):
            return 0.6 * w
        case (.male, .elderly):
            return 0.5 * w
        case (.female, .adult):
            return 0.5 * w
        case (.female, .elderly):
            return 0.45 * w
        }
    }
    
    private var sodiumpredictedChange: Double? {
        guard let na_serum = Double(currentSodium),
              let na_infusate = Double(infusolateSodium),
              let volume = Double(fluidVolume),
              volume > 0,
              let tbw = totalBodyWater else {
            return nil
        }
        
        // Convert volume to liters if needed
        let volumeInLiters = volumeUnit == .liters ? volume : volume / 1000.0
        
        // ΔNa = (Na_infusate - Na_serum) × Volume(L) / (TBW + 1)
        return (na_infusate - na_serum) * volumeInLiters / (tbw + 1)
    }
    
    private var predictedSodium: Double? {
        guard let current = Double(currentSodium),
              let change = sodiumpredictedChange else {
            return nil
        }
        return current + change
    }
    
    private func getSodiumStatus(_ na: Double) -> (status: String, color: Color) {
        switch na {
        case ..<135:
            return ("Hyponatremia", .blue)
        case 135...145:
            return ("Normal", .green)
        default:
            return ("Hypernatremia", .red)
        }
    }
    
    private func getCommonFluids() -> [(name: String, sodium: Double)] {
        return [
            ("0.9% NS", 154),
            ("0.45% NS", 77),
            ("Lactated Ringer's", 130),
            ("D5W", 0),
            ("2% Saline", 342),
            ("3% Hypertonic Saline", 513)
        ]
    }
    
    private var isLastField: Bool {
        return focusedField == .volume
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        let fields: [Field] = [.sodium, .infusate, .weight, .volume]
            
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
                    Text("Current Sodium")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $currentSodium)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .sodium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fluid Sodium")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $infusolateSodium)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .infusate)
                }
                
                // Common fluids quick reference
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(getCommonFluids(), id: \.name) { fluid in
                            Button(action: {
                                infusolateSodium = String(format: "%.0f", fluid.sodium)
                            }) {
                                Text(fluid.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .capsule)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .foregroundColor(.teal)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" kg", text: $weight)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .weight)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fluid Volume")
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    HStack {
                        TextField("", text: $fluidVolume)
                            .textFieldStyle(SoftTextFieldStyle())
                            #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                            .focused($focusedField, equals: .volume)
                        
                        Picker("Unit", selection: $volumeUnit) {
                            ForEach(VolumeUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 130)
                    }
                }
                
                // Sex and Age Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Demographics")
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    
                    Picker("Sex", selection: $sex) {
                        ForEach(Sex.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Age Group", selection: $ageGroup) {
                        ForEach(AgeGroup.allCases, id: \.self) { ag in
                            Text(ag.rawValue).tag(ag)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }
            
            // Results
            if let current = Double(currentSodium),
               let change = sodiumpredictedChange,
               let predicted = predictedSodium,
               let tbw = totalBodyWater {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Current Sodium
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Sodium")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mEq/L", current))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        let status = getSodiumStatus(current)
                        Text(status.status)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.color.opacity(0.2))
                            .foregroundColor(status.color)
                            .cornerRadius(6)
                    }
                    
                    Divider()
                    
                    // Predicted Change
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Predicted ΔNa")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                            Text(String(format: "%+.2f mEq/L", change))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("TBW")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f L", tbw))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Divider()
                    
                    // Predicted Sodium
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Predicted Sodium")
                                .font(.subheadline)
                                .foregroundColor(.teal)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mEq/L", predicted))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        let status = getSodiumStatus(predicted)
                        Text(status.status)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.color.opacity(0.2))
                            .foregroundColor(status.color)
                            .cornerRadius(6)
                    }
                    
                    // Interpretation
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interpretation")
                            .font(.subheadline)
                            .foregroundColor(.indigo)
                            .fontWeight(.semibold)
                        
                        let direction = change > 0 ? "increase" : "decrease"
                        let text = "Administering this fluid is predicted to \(direction) sodium by approximately \(String(format: "%.2f", abs(change))) mEq/L. Use cautiously as rates of sodium change >8 mEq/L per day increase risk of osmotic complications."
                        
                        Text(text)
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
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: predictedSodium)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Adrogue-Madias Formula")
                    .font(.headline)
                    .foregroundColor(.orange)
                formulaText("ΔNa = (Na_infusate - Na_serum) × Volume(L) / (TBW + 1)")
                    .foregroundColor(.primary)
                Text("TBW Calculation:")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                Text("Adult: Male 0.6 × wt, Female 0.5 × wt\nElderly: Male 0.5 × wt, Female 0.45 × wt")
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
                    Text("• Safe correction rate: 10-12 mEq/L per day maximum")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Avoid >10-12 mEq/L change per 24h (osmotic demyelination risk)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Rapid correction of hyponatremia can cause central pontine myelinolysis")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Consider sodium monitoring q2-4h during active correction")
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
                    Text("TBW — Total Body Water")
                    Text("NS — Normal Saline")
                    Text("D5W — Dextrose 5% in Water")
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
        Adrogue_MadiasCalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

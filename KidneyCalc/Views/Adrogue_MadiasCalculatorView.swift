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
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
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
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: predictedSodium)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Adrogue-Madias Formula")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("ΔNa = (Na_infusate - Na_serum) × Volume(L) / (TBW + 1)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("TBW Calculation:")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                Text("Adult: Male 0.6 × wt, Female 0.5 × wt\nElderly: Male 0.5 × wt, Female 0.45 × wt")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
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
        Adrogue_MadiasCalculatorView()
            .padding()
    }
}

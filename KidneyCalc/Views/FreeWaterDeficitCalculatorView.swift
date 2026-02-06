import SwiftUI

struct FreeWaterDeficitCalculatorView: View {
    @State private var currentSodium: String = ""
    @State private var desiredSodium: String = "140"
    @State private var weight: String = ""
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
    
    enum Field: Hashable {
        case currentSodium, desiredSodium, weight
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
    
    private var freeWaterDeficit: Double? {
        guard let na_current = Double(currentSodium),
              let na_desired = Double(desiredSodium),
              let tbw = totalBodyWater,
              na_current > na_desired else {
            return nil
        }
        
        // Free Water Deficit = TBW × (Na_current - Na_desired) / Na_desired
        return tbw * (na_current - na_desired) / na_desired
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
    
    private func getHypernatremiaSeverity(_ na: Double) -> String? {
        if na > 145 {
            if na > 160 {
                return "Severe"
            } else if na > 155 {
                return "Moderate"
            } else {
                return "Mild"
            }
        }
        return nil
    }
    
    private var estimatedCorrectionTime: [(hours: Double, deficitPercent: Double)] {
        return [
            (24, 0.5),   // 50% in 24 hours
            (48, 1.0),   // 100% (full correction) in 48 hours
        ]
    }
    
    private var isLastField: Bool {
        return focusedField == .weight
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        let fields: [Field] = [.currentSodium, .desiredSodium, .weight]
            
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
                        .focused($focusedField, equals: .currentSodium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Desired Sodium")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $desiredSodium)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .desiredSodium)
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
                        .disabled(focusedField == .currentSodium)
                        
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
               let desired = Double(desiredSodium),
               let deficit = freeWaterDeficit,
               let tbw = totalBodyWater,
               current > desired {
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
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(status.status)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(status.color.opacity(0.2))
                                .foregroundColor(status.color)
                                .cornerRadius(6)
                            if let severity = getHypernatremiaSeverity(current) {
                                Text(severity)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Free Water Deficit
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Free Water Deficit")
                                .font(.subheadline)
                                .foregroundColor(.teal)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f L", deficit))
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
                    
                    // Goal sodium and deficit percentage
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Goal Sodium")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mEq/L", desired))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Deficit %")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            let percentage = (deficit / tbw) * 100
                            Text(String(format: "%.1f%%", percentage))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Correction schedule
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Correction Schedule")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                        
                        ForEach(estimatedCorrectionTime, id: \.hours) { item in
                            HStack {
                                Text(String(format: "%.0f hours:", item.hours))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f L", deficit * item.deficitPercent))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(String(format: "(%.1f mL/hr)", (deficit * item.deficitPercent * 1000) / item.hours))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Interpretation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interpretation")
                            .font(.subheadline)
                            .foregroundColor(.indigo)
                            .fontWeight(.semibold)
                        Text("Free water deficit represents the volume of free water needed to dilute serum sodium to the desired level. Safe correction is typically 8-10 mEq/L per 24 hours maximum to avoid cerebral edema from too-rapid correction.")
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
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: freeWaterDeficit)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formula")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("Free Water Deficit = TBW × (Na_current - Na_desired) / Na_desired")
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
                    Text("• Safe correction: 8-10 mEq/L per 24 hours maximum")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Too-rapid correction can cause cerebral edema")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Free water sources: D5W, 0.45% NS, or free water")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Monitor sodium every 2-4 hours during acute correction")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Address underlying cause (diabetes insipidus, etc.)")
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
        FreeWaterDeficitCalculatorView()
            .padding()
    }
}

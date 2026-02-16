import SwiftUI

struct BicarbonateDeficitCalculatorView: View {
    @State private var currentBicarbonate: String = ""
    @State private var desiredBicarbonate: String = "24"
    @State private var weight: String = ""
    @State private var distributionVolume: DistributionVolume = .standard
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState
    
    enum DistributionVolume: String, CaseIterable {
        case standard = "0.5 × wt (Standard)"
        
        var multiplier: Double {
            switch self {
            case .standard:
                return 0.5
            }
        }
    }
    
    enum Field: Hashable {
        case currentBicarbonate, desiredBicarbonate, weight
    }
    
    private var bicarbonateSpace: Double? {
        guard let w = Double(weight), w > 0 else {
            return nil
        }
        return distributionVolume.multiplier * w
    }
    
    private var bicarbonateDeficit: Double? {
        guard let current = Double(currentBicarbonate),
              let desired = Double(desiredBicarbonate),
              let space = bicarbonateSpace,
              current < desired else {
            return nil
        }
        
        // Bicarbonate Deficit (mEq) = (Desired HCO3 - Current HCO3) × Distribution Volume
        return (desired - current) * space
    }
    
    private func getBicarbonateStatus(_ hco3: Double) -> (status: String, color: Color) {
        switch hco3 {
        case ..<22:
            return ("Low (Acidosis)", .red)
        case 22...26:
            return ("Normal", .green)
        default:
            return ("High (Alkalosis)", .blue)
        }
    }
    
    private func getAcidosisSeverity(_ hco3: Double) -> String? {
        if hco3 < 22 {
            if hco3 < 15 {
                return "Severe"
            } else if hco3 < 18 {
                return "Moderate"
            } else {
                return "Mild"
            }
        }
        return nil
    }
    
    private var ampulesRequired: [(concentration: String, ampuleSize: Double, ampulesNeeded: Double)] {
        guard let deficit = bicarbonateDeficit else { return [] }
        
        // Common sodium bicarbonate preparations
        // 8.4% NaHCO3 = 1 mEq/mL (50 mL ampule = 50 mEq)
        // 7.5% NaHCO3 = 0.892 mEq/mL (50 mL ampule = 44.6 mEq)
        let preparations: [(String, Double, Double)] = [
            ("8.4% (1 mEq/mL)", 50.0, 50.0),   // 50 mL ampule with 50 mEq
            ("7.5% (0.892 mEq/mL)", 50.0, 44.6) // 50 mL ampule with 44.6 mEq
        ]
        
        return preparations.map { (conc, size, meq) in
            let ampules = deficit / meq
            return (conc, size, ampules)
        }
    }
    
    private var isLastField: Bool {
        return focusedField == .weight
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        let fields: [Field] = [.currentBicarbonate, .desiredBicarbonate, .weight]
            
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
        keyboardToolbar.isFirstField = focusedField == .currentBicarbonate
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
                    Text("Current Bicarbonate")
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $currentBicarbonate)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .currentBicarbonate)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Desired Bicarbonate")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $desiredBicarbonate)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .desiredBicarbonate)
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
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }
            
            // Results
            if let current = Double(currentBicarbonate),
               let desired = Double(desiredBicarbonate),
               let deficit = bicarbonateDeficit,
               let space = bicarbonateSpace,
               current < desired {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Current Bicarbonate
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Bicarbonate")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mEq/L", current))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        let status = getBicarbonateStatus(current)
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(status.status)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(status.color.opacity(0.2))
                                .foregroundColor(status.color)
                                .cornerRadius(6)
                            if let severity = getAcidosisSeverity(current) {
                                Text(severity)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Bicarbonate Deficit
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bicarbonate Deficit")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                            Text(String(format: "%.0f mEq", deficit))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Dist. Volume")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f L", space))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Goal bicarbonate
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Goal Bicarbonate")
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
                            Text("Change Needed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            Text(String(format: "+%.1f mEq/L", desired - current))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Sodium Bicarbonate Requirements
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sodium Bicarbonate Requirements")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                        
                        ForEach(ampulesRequired, id: \.concentration) { prep in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(prep.concentration)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                HStack {
                                    Text(String(format: "%.1f ampules", prep.ampulesNeeded))
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .fontWeight(.bold)
                                    Text(String(format: "(%.0f mL total)", prep.ampulesNeeded * prep.ampuleSize))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                if prep.ampulesNeeded > 1 {
                                    Text("Consider administering in divided doses")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .italic()
                                }
                            }
                            .padding(.vertical, 6)
                            if prep.concentration != ampulesRequired.last?.concentration {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
                    
                    // Interpretation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interpretation")
                            .font(.subheadline)
                            .foregroundColor(.indigo)
                            .fontWeight(.semibold)
                        Text("The bicarbonate deficit represents the total amount of sodium bicarbonate needed to raise serum bicarbonate to the desired level. This calculation typically replaces 50% of the calculated deficit initially, then reassess. IV sodium bicarbonate is typically reserved for severe metabolic acidosis (pH < 7.1 or HCO3 < 10 mEq/L).")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
                    }
                }
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: bicarbonateDeficit)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formula")
                    .font(.headline)
                    .foregroundColor(.orange)
                formulaText("Bicarbonate Deficit (mEq) = (Desired HCO_3 - Current HCO_3) × 0.5")
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
                    Text("IV — Intravenous")
                    Text("mEq — Milliequivalents")
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
        BicarbonateDeficitCalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

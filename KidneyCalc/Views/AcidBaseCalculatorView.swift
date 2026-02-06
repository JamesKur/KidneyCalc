import SwiftUI

struct AcidBaseCalculatorView: View {
    @State private var pH: String = ""
    @State private var bicarbonate: String = ""
    @State private var pco2: String = ""
    @State private var isAcute: Bool = true
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case pH, bicarbonate, pco2
    }
    
    private var isValidInput: Bool {
        guard let ph = Double(pH),
              let hco3 = Double(bicarbonate),
              let co2 = Double(pco2) else {
            return false
        }
        return ph > 0 && hco3 > 0 && co2 > 0
    }
    
    private var acidBaseInterpretation: (primary: String, secondary: String?, notes: [String])? {
        guard let ph = Double(pH),
              let hco3 = Double(bicarbonate),
              let co2 = Double(pco2) else {
            return nil
        }
        
        var primary = ""
        var secondary: String? = nil
        var notes: [String] = []
        
        // Determine if acidemia or alkalemia
        let isAcidemia = ph < 7.35
        let isAlkalemia = ph > 7.45
        _ = ph >= 7.35 && ph <= 7.45  // Normal pH range
        
        // Check if HCO3 and PCO2 are abnormal
        let hco3Low = hco3 < 24
        let hco3High = hco3 > 24
        let pco2Low = co2 < 40
        let pco2High = co2 > 40
        
        // Determine primary disorder
        if isAcidemia {
            if hco3Low && pco2High {
                // Could be metabolic or respiratory
                primary = "Metabolic Acidosis (primary)"
                secondary = checkMetabolicAcidosisSecondary(pco2: co2, hco3: hco3, isAcute: isAcute)
            } else if hco3Low {
                primary = "Metabolic Acidosis"
                secondary = checkMetabolicAcidosisSecondary(pco2: co2, hco3: hco3, isAcute: isAcute)
            } else if pco2High {
                primary = "Respiratory Acidosis"
                secondary = checkRespiratoryAcidosisSecondary(pco2: co2, hco3: hco3, isAcute: isAcute)
            } else {
                primary = "Acidemia"
            }
        } else if isAlkalemia {
            if hco3High && pco2Low {
                // Could be metabolic or respiratory
                primary = "Metabolic Alkalosis (primary)"
                secondary = checkMetabolicAlkalosisSecondary(pco2: co2, hco3: hco3)
            } else if hco3High {
                primary = "Metabolic Alkalosis"
                secondary = checkMetabolicAlkalosisSecondary(pco2: co2, hco3: hco3)
            } else if pco2Low {
                primary = "Respiratory Alkalosis"
                secondary = checkRespiratoryAlkalosisSecondary(pco2: co2, hco3: hco3, isAcute: isAcute)
            } else {
                primary = "Alkalemia"
            }
        } else {
            // Normal pH - check for mixed disorders
            if hco3Low && pco2High {
                primary = "Concurrent Metabolic Acidosis & Respiratory Acidosis"
            } else if hco3High && pco2Low {
                primary = "Concurrent Metabolic Alkalosis & Respiratory Alkalosis"
            } else if hco3Low && pco2Low {
                primary = "Concurrent Metabolic Acidosis & Respiratory Alkalosis"
            } else if hco3High && pco2High {
                primary = "Concurrent Metabolic Alkalosis & Respiratory Acidosis"
            } else {
                primary = "Normal acid-base status"
            }
        }
        
        // Add interpretation notes
        notes.append("pH: \(String(format: "%.2f", ph)) (\(isAcidemia ? "Acidemia" : isAlkalemia ? "Alkalemia" : "Normal"))")
        notes.append("HCO3: \(String(format: "%.1f", hco3)) mEq/L (\(hco3Low ? "Low" : hco3High ? "High" : "Normal"))")
        notes.append("PCO2: \(String(format: "%.1f", co2)) mmHg (\(pco2Low ? "Low" : pco2High ? "High" : "Normal"))")
        
        return (primary: primary, secondary: secondary, notes: notes)
    }
    
    private func checkMetabolicAcidosisSecondary(pco2: Double, hco3: Double, isAcute: Bool) -> String? {
        // Winter's formula: Expected PCO2 = 1.5 × [HCO3] + 8 ± 2
        let expectedPCO2Lower = (1.5 * hco3) + 8 - 2
        let expectedPCO2Upper = (1.5 * hco3) + 8 + 2
        
        if pco2 > expectedPCO2Upper {
            return "Secondary Respiratory Acidosis (inadequate respiratory compensation)"
        } else if pco2 < expectedPCO2Lower {
            return "Secondary Respiratory Alkalosis (excessive respiratory compensation)"
        }
        return nil
    }
    
    private func checkRespiratoryAcidosisSecondary(pco2: Double, hco3: Double, isAcute: Bool) -> String? {
        let deltaPCO2 = pco2 - 40
        
        if isAcute {
            // Acute: HCO3 increases ~1 mEq/L per 10 mmHg increase in PCO2
            let expectedHCO3 = 24 + (deltaPCO2 / 10.0)
            
            if hco3 > expectedHCO3 + 2 {
                return "Secondary Metabolic Alkalosis"
            } else if hco3 < expectedHCO3 - 2 {
                return "Secondary Metabolic Acidosis"
            }
        } else {
            // Chronic: HCO3 increases ~4 mEq/L per 10 mmHg increase in PCO2
            let expectedHCO3 = 24 + ((deltaPCO2 / 10.0) * 4)
            
            if hco3 > expectedHCO3 + 2 {
                return "Secondary Metabolic Alkalosis"
            } else if hco3 < expectedHCO3 - 2 {
                return "Secondary Metabolic Acidosis"
            }
        }
        return nil
    }
    
    private func checkMetabolicAlkalosisSecondary(pco2: Double, hco3: Double) -> String? {
        // Expected PCO2 = 0.7 × [HCO3] + 20 ± 5
        let expectedPCO2Lower = (0.7 * hco3) + 20 - 5
        let expectedPCO2Upper = (0.7 * hco3) + 20 + 5
        
        if pco2 < expectedPCO2Lower {
            return "Secondary Respiratory Alkalosis (excessive respiratory compensation)"
        } else if pco2 > expectedPCO2Upper {
            return "Secondary Respiratory Acidosis (inadequate respiratory compensation)"
        }
        return nil
    }
    
    private func checkRespiratoryAlkalosisSecondary(pco2: Double, hco3: Double, isAcute: Bool) -> String? {
        let deltaPCO2 = 40 - pco2
        
        if isAcute {
            // Acute: HCO3 decreases ~2 mEq/L per 10 mmHg decrease in PCO2
            let expectedHCO3 = 24 - ((deltaPCO2 / 10.0) * 2)
            
            if hco3 < expectedHCO3 - 2 {
                return "Secondary Metabolic Acidosis"
            } else if hco3 > expectedHCO3 + 2 {
                return "Secondary Metabolic Alkalosis"
            }
        } else {
            // Chronic: HCO3 decreases ~5 mEq/L per 10 mmHg decrease in PCO2
            let expectedHCO3 = 24 - ((deltaPCO2 / 10.0) * 5)
            
            if hco3 < expectedHCO3 - 2 {
                return "Secondary Metabolic Acidosis"
            } else if hco3 > expectedHCO3 + 2 {
                return "Secondary Metabolic Alkalosis"
            }
        }
        return nil
    }
    
    private var isLastField: Bool {
        focusedField == .pco2
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        let fields: [Field] = [.pH, .bicarbonate, .pco2]
            
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
                
                // pH input
                VStack(alignment: .leading, spacing: 8) {
                    Text("pH")
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" 7.40", text: $pH)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .pH)
                }
                
                // HCO3 input
                VStack(alignment: .leading, spacing: 8) {
                    Text("HCO3")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $bicarbonate)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .bicarbonate)
                }
                
                // PCO2 input
                VStack(alignment: .leading, spacing: 8) {
                    Text("PCO2")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mmHg", text: $pco2)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .pco2)
                }
                
                // Acute vs Chronic toggle and input
                Toggle("Chronic respiratory process", isOn: Binding(
                    get: { !isAcute },
                    set: { isAcute = !$0 }
                ))
                    .fontWeight(.medium)
                    .tint(.purple)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.05), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: { moveFocus(direction: .back) }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .disabled(focusedField == .pH)
                        
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
            if isValidInput, let interpretation = acidBaseInterpretation {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Primary Disorder
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Primary Disorder")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .fontWeight(.semibold)
                        Text(interpretation.primary)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    }
                    
                    // Secondary Disorder (if present)
                    if let secondary = interpretation.secondary {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Secondary Disorder")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                            Text(secondary)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                        }
                    }
                    
                    // Notes
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(interpretation.notes, id: \.self) { note in
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
                .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9)), removal: .opacity))
            }
            
            // Reference Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Acid-Base Interpretation Rules")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Normal Values:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("• pH: 7.35 - 7.45")
                        .font(.caption2)
                    Text("• HCO3: 22 - 26 mEq/L")
                        .font(.caption2)
                    Text("• PCO2: 35 - 45 mmHg")
                        .font(.caption2)
                }
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Winter's Formula (Metabolic Acidosis):")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Expected PCO2 = 1.5 × [HCO3] + 8 ± 2")
                        .font(.system(.caption2, design: .monospaced))
                }
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Metabolic Alkalosis Compensation:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Expected PCO2 = 0.7 × [HCO3] + 20 ± 5")
                        .font(.system(.caption2, design: .monospaced))
                }
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Respiratory Compensation:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Acute Respiratory Acidosis:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text("• HCO3 increases ~1 mEq/L per 10 mmHg PCO2 increase")
                        .font(.caption2)
                    Text("Chronic Respiratory Acidosis:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text("• HCO3 increases ~4 mEq/L per 10 mmHg PCO2 increase")
                        .font(.caption2)
                    Text("Acute Respiratory Alkalosis:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text("• HCO3 decreases ~2 mEq/L per 10 mmHg PCO2 decrease")
                        .font(.caption2)
                    Text("Chronic Respiratory Alkalosis:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text("• HCO3 decreases ~5 mEq/L per 10 mmHg PCO2 decrease")
                        .font(.caption2)
                }
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
        }
    }
}

#Preview {
    ScrollView {
        AcidBaseCalculatorView()
            .padding()
    }
}

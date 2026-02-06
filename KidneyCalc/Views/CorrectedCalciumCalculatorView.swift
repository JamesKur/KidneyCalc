import SwiftUI

struct CorrectedCalciumCalculatorView: View {
    @State private var totalCalcium: String = ""
    @State private var albumin: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case calcium, albumin
    }
    
    private var correctedCalcium: Double? {
        guard let ca = Double(totalCalcium),
              let alb = Double(albumin) else {
            return nil
        }
        // Corrected Ca = Total Ca + 0.8 × (4.0 - Albumin)
        return ca + 0.8 * (4.0 - alb)
    }
    
    private func getCalciumStatus(_ ca: Double) -> (status: String, color: Color) {
        switch ca {
        case ..<8.5:
            return ("Hypocalcemia", .blue)
        case 8.5...10.5:
            return ("Normal", .green)
        default:
            return ("Hypercalcemia", .red)
        }
    }
    
    private func getSeverity(_ ca: Double) -> String? {
        if ca < 8.5 {
            if ca < 7.0 {
                return "Severe"
            } else if ca < 8.0 {
                return "Moderate"
            } else {
                return "Mild"
            }
        } else if ca > 10.5 {
            if ca > 13.0 {
                return "Severe"
            } else if ca > 12.0 {
                return "Moderate"
            } else {
                return "Mild"
            }
        }
        return nil
    }
    
    private var isLastField: Bool {
        return focusedField == .albumin
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        let fields: [Field] = [.calcium, .albumin]
            
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
            // Disclaimer
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clinical Disclaimer")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        Text("This correction may not be accurate, especially in critically ill patients, patients with renal failure, malnutrition, or liver disease. Direct ionized calcium measurement is preferred when accuracy is critical.")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            // Input Fields
            VStack(alignment: .leading, spacing: 16) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Calcium")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mg/dL", text: $totalCalcium)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .calcium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Albumin")
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" g/dL", text: $albumin)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .albumin)
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
                        .disabled(focusedField == .calcium)
                        
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
            if let ca = Double(totalCalcium),
               let correctedCa = correctedCalcium {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Total Calcium
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Calcium")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mg/dL", ca))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        // Status
                        VStack(alignment: .trailing, spacing: 4) {
                            let status = getCalciumStatus(ca)
                            Text(status.status)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(status.color.opacity(0.2))
                                .foregroundColor(status.color)
                                .cornerRadius(6)
                            if let severity = getSeverity(ca) {
                                Text(severity)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Corrected Calcium
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Corrected Calcium")
                                .font(.subheadline)
                                .foregroundColor(.teal)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mg/dL", correctedCa))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        // Status
                        VStack(alignment: .trailing, spacing: 4) {
                            let status = getCalciumStatus(correctedCa)
                            Text(status.status)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(status.color.opacity(0.2))
                                .foregroundColor(status.color)
                                .cornerRadius(6)
                            if let severity = getSeverity(correctedCa) {
                                Text(severity)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Correction amount
                    if let alb = Double(albumin) {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Correction Amount")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                    .fontWeight(.semibold)
                                Text(String(format: "%.1f mg/dL", correctedCa - ca))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Albumin")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.semibold)
                                Text(String(format: "%.1f g/dL", alb))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // Interpretation
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interpretation")
                            .font(.subheadline)
                            .foregroundColor(.indigo)
                            .fontWeight(.semibold)
                        Text("Low albumin decreases serum calcium due to reduced protein binding. This correction accounts for that effect, but the actual physiologically available (ionized) calcium may differ, especially in critical illness.")
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
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: correctedCalcium)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formulas")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("Corrected Ca = Total Ca + 0.8 × (4.0 - Albumin)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                Text("Note: Assumes albumin in g/dL and calcium in mg/dL")
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
                Text("Reference Ranges")
                    .font(.headline)
                    .foregroundColor(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Calcium: 8.5-10.5 mg/dL")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("Albumin: 3.5-5.0 g/dL")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("Ionized Calcium: 4.5-5.1 mg/dL (preferred)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hypocalcemia")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Mild: 8.0-8.5 mg/dL | Moderate: 7.0-8.0 | Severe: <7.0")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text("Hypercalcemia")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 2)
                    Text("Mild: 10.5-12.0 mg/dL | Moderate: 12.0-13.0 | Severe: >13.0")
                        .font(.system(.caption2, design: .monospaced))
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
        CorrectedCalciumCalculatorView()
            .padding()
    }
}

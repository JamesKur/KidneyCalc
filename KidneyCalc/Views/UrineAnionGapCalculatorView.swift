import SwiftUI

struct UrineAnionGapCalculatorView: View {
    @State private var urineNa: String = ""
    @State private var urineK: String = ""
    @State private var urineCl: String = ""
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var keyboardToolbar: KeyboardToolbarState
    
    enum Field: Hashable {
        case urineNa, urineK, urineCl
    }
    
    // UAG = (Na⁺ + K⁺) − Cl⁻
    private var urineAnionGap: Double? {
        guard let na = Double(urineNa),
              let k = Double(urineK),
              let cl = Double(urineCl) else {
            return nil
        }
        return (na + k) - cl
    }
    
    private var interpretation: (title: String, detail: String, color: Color)? {
        guard let uag = urineAnionGap else { return nil }
        if uag < 0 {
            return (
                "Negative (GI bicarbonate loss likely)",
                "A negative urine anion gap suggests intact renal ammonium (NH₄⁺) excretion. The kidneys are appropriately increasing acid excretion. This pattern is typical of extrarenal causes of normal anion gap metabolic acidosis such as diarrhea.",
                .green
            )
        } else if uag >= 0 && uag <= 10 {
            return (
                "Borderline / Indeterminate",
                "A urine anion gap near zero may be seen early in the course of acidosis or with mixed etiologies. Clinical correlation is recommended.",
                .orange
            )
        } else {
            return (
                "Positive (Renal tubular acidosis likely)",
                "A positive urine anion gap suggests impaired renal ammonium excretion. This pattern is consistent with renal tubular acidosis (RTA) — the kidneys are unable to appropriately excrete acid. Consider Type 1 (distal) or Type 4 RTA.",
                .red
            )
        }
    }
    
    private var isLastField: Bool {
        return focusedField == .urineCl
    }
    
    private func moveFocus(direction: NavigationDirection) {
        guard let current = focusedField else { return }
        
        let fields: [Field] = [.urineNa, .urineK, .urineCl]
        
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
        keyboardToolbar.isFirstField = focusedField == .urineNa
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
                    Text("Urine Sodium")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $urineNa)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .urineNa)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Urine Potassium")
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $urineK)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .urineK)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Urine Chloride")
                        .foregroundColor(.teal)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    TextField(" mEq/L", text: $urineCl)
                        .textFieldStyle(SoftTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .urineCl)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .onChange(of: focusedField) { _, _ in updateToolbarState() }
            .onDisappear { keyboardToolbar.isActive = false }
            
            // Results
            if let uag = urineAnionGap,
               let interp = interpretation {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // UAG Value
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Urine Anion Gap")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                            Text(String(format: "%.1f mEq/L", uag))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        Text(uag < 0 ? "Negative" : uag <= 10 ? "Borderline" : "Positive")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(interp.color.opacity(0.2))
                            .foregroundColor(interp.color)
                            .cornerRadius(6)
                    }
                    
                    Divider()
                    
                    // Component breakdown
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Na⁺ + K⁺")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            if let na = Double(urineNa), let k = Double(urineK) {
                                Text(String(format: "%.1f mEq/L", na + k))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Cl⁻")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            if let cl = Double(urineCl) {
                                Text(String(format: "%.1f mEq/L", cl))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Interpretation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interpretation")
                            .font(.subheadline)
                            .foregroundColor(.indigo)
                            .fontWeight(.semibold)
                        
                        Text(interp.title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(interp.color)
                        
                        Text(interp.detail)
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
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: urineAnionGap)
            }
            
            // Formula Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("Formula")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("UAG = (Na⁺ + K⁺) − Cl⁻")
                    .font(.system(.body, design: .monospaced))
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
                    Text("• Used to differentiate causes of NAGMA")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Negative UAG → GI losses (e.g., diarrhea)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Positive UAG → Impaired renal NH₄⁺ excretion (RTA)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Unreliable if urine contains unmeasured anions")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("  (e.g., ketoacids, hippurate, D-lactate)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Requires spot urine Na, K, and Cl")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("• Best used in the setting of NAGMA with normal AG")
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
                    Text("UAG — Urine Anion Gap")
                    Text("NAGMA — Normal Anion Gap Metabolic Acidosis")
                    Text("RTA — Renal Tubular Acidosis")
                    Text("GI — Gastrointestinal")
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
        UrineAnionGapCalculatorView()
            .padding()
    }
    .environmentObject(KeyboardToolbarState())
}

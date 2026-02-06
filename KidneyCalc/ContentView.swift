import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: String = "All Formulas"
    @State private var isAnimating = false // <--- ADD THIS LINE
    @Environment(\.colorScheme) var colorScheme
    
    let categories = ["All Formulas", "GFR", "Electrolytes", "Acid-Base", "Bone & Mineral"]
    
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "GFR":
            return .blue
        case "Electrolytes":
            return .green
        case "Acid-Base":
            return .purple
        case "Bone & Mineral":
            return .pink
        default:
            return .orange
        }
    }
    
    let placeholderFormulas = [
        Formula(
            name: "CKD-EPI 2021",
            category: "GFR",
            description: "Calculate eGFR using CKD-EPI 2021 equation (race-free) with optional cystatin C",
            equation: "eGFR = 142 × (Scr/κ)^α × 0.9938^age [× 1.012 if female]",
            variables: [
                "Scr: Serum Creatinine (mg/dL)",
                "Scys: Serum Cystatin C (mg/L)",
                "Age: years",
                "Sex: Male or Female"
            ],
            references: [
                "Inker LA, Eneanya ND, Coresh J, et al. New creatinine- and cystatin C-based equations to estimate GFR without race. N Engl J Med. 2021;385:1737-1749."
            ]
        ),
        Formula(
            name: "Glucose Correction for Sodium",
            category: "Electrolytes",
            description: "Correct measured sodium for hyperglycemia-induced dilutional hyponatremia",
            equation: "Corrected Na = Measured Na + 0.016 × (Glucose - 100)",
            variables: [
                "Measured Na: Serum Sodium (mEq/L)",
                "Glucose: Serum Glucose (mg/dL)"
            ],
            references: [
                "Katz MA. Hyperglycemia-induced hyponatremia: calculation of expected serum sodium decrease. N Engl J Med. 1973;289:843-844.",
                "Hillier TA, Abbott RD, Barrett EJ. Hyponatremia: evaluating the correction factor for hyperglycemia. Am J Med. 1999 Apr;106(4):399-403. doi: 10.1016/s0002-9343(99)00055-8. PMID: 10225241."
            ]
        ),
        Formula(
            name: "Adrogue-Madias Sodium Prediction",
            category: "Electrolytes",
            description: "Predict sodium change with IV fluid administration",
            equation: "ΔNa = (Na_infusate - Na_serum) × Volume(L) / (TBW + 1)",
            variables: [
                "Na_infusate: Sodium in fluid (mEq/L)",
                "Na_serum: Current serum sodium (mEq/L)",
                "TBW: Total body water (L)"
            ],
            references: [
                "Adrogue HJ, Madias NE. Hyponatremia. N Engl J Med. 2000;342:1581-1589."
            ]
        ),
        Formula(
            name: "Free Water Deficit",
            category: "Electrolytes",
            description: "Calculate free water deficit in hypernatremia",
            equation: "FWD = TBW × (Na_current - Na_desired) / Na_desired",
            variables: [
                "Na_current: Current serum sodium (mEq/L)",
                "Na_desired: Goal sodium (mEq/L)",
                "TBW: Total body water (L)"
            ],
            references: [
                "Adrogue HJ, Madias NE. Hypernatremia. N Engl J Med. 2000;342:1493-1499."
            ]
        ),
        Formula(
            name: "Corrected Calcium",
            category: "Bone & Mineral",
            description: "Correct serum calcium for hypoalbuminemia",
            equation: "Corrected Ca = Total Ca + 0.8 × (4.0 - Albumin)",
            variables: [
                "Total Ca: Total Serum Calcium (mg/dL)",
                "Albumin: Serum Albumin (g/dL)"
            ],
            references: [
                "Payne RB, Little AJ, Williams RB, Milner JR. Interpretation of serum calcium in patients with abnormal serum proteins. BMJ. 1973;4:643-646.",
                "Ghada El-Hajj Fuleihan, Gregory A Clines, Mimi I Hu, Claudio Marcocci, M Hassan Murad, Thomas Piggott, Catherine Van Poznak, Joy Y Wu, Matthew T Drake, Treatment of Hypercalcemia of Malignancy in Adults: An Endocrine Society Clinical Practice Guideline, The Journal of Clinical Endocrinology & Metabolism, Volume 108, Issue 3, March 2023, Pages 507–528."
            ]
        ),
        Formula(
            name: "Anion Gap & Delta-Delta",
            category: "Acid-Base",
            description: "Calculate anion gap and delta-delta ratio for acid-base disorders",
            equation: "AG = Na - (Cl + HCO3)\nΔΔ = (AG - 12) / (24 - HCO3)",
            variables: [
                "Na: Sodium (mEq/L)",
                "Cl: Chloride (mEq/L)",
                "HCO3: Bicarbonate (mEq/L)",
                "Normal AG: 12 mEq/L",
                "Normal HCO3: 24 mEq/L"
            ],
            references: [
                "Emmett M, Palmer B. The delta anion gap/delta HCO3 ratio in patients with a high anion gap metabolic acidosis. UpToDate.com. Published May 1, 2024. Accessed February 5, 2026. https://www.uptodate.com/contents/the-delta-anion-gap-delta-hco3-ratio-in-patients-with-a-high-anion-gap-metabolic-acidosis?search=delta%20delta&source=search_result&selectedTitle=1~56&usage_type=default&display_rank=1"
            ]
        ),
        Formula(
            name: "Acid-Base Interpretation",
            category: "Acid-Base",
            description: "Interpret acid-base disorders by analyzing pH, HCO3, and PCO2 to identify primary and secondary disorders",
            equation: "Primary disorder determined by pH and abnormal lab values; secondary disorders assessed via Winter's formula and compensation calculations",
            variables: [
                "pH: Arterial pH (7.35-7.45)",
                "HCO3: Serum Bicarbonate (22-26 mEq/L)",
                "PCO2: Arterial CO2 pressure (35-45 mmHg)",
                "Acute vs Chronic: For respiratory processes"
            ],
            references: [
                "Berend K, de Vries APJ, Gans ROB. Physiological Approach to Assessment of Acid–Base Disturbances. Ingelfinger JR, ed. New England Journal of Medicine. 2014;371(15):1434-1445."
            ]
        ),
        Formula(
            name: "Bicarbonate Deficit",
            category: "Acid-Base",
            description: "Calculate the amount of sodium bicarbonate needed to correct metabolic acidosis",
            equation: "Bicarbonate Deficit (mEq) = (Desired HCO3 - Current HCO3) × Distribution Volume",
            variables: [
                "Current HCO3: Serum Bicarbonate (mEq/L)",
                "Desired HCO3: Goal Bicarbonate (mEq/L)",
                "Distribution Volume: 0.5 × weight (kg) or 0.6 × weight (kg)"
            ],
            references: [
                "Di Iorio BR, Bellasi A, Raphael KL, Santoro D, Aucella F, Garofano L, Ceccarelli M, Di Lullo L, Capolongo G, Di Iorio M, Guastaferro P, Capasso G; UBI Study Group. Treatment of metabolic acidosis with sodium bicarbonate delays progression of chronic kidney disease: the UBI Study. J Nephrol. 2019 Dec;32(6):989-1001."
            ]
        )
    ]
    
    var filteredFormulas: [Formula] {
        if selectedCategory == "All Formulas" {
            return placeholderFormulas
        }
        return placeholderFormulas.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05),
                        Color.pink.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                // LAYER 1: The Liquid Body (Glassy Gradient)
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                .cyan.opacity(0.3), // Top is lighter/clearer
                                                .blue.opacity(0.6)  // Bottom collects the color/shadow
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    // Add a subtle border to define the edge of the water
                                    .overlay(
                                        Image(systemName: "drop")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.blue.opacity(0.3))
                                    )
                                
                                // LAYER 2: The "Wet" Shine (Specular Highlight)
                                // This creates the glossy 3D curve look
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 14)) // Smaller drop inside
                                    .scaleEffect(x: 0.7, y: 1.8) // Squeeze to look like a reflection
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white.opacity(0.9), .white.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .rotationEffect(.degrees(15)) // Tilt the reflection slightly
                                    .offset(x: -2, y: -6) // Move it to the "light source" (top left)
                                    .blur(radius: 1) // Soften the shine
                            }
                            // 3. THE ANIMATION: Gentle Bobbing & Breathing
                            // Real water doesn't spin; it floats and pulses.
                            .scaleEffect(isAnimating ? 1.05 : 1.0) // Subtle pulse
                            .offset(y: isAnimating ? -2 : 2)       // Gentle float up and down
                            .shadow(
                                color: .blue.opacity(isAnimating ? 0.3 : 0.1),
                                radius: isAnimating ? 6 : 2,
                                x: 0,
                                y: isAnimating ? 8 : 4
                            )
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 2.5)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    isAnimating = true
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("KidneyCalc")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("Nephrology Calculator")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
                    .padding(.horizontal)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.1),
                                Color.cyan.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    // Category Picker with enhanced styling
                    VStack(spacing: 16) {
                        Text("Categories")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: { 
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCategory = category
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            if selectedCategory == category {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption)
                                            }
                                            Text(category)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == category
                                                ? getCategoryColor(selectedCategory).opacity(0.8)
                                                : Color(uiColor: .secondarySystemGroupedBackground)
                                        )
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .cornerRadius(20)
                                        .scaleEffect(selectedCategory == category ? 1.05 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCategory)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                    
                    // Formula List with cards
                    List {
                        if filteredFormulas.isEmpty {
                            Text("No formulas in this category yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(filteredFormulas) { formula in
                                NavigationLink(destination: FormulaDetailView(formula: formula)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 12) {
                                            // Category color indicator
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(getCategoryColor(formula.category).opacity(0.8))
                                                .frame(width: 4)
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(formula.name)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Text(formula.description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                                
                                                HStack(spacing: 8) {
                                                    Label(formula.category, systemImage: getCategoryIcon(formula.category))
                                                        .font(.caption2)
                                                        .foregroundColor(getCategoryColor(formula.category))
                                                        .fontWeight(.semibold)
                                                    
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .navigationTitle("")
        }
    }
    
    private func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "GFR":
            return "function"
        case "Electrolytes":
            return "bolt.fill"
        case "Acid-Base":
            return "scale.3d"
        case "Bone & Mineral":
            return "sparkles"
        default:
            return "star.fill"
        }
    }
}

#Preview {
    ContentView()
}

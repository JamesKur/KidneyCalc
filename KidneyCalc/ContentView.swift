import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: String = "All Formulas"
    @State private var isAnimating = false
    @EnvironmentObject var favorites: FavoritesManager
    @Environment(\.colorScheme) var colorScheme
    
    let categories = ["All Formulas", "Favorites", "Acid-Base", "Bone & Mineral", "Electrolytes", "GFR"]
    
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
        case "Favorites":
            return .yellow
        default:
            return .orange
        }
    }
    
    static let placeholderFormulas = [
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
        ),
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
            name: "Electrolyte-Free Water Clearance",
            category: "Electrolytes",
            description: "Calculate electrolyte-free water clearance to predict the effect of urine output on serum sodium concentration",
            equation: "EFWC = V × [1 − (U_Na + U_K) / S_Na]",
            variables: [
                "U_Na: Urine Sodium (mEq/L)",
                "U_K: Urine Potassium (mEq/L)",
                "S_Na: Serum Sodium (mEq/L)",
                "V: Urine Volume (L/day or mL/hr)"
            ],
            references: [
                "Goldberg M. Hyponatremia. Med Clin North Am. 1981;65(2):251-269. doi:10.1016/s0025-7125(16)31523-1",
                "Rose BD. New approach to disturbances in the plasma sodium concentration. Am J Med. 1986;81(6):1033-1040. doi:10.1016/0002-9343(86)90401-8",
                "Kamel KS, Halperin ML. Use of urine electrolytes and urine osmolality in the clinical diagnosis of fluid, electrolyte, and acid-base disorders. Kidney Int Rep. 2021;6(5):1211-1224. doi:10.1016/j.ekir.2021.02.003"
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
            name: "Serum Osmolality & Osmolal Gap",
            category: "Electrolytes",
            description: "Calculate serum osmolality and osmolal gap to detect unmeasured osmoles such as toxic alcohols",
            equation: "Calc Osm = 2(Na) + Glucose/18 + BUN/2.8\nOsmolal Gap = Measured Osm − Calculated Osm",
            variables: [
                "Na: Serum Sodium (mEq/L)",
                "Glucose: Serum Glucose (mg/dL)",
                "BUN: Blood Urea Nitrogen (mg/dL)",
                "Measured Osm: Measured Osmolality (mOsm/kg) [optional]"
            ],
            references: [
                "Purssell RA, Pudek M, Brubacher J, Abu-Laban RB. Derivation and validation of a formula to calculate the contribution of ethanol to the osmolal gap. Ann Emerg Med. 2001;38(6):653-659. doi:10.1067/mem.2001.119455",
                "Kraut JA, Kurtz I. Toxic alcohol ingestions: clinical features, diagnosis, and management. Clin J Am Soc Nephrol. 2008;3(1):208-225. doi:10.2215/CJN.03220807"
            ]
        ),
        Formula(
            name: "Urine Anion Gap",
            category: "Acid-Base",
            description: "Differentiate renal from extrarenal causes of normal anion gap metabolic acidosis using urine electrolytes",
            equation: "UAG = (Na⁺ + K⁺) − Cl⁻",
            variables: [
                "Na⁺: Urine Sodium (mEq/L)",
                "K⁺: Urine Potassium (mEq/L)",
                "Cl⁻: Urine Chloride (mEq/L)"
            ],
            references: [
                "Batlle DC, Hizon M, Cohen E, Gutterman C, Gupta R. The use of the urinary anion gap in the diagnosis of hyperchloremic metabolic acidosis. N Engl J Med. 1988;318(10):594-599. doi:10.1056/NEJM198803103181002"
            ]
        ),
        Formula(
            name: "Urine Osmolal Gap",
            category: "Acid-Base",
            description: "Estimate urine ammonium excretion using the urine osmolal gap — more reliable than the urine anion gap when unmeasured anions are present",
            equation: "Calc Urine Osm = 2(Na + K) + Urea N/2.8 + Glucose/18\nUrine Osmolal Gap = Measured Osm − Calculated Osm\nEstimated NH₄⁺ ≈ Gap / 2",
            variables: [
                "Urine Na: Urine Sodium (mEq/L)",
                "Urine K: Urine Potassium (mEq/L)",
                "Urine Urea N: Urine Urea Nitrogen (mg/dL)",
                "Urine Glucose: Urine Glucose (mg/dL)",
                "Measured Urine Osm: Measured Urine Osmolality (mOsm/kg)"
            ],
            references: [
                "Kamel KS, Halperin ML. Use of urine electrolytes and urine osmolality in the clinical diagnosis of fluid, electrolyte, and acid-base disorders. Kidney Int Rep. 2021;6(5):1211-1224. doi:10.1016/j.ekir.2021.02.003",
                "Goldstein MB, Bear R, Richardson RM, Marsden PA, Halperin ML. The urine anion gap: a clinically useful index of ammonium excretion. Am J Med Sci. 1986;292(4):198-202."
            ]
        )
    ]
    
    var filteredFormulas: [Formula] {
        if selectedCategory == "All Formulas" {
            return Self.placeholderFormulas
        }
        if selectedCategory == "Favorites" {
            return Self.placeholderFormulas.filter { favorites.isFavorite($0) }
        }
        return Self.placeholderFormulas.filter { $0.category == selectedCategory }
    }
    
    var favoriteFormulas: [Formula] {
        Self.placeholderFormulas.filter { favorites.isFavorite($0) }
    }

    var shouldShowFavoritesQuickAccess: Bool {
        selectedCategory != "Favorites" && !favoriteFormulas.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated mesh gradient background
                AnimatedMeshBackground()
                
                ScrollView {
                VStack(spacing: 16) {
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
                                    .offset(x: -3, y: -3) // Move it to the "light source" (top left)
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
                    
                    // Category Picker with glass pills
                    VStack(spacing: 12) {
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
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            if selectedCategory == category {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption)
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                            Text(category)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                    }
                                    .background(
                                        Capsule()
                                            .fill(getCategoryColor(category).opacity(selectedCategory == category ? 0.7 : 0))
                                    )
                                    .glassEffect(.regular, in: .capsule)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCategory)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Favorites Quick-Access Section (Liquid Glass Chips)
                    if shouldShowFavoritesQuickAccess {
                        // transition added so the section slides in/out smoothly
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Favorites")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedCategory = "Favorites"
                                    }
                                }) {
                                    Text("See All")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(favoriteFormulas) { formula in
                                        NavigationLink(destination: FormulaDetailView(formula: formula)) {
                                            LiquidGlassFavoriteChip(
                                                formula: formula,
                                                categoryColor: getCategoryColor(formula.category),
                                                action: { }
                                            )
                                            .allowsHitTesting(false) // NavigationLink handles the tap
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: favoriteFormulas.map(\.id))
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Formula Cards with glass
                    VStack(spacing: 12) {
                        if filteredFormulas.isEmpty {
                            VStack(spacing: 12) {
                                if selectedCategory == "Favorites" {
                                    Image(systemName: "star.slash")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                    Text("No favorites yet")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Tap the star on any formula to add it here")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text("No formulas in this category yet")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(filteredFormulas) { formula in
                                NavigationLink(destination: FormulaDetailView(formula: formula)) {
                                    HStack(spacing: 12) {
                                        // Category color indicator
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getCategoryColor(formula.category))
                                            .frame(width: 4)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(formula.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text(formula.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            
                                            Label(formula.category, systemImage: getCategoryIcon(formula.category))
                                                .font(.caption2)
                                                .foregroundColor(getCategoryColor(formula.category))
                                                .fontWeight(.semibold)
                                        }
                                        
                                        Spacer()
                                        
                                        // Favorite toggle star
                                        FavoriteCardButton(
                                            isFavorite: favorites.isFavorite(formula),
                                            action: {
                                                favorites.toggle(formula)
                                            }
                                        )
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: favorites.favoriteNames)
                } // ScrollView
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
        case "Favorites":
            return "star.fill"
        default:
            return "star.fill"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FavoritesManager())
}

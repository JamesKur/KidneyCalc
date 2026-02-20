import SwiftUI
import Combine

// MARK: - Animated Mesh Background

class BackgroundManager: ObservableObject {
    static let shared = BackgroundManager()
    
    @Published var phase = false
    @Published var baseHue: Double = 0.0
    var isInitialized = false
    
    private var colorTimer: AnyCancellable?
    
    private init() {
        // Pick a consistent random starting hue for this launch
        self.baseHue = Double.random(in: 0...1)
        
        // Start color rotation timer
        colorTimer = Timer.publish(every: 90, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                withAnimation(.easeInOut(duration: 2.0)) {
                    self.baseHue = (self.baseHue + 0.382).truncatingRemainder(dividingBy: 1.0)
                }
            }
    }
}

/// A beautiful animated mesh gradient that serves as the app background,
/// giving glass effects a colorful, dynamic backdrop.
struct AnimatedMeshBackground: View {
    @StateObject private var manager = BackgroundManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Fixed relative saturations/brightnesses to prevent jitter on redraws
    private let darkSats: [Double] = [0.45, 0.32, 0.48, 0.35, 0.42, 0.38, 0.49, 0.31, 0.39]
    private let darkBrights: [Double] = [0.05, 0.08, 0.11, 0.06, 0.09, 0.04, 0.12, 0.10, 0.07]
    
    private let lightSats: [Double] = [0.04, 0.07, 0.05, 0.08, 0.06, 0.03, 0.09, 0.05, 0.08]
    private let lightBrights: [Double] = [0.95, 0.98, 0.96, 0.99, 0.94, 0.97, 1.0, 0.98, 0.95]
    
    /// Generate 9 mesh colors from the current hue, adapted for the color scheme.
    private func meshColors(hue: Double, isDark: Bool) -> [Color] {
        let offsets: [Double] = [-0.03, 0.02, -0.01, 0.01, 0.0, -0.02, 0.03, -0.01, 0.02]
        
        return offsets.enumerated().map { index, offset in
            let h = (hue + offset).truncatingRemainder(dividingBy: 1.0)
            let adjustedH = h < 0 ? h + 1 : h
            
            if isDark {
                return Color(hue: adjustedH, saturation: darkSats[index], brightness: darkBrights[index])
            } else {
                return Color(hue: adjustedH, saturation: lightSats[index], brightness: lightBrights[index])
            }
        }
    }
    
    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5),
                .init(0.5, 0.5),
                .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ],
            colors: meshColors(hue: manager.baseHue, isDark: colorScheme == .dark)
        )
        .ignoresSafeArea()
        .onAppear {
            if !manager.isInitialized {
                manager.isInitialized = true
            }
        }
    }
}

// MARK: - Staggered Entrance Animation

extension View {
    /// Adds a staggered entrance animation (fade + slide up + scale)
    func staggeredAppearance(index: Int, delay: Double = 0.05) -> some View {
        modifier(StaggeredAppearanceModifier(index: index, delay: delay))
    }
}

private struct StaggeredAppearanceModifier: ViewModifier {
    let index: Int
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .scaleEffect(appeared ? 1 : 0.96)
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(Double(index) * delay)
                ) {
                    appeared = true
                }
            }
    }
}

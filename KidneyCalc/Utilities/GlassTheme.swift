import SwiftUI

// MARK: - Animated Mesh Background

/// A beautiful animated mesh gradient that serves as the app background,
/// giving glass effects a colorful, dynamic backdrop.
struct AnimatedMeshBackground: View {
    @State private var phase = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5),
                .init(phase ? 0.55 : 0.45, phase ? 0.45 : 0.55),
                .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ],
            colors: colorScheme == .dark ? [
                Color(red: 0.04, green: 0.08, blue: 0.20),
                Color(red: 0.08, green: 0.04, blue: 0.18),
                Color(red: 0.04, green: 0.12, blue: 0.18),
                Color(red: 0.02, green: 0.10, blue: 0.16),
                Color(red: 0.06, green: 0.06, blue: 0.20),
                Color(red: 0.04, green: 0.04, blue: 0.16),
                Color(red: 0.04, green: 0.10, blue: 0.18),
                Color(red: 0.06, green: 0.04, blue: 0.14),
                Color(red: 0.04, green: 0.08, blue: 0.20)
            ] : [
                Color(red: 0.91, green: 0.95, blue: 1.0),
                Color(red: 0.95, green: 0.92, blue: 1.0),
                Color(red: 0.89, green: 0.97, blue: 1.0),
                Color(red: 0.94, green: 0.97, blue: 1.0),
                Color(red: 0.93, green: 0.94, blue: 1.0),
                Color(red: 0.96, green: 0.94, blue: 1.0),
                Color(red: 0.90, green: 0.96, blue: 1.0),
                Color(red: 0.94, green: 0.92, blue: 1.0),
                Color(red: 0.91, green: 0.95, blue: 1.0)
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                phase = true
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

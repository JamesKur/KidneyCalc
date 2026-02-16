import SwiftUI

// MARK: - Smooth Press Button Style

/// A button style that gently scales down on press and springs back on release,
/// giving a tactile, polished feel without the abrupt default highlight.
private struct SmoothPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Glassy Star Icon

/// A star icon with a layered liquid-glass look:
///  - Filled body uses a translucent gradient
///  - A specular highlight overlay fakes light refraction
///  - A faint outer glow when active
private struct GlassyStar: View {
    let filled: Bool
    let size: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Outer glow (only when filled)
            if filled {
                Image(systemName: "star.fill")
                    .font(.system(size: size + 4, weight: .medium))
                    .foregroundStyle(.yellow.opacity(0.35))
                    .blur(radius: 6)
            }
            
            // Base icon
            Image(systemName: filled ? "star.fill" : "star")
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(
                    filled
                        ? AnyShapeStyle(LinearGradient(
                            colors: [
                                Color.yellow,
                                Color.orange.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(.secondary)
                )
            
            // Specular highlight (glass refraction look)
            if filled {
                Image(systemName: "star.fill")
                    .font(.system(size: size * 0.45, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(colorScheme == .dark ? 0.7 : 0.9), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .offset(x: -size * 0.08, y: -size * 0.1)
                    .blur(radius: 0.5)
            }
        }
        .contentTransition(.symbolEffect(.replace))
    }
}

// MARK: - Toolbar Favorite Button

/// Animated liquid-glass star button for toggling favorites (toolbar size).
/// Features a scale + ripple animation on tap for a satisfying feel.
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.0
    @State private var rippleScale: CGFloat = 0.5
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                pulseScale = 1.3
            }
            withAnimation(.easeOut(duration: 0.4)) {
                rippleOpacity = 0.6
                rippleScale = 2.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                rippleOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    pulseScale = 1.0
                    rippleScale = 0.5
                }
            }
            action()
        }) {
            ZStack {
                Circle()
                    .stroke(
                        isFavorite ? Color.yellow.opacity(rippleOpacity) : Color.orange.opacity(rippleOpacity),
                        lineWidth: 2
                    )
                    .scaleEffect(rippleScale)
                    .frame(width: 32, height: 32)
                
                GlassyStar(filled: isFavorite, size: 20)
                    .scaleEffect(pulseScale)
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(SmoothPressButtonStyle())
        .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
    }
}

// MARK: - Card Favorite Button

/// Compact glassy star button for use in formula cards.
struct FavoriteCardButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                pulseScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    pulseScale = 1.0
                }
            }
            action()
        }) {
            GlassyStar(filled: isFavorite, size: 17)
                .scaleEffect(pulseScale)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(SmoothPressButtonStyle())
        .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
    }
}

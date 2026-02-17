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
/// Uses iOS 26 `.glassEffect()` for a native liquid glass circle backdrop.
/// Features a gentle glow and fade animation on tap.
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    @State private var glowOpacity: Double = 0.0
    
    var body: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.6)) {
                glowOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                glowOpacity = 0.0
            }
            action()
        }) {
            ZStack {
                // Gentle glow
                if glowOpacity > 0 {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow.opacity(0.4 * glowOpacity),
                                    Color.yellow.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 48, height: 48)
                }
                
                GlassyStar(filled: isFavorite, size: 20)
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(SmoothPressButtonStyle())
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
    }
}

// MARK: - Card Favorite Button

/// Compact glassy star button for use in formula cards.
/// Uses iOS 26 `.glassEffect()` for a native liquid glass circle backdrop.
struct FavoriteCardButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    @State private var glowOpacity: Double = 0.0
    
    var body: some View {
        Button(action: {
            action()
            withAnimation(.easeOut(duration: 0.5)) {
                glowOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                glowOpacity = 0.0
            }
        }) {
            ZStack {
                // Gentle glow
                if glowOpacity > 0 {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow.opacity(0.3 * glowOpacity),
                                    Color.yellow.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 44, height: 44)
                }
                
                GlassyStar(filled: isFavorite, size: 17)
            }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
        }
        .buttonStyle(SmoothPressButtonStyle())
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
    }
}

// MARK: - Liquid Glass Favorite Chip

/// A favorite item chip that appears in the quick-access bar with a liquid glass effect.
/// Uses `.glassEffect()` for native iOS 26 liquid glass with smooth morphing transitions.
struct LiquidGlassFavoriteChip: View {
    let formula: Formula
    let categoryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(categoryColor)
                    .frame(width: 3, height: 16)
                Text(formula.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(SmoothPressButtonStyle())
        .glassEffect(.regular.interactive(), in: .capsule)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.4, anchor: .center)
                    .combined(with: .opacity),
                removal: .scale(scale: 0.4, anchor: .center)
                    .combined(with: .opacity)
            )
        )
    }
}

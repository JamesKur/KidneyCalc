import SwiftUI
import Combine

// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SoftTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(8)
    }
}

// MARK: - Keyboard Toolbar State

/// Shared observable state for the floating keyboard navigation toolbar.
/// Created by FormulaDetailView and injected via `@EnvironmentObject`.
class KeyboardToolbarState: ObservableObject {
    @Published var isActive = false
    @Published var isFirstField = true
    @Published var isLastField = false
    
    var onBack: () -> Void = {}
    var onForward: () -> Void = {}
    var onDismiss: () -> Void = {}
}

// MARK: - Floating Keyboard Navigation Toolbar

/// A floating pill-shaped toolbar shown above the keyboard, right-aligned.
struct KeyboardNavigationToolbar: View {
    let isFirstField: Bool
    let isLastField: Bool
    let onBack: () -> Void
    let onForward: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 18) {
                Button(action: onBack) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isFirstField)
                .opacity(isFirstField ? 0.3 : 1.0)
                
                Divider()
                    .frame(height: 20)
                
                Button(action: onForward) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isLastField)
                .opacity(isLastField ? 0.3 : 1.0)
                
                Divider()
                    .frame(height: 20)
                
                Button(action: {
                    if isLastField { onDismiss() }
                    else { onForward() }
                }) {
                    Text(isLastField ? "Done" : "Next")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(height: 24)
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .glassEffect(.regular.interactive(), in: .capsule)
            .padding(.trailing, 16)
        }
    }
}
// MARK: - Shared Navigation Direction

/// Direction for keyboard focus navigation, used by all calculator views.
enum NavigationDirection {
    case forward, back
}
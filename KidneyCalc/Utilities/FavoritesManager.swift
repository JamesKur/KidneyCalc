import SwiftUI
import Combine

/// Manages the user's favorite formulas with UserDefaults persistence.
/// Keyed by formula name (stable across app launches, unlike UUID).
class FavoritesManager: ObservableObject {
    private static let storageKey = "favoriteFormulaNames"
    
    @Published private(set) var favoriteNames: Set<String> {
        didSet { persist() }
    }
    
    init() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.storageKey) ?? []
        self.favoriteNames = Set(saved)
    }
    
    func isFavorite(_ formula: Formula) -> Bool {
        favoriteNames.contains(formula.name)
    }
    
    func toggle(_ formula: Formula) {
        if favoriteNames.contains(formula.name) {
            favoriteNames.remove(formula.name)
        } else {
            favoriteNames.insert(formula.name)
        }
    }
    
    private func persist() {
        UserDefaults.standard.set(Array(favoriteNames), forKey: Self.storageKey)
    }
}

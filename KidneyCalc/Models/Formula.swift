import Foundation

struct Formula: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let description: String
    let equation: String?
    let variables: [String]?
    let references: [String]?
    
    init(name: String, category: String, description: String, equation: String? = nil, variables: [String]? = nil, references: [String]? = nil) {
        self.name = name
        self.category = category
        self.description = description
        self.equation = equation
        self.variables = variables
        self.references = references
    }
}

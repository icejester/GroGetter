//
//  GroceryItem.swift
//  GroGetter
//
//  Created by Jared Mallas on 8/2/25.
//

import Foundation

struct GroceryCategory: Identifiable, Codable, Hashable, Equatable {
    static let standardCategories: [GroceryCategory] = [
        GroceryCategory(name: "Produce"),
        GroceryCategory(name: "Bakery"),
        GroceryCategory(name: "Deli"),
        GroceryCategory(name: "Butcher"),
        GroceryCategory(name: "Dairy"),
        GroceryCategory(name: "Aisles"),
        GroceryCategory(name: "Frozen"),
        
    ]
    
    static var allCases: [GroceryCategory] {
        // Load custom categories from UserDefaults if available
        if let data = UserDefaults.standard.data(forKey: "customCategories"),
           let customCategories = try? JSONDecoder().decode([GroceryCategory].self, from: data) {
            return standardCategories + customCategories
        }
        return standardCategories
    }
    
    static func saveCustomCategories(_ categories: [GroceryCategory]) {
        // Filter out standard categories
        let customCategories = categories.filter { category in
            !standardCategories.contains(category)
        }
        
        if let encoded = try? JSONEncoder().encode(customCategories) {
            UserDefaults.standard.set(encoded, forKey: "customCategories")
        }
    }
    
    let id: UUID
    let name: String
    var isCustom: Bool {
        !GroceryCategory.standardCategories.contains(self)
    }
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
    
    // For decoding from UserDefaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
    }
    
    // For encoding to UserDefaults
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name
    }
    
    static func == (lhs: GroceryCategory, rhs: GroceryCategory) -> Bool {
        lhs.name.lowercased() == rhs.name.lowercased()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
    }
}

enum QuantityUnit: String, CaseIterable, Identifiable, Codable {
    case piece = "piece(s)"
    case gram = "g"
    case kilogram = "kg"
    case milliliter = "ml"
    case liter = "L"
    case cup = "cup(s)"
    case tablespoon = "tbsp"
    case teaspoon = "tsp"
    case pinch = "pinch(es)"
    case bunch = "bunch(es)"
    case pack = "pack(s)"
    case can = "can(s)"
    case bottle = "bottle(s)"
    case jar = "jar(s)"
    case box = "box(es)"
    case bag = "bag(s)"
    
    var id: String { self.rawValue }
}

struct GroceryItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var category: GroceryCategory = GroceryCategory(name: "Produce")
    var quantity: Double = 1
    var unit: QuantityUnit = .piece
    var isCompleted: Bool = false
    var notes: String = ""
    
    var displayQuantity: String {
        if unit == .piece && quantity == 1 {
            return ""
        } else if unit == .piece && quantity != 1 {
            return "\(Int(quantity)) "
        } else {
            return "\(quantity.clean) \(unit.rawValue)"
        }
    }
}

extension Double {
    var clean: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

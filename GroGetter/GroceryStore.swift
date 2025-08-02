import Foundation

class GroceryStore: ObservableObject {
    @Published var items: [GroceryItem] = [] {
        didSet {
            saveItems()
        }
    }
    
    private let itemsKey = "savedGroceryItems"
    
    init() {
        loadItems()
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: itemsKey) {
            if let decoded = try? JSONDecoder().decode([GroceryItem].self, from: data) {
                items = decoded
                return
            }
        }
        items = []
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: itemsKey)
        }
    }
    
    func addItem(_ item: GroceryItem) {
        items.append(item)
    }
    
    func deleteItems(at offsets: IndexSet) {
        // Get the categories of the items being deleted
        let deletedCategories = Set(offsets.map { items[$0].category })
        
        // Remove the items
        items.remove(atOffsets: offsets)
        
        // Check if any categories are now empty and remove them if they're custom
        for category in deletedCategories {
            if category.isCustom && !items.contains(where: { $0.category == category }) {
                // Remove the custom category from UserDefaults
                removeCustomCategory(category)
            }
        }
    }
    
    private func removeCustomCategory(_ category: GroceryCategory) {
        // Load current custom categories
        if let data = UserDefaults.standard.data(forKey: "customCategories"),
           var customCategories = try? JSONDecoder().decode([GroceryCategory].self, from: data) {
            // Remove the category if it exists
            customCategories.removeAll { $0.id == category.id }
            
            // Save back to UserDefaults
            if let encoded = try? JSONEncoder().encode(customCategories) {
                UserDefaults.standard.set(encoded, forKey: "customCategories")
            }
        }
    }
    
    func updateItem(_ item: GroceryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
}

import Foundation

struct GroceryList: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var items: [GroceryItem]
    var createdAt: Date
    var isDefault: Bool
    
    init(name: String, items: [GroceryItem] = [], isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.items = items
        self.createdAt = Date()
        self.isDefault = isDefault
    }
    
    mutating func addItem(_ item: GroceryItem) {
        items.append(item)
    }
    
    mutating func deleteItems(at offsets: IndexSet) -> Set<GroceryCategory> {
        // Get the categories of the items being deleted
        let deletedCategories = Set(offsets.map { items[$0].category })
        
        // Remove the items
        items.remove(atOffsets: offsets)
        
        return deletedCategories
    }
    
    mutating func toggleItemCompletion(_ item: GroceryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
        }
    }
    
    mutating func updateItem(_ item: GroceryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
    
    mutating func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
    
    mutating func clearCompletedItems() {
        items.removeAll { $0.isCompleted }
    }
}

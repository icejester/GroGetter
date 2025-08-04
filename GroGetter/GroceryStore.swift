//
//  GroceryStore.swift
//  GroGetter
//
//  Created by Jared Mallas on 8/2/25.
//  Modified to support multiple grocery lists
//

import Foundation

class GroceryStore: ObservableObject {
    @Published var lists: [GroceryList] = [] {
        didSet {
            saveLists()
        }
    }
    
    @Published var selectedListId: UUID? {
        willSet {
            print("GroceryStore - Will set selectedListId from:", selectedListId?.uuidString ?? "nil", "to:", newValue?.uuidString ?? "nil")
            print("GroceryStore - Current thread:", Thread.current)
        }
        didSet {
            print("GroceryStore - selectedListId changed from:", oldValue?.uuidString ?? "nil", "to:", selectedListId?.uuidString ?? "nil")
            
            // Save to UserDefaults
            if let id = selectedListId {
                print("GroceryStore - Saving selectedListId to UserDefaults:", id.uuidString)
                UserDefaults.standard.set(id.uuidString, forKey: "selectedListId")
            } else {
                print("GroceryStore - Removing selectedListId from UserDefaults")
                UserDefaults.standard.removeObject(forKey: "selectedListId")
            }
            
            // Verify the value was set correctly
            let savedId = UserDefaults.standard.string(forKey: "selectedListId")
            print("GroceryStore - Verified UserDefaults selectedListId:", savedId ?? "nil")
        }
    }
    
    var selectedList: GroceryList? {
        let list = lists.first { $0.id == selectedListId }
        print("selectedList computed:", list?.name ?? "nil")
        return list
    }
    
    private let listsKey = "savedGroceryLists"
    private let selectedListKey = "selectedListId"
    
    init() {
        loadLists()
        migrateIfNeeded()
    }
    
    // MARK: - List Management
    
    func createNewList(name: String) -> GroceryList {
        let newList = GroceryList(name: name, items: [])
        lists.append(newList)
        if selectedListId == nil {
            selectedListId = newList.id
        }
        saveLists() // Ensure the new list is saved to UserDefaults
        return newList
    }
    
    func deleteList(_ list: GroceryList) {
        lists.removeAll { $0.id == list.id }
        if selectedListId == list.id {
            selectedListId = lists.first?.id
        }
    }
    
    func renameList(_ list: GroceryList, to newName: String) {
        guard let index = lists.firstIndex(where: { $0.id == list.id }) else { return }
        lists[index].name = newName
        saveLists()
    }
    
    func updateList(_ list: GroceryList) {
        if let index = lists.firstIndex(where: { $0.id == list.id }) {
            lists[index] = list
        }
    }
    
    // MARK: - Item Management
    
    func addItem(_ item: GroceryItem, to listId: UUID? = nil) {
        let targetListId = listId ?? selectedListId
        if let index = lists.firstIndex(where: { $0.id == targetListId }) {
            lists[index].addItem(item)
        }
    }
    
    func deleteItems(at offsets: IndexSet, from listId: UUID? = nil) {
        let targetListId = listId ?? selectedListId
        if let index = lists.firstIndex(where: { $0.id == targetListId }) {
            let deletedCategories = lists[index].deleteItems(at: offsets)
            
            // Check if any categories are now empty and remove them if they're custom
            for category in deletedCategories {
                if category.isCustom && !lists.flatMap({ $0.items }).contains(where: { $0.category == category }) {
                    removeCustomCategory(category)
                }
            }
        }
    }
    
    func toggleItemCompletion(_ item: GroceryItem, in listId: UUID? = nil) {
        let targetListId = listId ?? selectedListId
        if let listIndex = lists.firstIndex(where: { $0.id == targetListId }),
           let itemIndex = lists[listIndex].items.firstIndex(where: { $0.id == item.id }) {
            lists[listIndex].items[itemIndex].isCompleted.toggle()
        }
    }
    
    func updateItem(_ item: GroceryItem, in listId: UUID? = nil) {
        let targetListId = listId ?? selectedListId
        if let listIndex = lists.firstIndex(where: { $0.id == targetListId }) {
            lists[listIndex].updateItem(item)
        }
    }
    
    func moveItems(from source: IndexSet, to destination: Int, in listId: UUID? = nil) {
        let targetListId = listId ?? selectedListId
        if let index = lists.firstIndex(where: { $0.id == targetListId }) {
            lists[index].moveItems(from: source, to: destination)
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadLists() {
        if let data = UserDefaults.standard.data(forKey: listsKey) {
            if let decoded = try? JSONDecoder().decode([GroceryList].self, from: data) {
                lists = decoded
                
                // Restore selected list
                if let selectedIdString = UserDefaults.standard.string(forKey: selectedListKey),
                   let selectedId = UUID(uuidString: selectedIdString),
                   lists.contains(where: { $0.id == selectedId }) {
                    selectedListId = selectedId
                } else {
                    selectedListId = lists.first?.id
                }
                return
            }
        }
        
        // If no lists found, create a default one
        let defaultList = GroceryList(name: "My Grocery List", isDefault: true)
        lists = [defaultList]
        selectedListId = defaultList.id
    }
    
    private func saveLists() {
        if let encoded = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(encoded, forKey: listsKey)
        }
    }
    
    // MARK: - Migration from single list to multiple lists
    
    private func migrateIfNeeded() {
        let oldItemsKey = "savedGroceryItems"
        guard UserDefaults.standard.data(forKey: oldItemsKey) != nil else { return }
        
        // Load old items
        if let data = UserDefaults.standard.data(forKey: oldItemsKey),
           let oldItems = try? JSONDecoder().decode([GroceryItem].self, from: data) {
            
            // If we have old items but no lists, create a list with them
            if lists.isEmpty || (lists.count == 1 && lists[0].items.isEmpty) {
                let migratedList = GroceryList(name: "My Grocery List", items: oldItems, isDefault: true)
                if lists.isEmpty {
                    lists = [migratedList]
                } else {
                    lists[0] = migratedList
                }
                selectedListId = migratedList.id
                
                // Save the changes
                saveLists()
            }
            
            // Clean up old data
            UserDefaults.standard.removeObject(forKey: oldItemsKey)
        }
    }
    
    // MARK: - Category Management
    
    private func removeCustomCategory(_ category: GroceryCategory) {
        var customCategories = GroceryCategory.allCases.filter { $0.isCustom }
        customCategories.removeAll { $0 == category }
        GroceryCategory.saveCustomCategories(customCategories)
    }
    
    func updateItem(_ item: GroceryItem, in listId: UUID) {
        if let listIndex = lists.firstIndex(where: { $0.id == listId }),
           let itemIndex = lists[listIndex].items.firstIndex(where: { $0.id == item.id }) {
            lists[listIndex].items[itemIndex] = item
            saveLists()
        }
    }
    
    func clearCompletedItems(in list: GroceryList) {
        if let index = lists.firstIndex(where: { $0.id == list.id }) {
            lists[index].clearCompletedItems()
            saveLists()
        }
    }
}

import SwiftUI

struct ItemDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var store: GroceryStore
    
    @State private var name: String
    @State private var category: GroceryCategory
    @State private var newCategoryName = ""
    @State private var showingNewCategoryAlert = false
    @State private var categories: [GroceryCategory] = []
    @State private var customCategories: [GroceryCategory] = []
    
    @State private var quantity: String
    @State private var unit: QuantityUnit
    @State private var notes: String
    
    var item: GroceryItem?
    
    init(item: GroceryItem? = nil) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _category = State(initialValue: item?.category ?? GroceryCategory(name: "Other"))
        _quantity = State(initialValue: item != nil ? String(format: "%g", item!.quantity) : "1")
        _unit = State(initialValue: item?.unit ?? .piece)
        _notes = State(initialValue: item?.notes ?? "")
        
        // Initialize categories from standard and custom categories
        let customCategories: [GroceryCategory] = {
            if let data = UserDefaults.standard.data(forKey: "customCategories"),
               let decoded = try? JSONDecoder().decode([GroceryCategory].self, from: data) {
                return decoded
            }
            return []
        }()
        _categories = State(initialValue: GroceryCategory.standardCategories + customCategories)
        _customCategories = State(initialValue: customCategories)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item name", text: $name)
                    
                    HStack {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.id) { category in
                                Text(category.name).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button(action: {
                            showingNewCategoryAlert = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .alert("New Category", isPresented: $showingNewCategoryAlert) {
                        TextField("Category name", text: $newCategoryName)
                        Button("Cancel", role: .cancel) {
                            newCategoryName = ""
                        }
                        Button("Add") {
                            addNewCategory()
                        }
                    }
                    
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                        
                        Picker("", selection: $unit) {
                            ForEach(QuantityUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    TextField("Notes (optional)", text: $notes)
                }
                
                if item != nil {
                    Button(action: deleteItem) {
                        HStack {
                            Spacer()
                            Text("Delete Item")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "Add Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(item == nil ? "Add" : "Save") {
                        saveItem()
                    }
                    .disabled(name.isEmpty || Double(quantity) == nil)
                }
            }
        }
    }
    
    private func addNewCategory() {
        if !newCategoryName.isEmpty {
            let newCategory = GroceryCategory(name: newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines))
            
            // Check if category already exists (case insensitive)
            if !categories.contains(where: { $0.name.lowercased() == newCategory.name.lowercased() }) {
                // Add to our local state
                categories.append(newCategory)
                
                // Add to custom categories and save
                var updatedCustomCategories = customCategories
                if !updatedCustomCategories.contains(where: { $0.name.lowercased() == newCategory.name.lowercased() }) {
                    updatedCustomCategories.append(newCategory)
                    GroceryCategory.saveCustomCategories(updatedCustomCategories)
                    customCategories = updatedCustomCategories
                }
                
                // Select the new category
                category = newCategory
            } else {
                // If category exists, just select it
                if let existingCategory = categories.first(where: { $0.name.lowercased() == newCategory.name.lowercased() }) {
                    category = existingCategory
                }
            }
            
            newCategoryName = ""
        }
    }
    
    private func saveItem() {
        guard let quantityValue = Double(quantity) else { return }
        guard let listId = store.selectedListId else {
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        let newItem = GroceryItem(
            id: item?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            quantity: quantityValue,
            unit: unit,
            isCompleted: item?.isCompleted ?? false,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        if let item = item {
            // Update existing item
            store.updateItem(newItem, in: listId)
        } else {
            // Add new item
            store.addItem(newItem, to: listId)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteItem() {
        guard let item = item, let listId = store.selectedListId else {
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        if let listIndex = store.lists.firstIndex(where: { $0.id == listId }),
           let itemIndex = store.lists[listIndex].items.firstIndex(where: { $0.id == item.id }) {
            store.deleteItems(at: IndexSet(integer: itemIndex), from: listId)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView()
            .environmentObject(GroceryStore())
    }
}

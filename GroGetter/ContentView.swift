//
//  ContentView.swift
//  GroGetter
//
//  Created by Jared Mallas on 8/2/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: GroceryStore
    @State private var showingAddItem = false
    // Removed search functionality as per user request
    @State private var selectedCategory: GroceryCategory? = nil
    @State private var showingActionSheet = false
    @State private var showingShareSheet = false
    @State private var isGroupedByCategory = true
    
    private var filteredItems: [GroceryItem] {
        var items = store.items
        
        // Filter by category
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        // Sort by completion status and then by name
        return items.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted && $1.isCompleted
            }
            return $0.name < $1.name
        }
    }
    
    private var categories: [GroceryCategory] {
        // Get all unique categories from items
        let itemCategories = Set(store.items.map { $0.category })
        
        // Filter categories to include only those in use or custom
        var result = [GroceryCategory]()
        for category in GroceryCategory.allCases {
            if itemCategories.contains(category) || category.isCustom {
                result.append(category)
            }
        }
        return result
    }
    
    private var addItemButton: some View {
        Button(action: { showingAddItem = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Add Item")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
    }
    
    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: { selectedCategory = nil }) {
                    Text("All")
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(15)
                }
                
                ForEach(categories) { category in
                    Button(action: { 
                        selectedCategory = selectedCategory == category ? nil : category 
                    }) {
                        Text(category.name)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var emptyStateView: some View {
        Group {
            if store.items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Your grocery list is empty")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            } else if filteredItems.isEmpty && selectedCategory != nil {
                VStack(spacing: 20) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No items in \(selectedCategory?.name ?? "this category")")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Button(action: {
                        selectedCategory = nil
                    }) {
                        Text("Show All Items")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private var groupedListView: some View {
        List {
            ForEach(groupedItems.keys.sorted(by: { $0.name < $1.name }), id: \.self) { category in
                if let items = groupedItems[category] {
                    Section(header: Text(category.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .textCase(.none)) {
                        ForEach(items) { item in
                            itemRow(for: item)
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, in: items)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
    
    private var regularListView: some View {
        List {
            ForEach(filteredItems) { item in
                itemRow(for: item)
            }
            .onDelete { indexSet in
                deleteItems(at: indexSet, in: filteredItems)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var toolbarMenu: some View {
        Menu {
            Button(action: {
                isGroupedByCategory.toggle()
            }) {
                Label(
                    isGroupedByCategory ? "Ungroup by Category" : "Group by Category",
                    systemImage: isGroupedByCategory ? "rectangle.grid.1x2" : "list.bullet"
                )
            }
            
            Divider()
            
            Button(action: { showingShareSheet = true }) {
                Label("Share List", systemImage: "square.and.arrow.up")
            }
            
            Button(role: .destructive, action: confirmClearCompleted) {
                Label("Clear Completed", systemImage: "checkmark.circle")
            }
            
            Button(role: .destructive, action: confirmDeleteAll) {
                Label("Delete All", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    categoryFilterChips
                    
                    if isGroupedByCategory {
                        groupedListView
                    } else {
                        regularListView
                    }
                }
                .padding(.bottom, 60) // Add padding to prevent content from being hidden behind the button
                
                addItemButton
            }
            .navigationTitle("GroGetter")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
            .sheet(isPresented: $showingAddItem) {
                ItemDetailView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [shareContent])
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Are you sure?"),
                    message: Text("This action cannot be undone."),
                    buttons: [
                        .destructive(Text("Delete All")) {
                            store.items.removeAll()
                        },
                        .cancel()
                    ]
                )
            }
            .overlay(emptyStateView)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var shareContent: String {
        var content = "# Grocery List\n\n"
        
        let itemsByCategory = Dictionary(grouping: store.items) { $0.category }
        
        for category in GroceryCategory.allCases {
            if let items = itemsByCategory[category], !items.isEmpty {
                content += "## \(category.name)\n"
                for item in items.sorted(by: { $0.name < $1.name }) {
                    let quantityText = item.unit == .piece && item.quantity == 1 ? "" : "\(item.quantity.clean) \(item.unit.rawValue) "
                    let status = item.isCompleted ? "✅" : "◻️"
                    content += "- \(status) \(quantityText)\(item.name)\n"
                    if !item.notes.isEmpty {
                        content += "  - \(item.notes)\n"
                    }
                }
                content += "\n"
            }
        }
        
        return content
    }
    
    private func confirmDeleteAll() {
        showingActionSheet = true
    }
    private func confirmClearCompleted() {
        store.items.removeAll { $0.isCompleted }
    }
    
    private var groupedItems: [GroceryCategory: [GroceryItem]] {
        let grouped = Dictionary(grouping: filteredItems) { $0.category }
        // Sort items within each category by completion status and then by name
        return grouped.mapValues { items in
            items.sorted {
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted && $1.isCompleted
                }
                return $0.name < $1.name
            }
        }
    }
    
    private func itemRow(for item: GroceryItem) -> some View {
        ItemRow(item: item) { updatedItem in
            if let index = store.items.firstIndex(where: { $0.id == updatedItem.id }) {
                store.items[index] = updatedItem
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet, in items: [GroceryItem]? = nil) {
        if let items = items {
            // Get the actual indices in the store from the filtered/grouped items
            let idsToDelete = offsets.map { items[$0].id }
            let indicesToDelete = store.items.indices.filter { index in
                idsToDelete.contains(store.items[index].id)
            }
            store.deleteItems(at: IndexSet(indicesToDelete))
        } else {
            // Handle direct deletion from ungrouped list
            let itemsToDelete = offsets.map { filteredItems[$0] }
            for item in itemsToDelete {
                if let index = store.items.firstIndex(where: { $0.id == item.id }) {
                    store.deleteItems(at: IndexSet(integer: index))
                }
            }
        }
    }
}

struct ItemRow: View {
    @EnvironmentObject private var store: GroceryStore
    let item: GroceryItem
    let onUpdate: (GroceryItem) -> Void
    
    @State private var showingDetail = false
    
    private func toggleCompletion() {
        var updatedItem = item
        updatedItem.isCompleted.toggle()
        onUpdate(updatedItem)
    }
    
    var body: some View {
        HStack {
            // Checkbox with tap gesture
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isCompleted ? .green : .gray)
                .font(.title2)
                .onTapGesture {
                    toggleCompletion()
                }
            
            // Item details - make entire area tappable for detail view
            Button(action: { showingDetail = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .strikethrough(item.isCompleted)
                            .foregroundColor(item.isCompleted ? .gray : .primary)
                        
                        if !item.displayQuantity.isEmpty || !item.notes.isEmpty {
                            HStack(spacing: 8) {
                                if !item.displayQuantity.isEmpty {
                                    Text(item.displayQuantity)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !item.notes.isEmpty {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(item.notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Category indicator
                    Text(String(item.category.name.prefix(1)))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(categoryColor(for: item.category)))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingDetail) {
            ItemDetailView(item: item)
                .environmentObject(store)
        }
        .swipeActions(edge: .leading) {
            Button(role: .destructive, action: {
                if let index = store.items.firstIndex(where: { $0.id == item.id }) {
                    store.deleteItems(at: IndexSet(integer: index))
                }
            }) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .trailing) {
            Button(action: toggleCompletion) {
                Label(
                    item.isCompleted ? "Mark Incomplete" : "Mark Complete",
                    systemImage: item.isCompleted ? "arrow.uturn.backward" : "checkmark"
                )
            }
            .tint(item.isCompleted ? .orange : .green)
        }
    }
    
    private func categoryColor(for category: GroceryCategory) -> Color {
        switch category.name.lowercased() {
        case "produce": return .green
        case "dairy": return .blue
        case "meat": return .red
        case "bakery": return .orange
        case "frozen": return .cyan
        case "pantry": return .brown
        case "beverages": return .blue.opacity(0.8)
        case "household": return .purple
        default: return .gray
        }
    }
}

// SearchBar removed as per user request

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GroceryStore())
    }
}

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var store: GroceryStore
    @State private var showingAddItem = false
    @State private var showingActionSheet = false
    @State private var showingShareSheet = false
    @State private var selectedCategory: GroceryCategory? = nil
    @State private var isGroupedByCategory = true
    @State private var showingSidebar = false
    
    private var currentItems: [GroceryItem] {
        store.selectedList?.items ?? []
    }
    
    private var filteredItems: [GroceryItem] {
        if let category = selectedCategory {
            return currentItems.filter { $0.category == category }
        }
        return currentItems
    }
    
    private var sortedItems: [GroceryItem] {
        filteredItems.sorted { $0.name < $1.name }
    }
    
    private var categories: [GroceryCategory] {
        var result = [GroceryCategory]()
        for category in GroceryCategory.allCases {
            if currentItems.contains(where: { $0.category == category }) {
                result.append(category)
            }
        }
        return result
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        Group {
            if store.selectedList == nil {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No List Selected")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Select a list from the sidebar or create a new one to get started.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Items Yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Tap the + button to add your first item.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - List Views
    private var groupedItemsList: some View {
        List {
            ForEach(GroceryCategory.allCases, id: \.self) { category in
                let items = filteredItems.filter { $0.category == category }
                if !items.isEmpty {
                    Section(header: Text(category.name)) {
                        ForEach(items) { item in
                            ItemRow(item: item, listId: store.selectedList?.id)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var flatItemsList: some View {
        List {
            ForEach(filteredItems) { item in
                ItemRow(item: item, listId: store.selectedList?.id)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Add Item Button
    private var addItemButton: some View {
        Button(action: { showingAddItem = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Item")
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private var shareText: String? {
        guard let list = store.selectedList, !list.items.isEmpty else { return nil }
        
        var shareText = "\(list.name):\n\n"
        
        for item in list.items {
            let quantityText = item.quantity > 1 ? "\(item.quantity)x " : ""
            let notesText = item.notes.isEmpty ? "" : " (\(item.notes))"
            let completed = item.isCompleted ? "✓ " : "- "
            shareText += "\(completed)\(quantityText)\(item.name)\(notesText)\n"
        }
        
        return shareText
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !filteredItems.isEmpty {
                    CategoryFilterView(
                        selectedCategory: $selectedCategory,
                        categories: categories
                    )
                    
                    if isGroupedByCategory {
                        groupedItemsList
                    } else {
                        flatItemsList
                    }
                } else {
                    emptyStateView
                }
                
                if store.selectedList != nil {
                    addItemButton
                }
            }
            .navigationTitle(store.selectedList?.name ?? "GroGetter")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSidebar = true }) {
                        Image(systemName: "sidebar.left")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ListActionsView(
                        showingActionSheet: $showingActionSheet,
                        showingShareSheet: $showingShareSheet,
                        showingAddItem: $showingAddItem,
                        store: store,
                        shareText: shareText
                    )
                }
            }
            .sheet(isPresented: $showingAddItem) {
                if let listId = store.selectedList?.id {
                    ItemDetailView(item: nil)
                        .environmentObject(store)
                }
            }
            .sheet(isPresented: $showingSidebar) {
                ListSidebarView()
                    .environmentObject(store)
            }
        }
    }
}

import SwiftUI

struct ItemRow: View {
    @EnvironmentObject private var store: GroceryStore
    let item: GroceryItem
    let listId: UUID?
    
    @State private var showingDetail = false
    
    private func toggleCompletion() {
        if let listId = listId {
            store.toggleItemCompletion(item, in: listId)
        }
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
                    if !item.category.name.isEmpty {
                        Text(item.category.name.prefix(1).capitalized)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingDetail) {
                ItemDetailView(item: item)
                    .environmentObject(store)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ItemRow_Previews: PreviewProvider {
    static var previews: some View {
        let testItem = GroceryItem(
            id: UUID(),
            name: "Test Item",
            category: GroceryCategory(name: "Produce"),
            quantity: 1,
            unit: .piece,
            isCompleted: false,
            notes: ""
        )
        return ItemRow(item: testItem, listId: UUID())
            .environmentObject(GroceryStore())
    }
}

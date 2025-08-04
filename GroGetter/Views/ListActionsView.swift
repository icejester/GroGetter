import SwiftUI

struct ListActionsView: View {
    @Binding var showingActionSheet: Bool
    @Binding var showingShareSheet: Bool
    @Binding var showingAddItem: Bool
    @ObservedObject var store: GroceryStore
    var shareText: String?
    
    var body: some View {
        HStack {
            if store.selectedList != nil {
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis.circle")
                }
                .actionSheet(isPresented: $showingActionSheet) {
                    ActionSheet(
                        title: Text("List Actions"),
                        buttons: [
                            .default(Text("Share List")) { showingShareSheet = true },
                            .destructive(Text("Clear Completed")) {
                                if let list = store.selectedList {
                                    store.clearCompletedItems(in: list)
                                }
                            },
                            .destructive(Text("Delete List")) {
                                if let list = store.selectedList {
                                    store.deleteList(list)
                                }
                            },
                            .cancel()
                        ]
                    )
                }
                .sheet(isPresented: $showingShareSheet) {
                    if let shareText = shareText {
                        ShareSheet(activityItems: [shareText])
                    }
                }
            }
        }
    }
}

struct ListActionsView_Previews: PreviewProvider {
    @State static var store = GroceryStore()
    
    static var previews: some View {
        ListActionsView(
            showingActionSheet: .constant(false),
            showingShareSheet: .constant(false),
            showingAddItem: .constant(false),
            store: store,
            shareText: "Sample share text"
        )
        .previewLayout(.sizeThatFits)
    }
}

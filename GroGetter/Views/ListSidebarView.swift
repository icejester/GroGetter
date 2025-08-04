import SwiftUI

struct ListSidebarView: View {
    @EnvironmentObject private var store: GroceryStore
    @State private var showingNewListSheet = false
    @State private var newListName = ""
    @State private var listToRename: GroceryList?
    @State private var renameText = ""
    
    var body: some View {
        // Debug information
        let _ = print("ListSidebarView - selectedListId:", store.selectedListId ?? "nil")
        let _ = print("ListSidebarView - lists count:", store.lists.count)
        
        return List {
            Section(header: Text("My Lists")) {
                ForEach(store.lists) { list in
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.accentColor)
                        Text(list.name)
                            .lineLimit(1)
                        Spacer()
                        
                        if store.lists.count > 1 {
                            Menu {
                                Button(role: .destructive) {
                                    store.deleteList(list)
                                } label: {
                                    Label("Delete List", systemImage: "trash")
                                }
                                
                                Button {
                                    listToRename = list
                                    renameText = list.name
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .contentShape(Rectangle())
                    .listRowBackground(store.selectedListId == list.id ? Color.accentColor.opacity(0.2) : Color.clear)
                    .onTapGesture {
                        print("ListSidebarView - Tapped list:", list.id, list.name)
                        print("ListSidebarView - Current selectedListId before change:", store.selectedListId?.uuidString ?? "nil")
                        
                        // Update the selected list
                        store.selectedListId = list.id
                        
                        // Debug print after setting the new ID
                        print("ListSidebarView - selectedListId after change:", store.selectedListId?.uuidString ?? "nil")
                        
                        // Force UI update by toggling the selection
                        let currentId = store.selectedListId
                        store.selectedListId = nil
                        DispatchQueue.main.async {
                            print("ListSidebarView - Restoring selectedListId after delay:", currentId?.uuidString ?? "nil")
                            store.selectedListId = currentId
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            store.deleteList(list)
                        } label: {
                            Label("Delete List", systemImage: "trash")
                        }
                        
                        Button {
                            listToRename = list
                            renameText = list.name
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem {
                Button(action: { showingNewListSheet = true }) {
                    Label("Add List", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewListSheet) {
            newListSheet
        }
        .alert("Rename List", isPresented: Binding(
            get: { listToRename != nil },
            set: { if !$0 { listToRename = nil } }
        ), actions: {
            TextField("List Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                listToRename = nil
            }
            Button("Rename") {
                if let list = listToRename {
                    var updatedList = list
                    updatedList.name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.updateList(updatedList)
                    listToRename = nil
                }
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        })
    }
    
    private var newListSheet: some View {
        NavigationView {
            Form {
                TextField("List Name", text: $newListName)
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingNewListSheet = false
                        newListName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty {
                            _ = store.createNewList(name: name)
                        }
                        showingNewListSheet = false
                        newListName = ""
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

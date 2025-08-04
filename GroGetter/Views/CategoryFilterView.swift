import SwiftUI

struct CategoryFilterView: View {
    @Binding var selectedCategory: GroceryCategory?
    let categories: [GroceryCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        action: {
                            selectedCategory = (selectedCategory?.id == category.id) ? nil : category
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryFilterView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryFilterView(
            selectedCategory: .constant(nil),
            categories: [
                GroceryCategory(name: "Produce"),
                GroceryCategory(name: "Dairy"),
                GroceryCategory(name: "Bakery")
            ]
        )
        .previewLayout(.sizeThatFits)
    }
}

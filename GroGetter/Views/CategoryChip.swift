import SwiftUI

struct CategoryChip: View {
    let category: GroceryCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? category.color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(category.color, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CategoryChip(category: GroceryCategory(name: "Produce"), isSelected: true, action: {})
            CategoryChip(category: GroceryCategory(name: "Dairy"), isSelected: false, action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

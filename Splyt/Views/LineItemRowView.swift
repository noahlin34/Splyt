import SwiftUI

struct LineItemRowView: View {
    let item: LineItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                if let person = item.assignedPerson {
                    Label(person.name, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(person.color)
                } else {
                    Text("Tap to edit")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(item.price, format: .currency(code: "USD"))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

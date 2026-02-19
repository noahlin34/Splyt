import SwiftUI

struct ReceiptRowView: View {
    let receipt: Receipt

    private var formattedDate: String {
        receipt.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(receipt.restaurantName ?? "Receipt")
                .font(.headline)
            HStack {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(receipt.total, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            if !receipt.lineItems.isEmpty {
                let assignedCount = receipt.lineItems.filter { $0.assignedPerson != nil }.count
                Text("\(receipt.lineItems.count) items · \(assignedCount) assigned")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

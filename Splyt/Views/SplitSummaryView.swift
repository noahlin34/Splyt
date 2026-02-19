import SwiftUI

struct SplitSummaryView: View {
    let receipt: Receipt
    @Environment(\.dismiss) private var dismiss

    private var splits: [PersonSplit] {
        PersonSplit.calculate(for: receipt)
    }

    private var unassigned: [LineItem] {
        receipt.lineItems.filter { $0.assignedPerson == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(splits) { split in
                    Section {
                        HStack {
                            Circle()
                                .fill(split.person.color)
                                .frame(width: 16, height: 16)
                            Text(split.person.name)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(split.total, format: .currency(code: "USD"))
                                .fontWeight(.bold)
                        }

                        ForEach(split.items) { item in
                            HStack {
                                Text(item.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(item.price, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack {
                            Text("Tax share")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text(split.taxShare, format: .currency(code: "USD"))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        if receipt.tipPercentage > 0 {
                            HStack {
                                Text("Tip share")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                Text(split.tipShare, format: .currency(code: "USD"))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                if !unassigned.isEmpty {
                    Section("Unassigned") {
                        ForEach(unassigned) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text(item.price, format: .currency(code: "USD"))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Split Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

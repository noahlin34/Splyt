import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Bindable var receipt: Receipt
    var capturedImage: UIImage?

    @Environment(\.modelContext) private var modelContext
    @State private var isProcessing: Bool
    @State private var selectedLineItem: LineItem?
    @State private var showingSplitSummary = false

    init(receipt: Receipt, capturedImage: UIImage? = nil) {
        self.receipt = receipt
        self.capturedImage = capturedImage
        _isProcessing = State(initialValue: capturedImage != nil)
    }

    var body: some View {
        Group {
            if isProcessing, let image = capturedImage {
                ProcessingView(receipt: receipt, image: image) {
                    isProcessing = false
                }
            } else {
                mainContent
            }
        }
        .navigationTitle(receipt.restaurantName ?? "Receipt")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !isProcessing && !receipt.lineItems.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Split") { showingSplitSummary = true }
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingSplitSummary) {
            SplitSummaryView(receipt: receipt)
        }
        .sheet(item: $selectedLineItem) { item in
            PersonPickerView(lineItem: item)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if receipt.lineItems.isEmpty {
            ContentUnavailableView(
                "No Items",
                systemImage: "list.bullet.rectangle",
                description: Text("No items were found on this receipt.")
            )
        } else {
            List {
                Section("Items") {
                    ForEach(receipt.lineItems) { item in
                        LineItemRowView(item: item)
                            .onTapGesture { selectedLineItem = item }
                    }
                }

                Section("Charges") {
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(receipt.taxAmount, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tip")
                            Spacer()
                            Text(receipt.tipPercentage, format: .percent.precision(.fractionLength(0)))
                                .foregroundStyle(.secondary)
                            Text(receipt.tipAmount, format: .currency(code: "USD"))
                                .foregroundStyle(.secondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        Slider(value: $receipt.tipPercentage, in: 0...0.30, step: 0.01)
                            .tint(.green)
                    }
                }

                Section {
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(receipt.total, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

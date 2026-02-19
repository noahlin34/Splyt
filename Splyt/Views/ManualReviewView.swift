import SwiftUI
import SwiftData

struct ManualReviewView: View {
    let receipt: Receipt
    let ocrText: String
    let initialDrafts: [(name: String, price: Double)]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draftItems: [DraftItem]
    @State private var taxText: String
    @State private var showingOCRText = false

    init(receipt: Receipt, ocrText: String, initialDrafts: [(name: String, price: Double)]) {
        self.receipt = receipt
        self.ocrText = ocrText
        self.initialDrafts = initialDrafts
        _draftItems = State(initialValue: initialDrafts.map {
            DraftItem(name: $0.name, priceText: String(format: "%.2f", $0.price))
        })
        _taxText = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            List {
                infoSection
                itemsSection
                taxSection
            }
            .navigationTitle("Review Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("OCR Text") { showingOCRText.toggle() }
                        .font(.caption)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirm") { confirm() }
                        .fontWeight(.semibold)
                        .disabled(draftItems.isEmpty)
                }
            }
            .sheet(isPresented: $showingOCRText) {
                ocrTextSheet
            }
        }
    }

    private var infoSection: some View {
        Section {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Apple Intelligence isn't available on this device. Review what we found and make any corrections.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var itemsSection: some View {
        Section("Items") {
            ForEach($draftItems) { $item in
                HStack {
                    TextField("Item name", text: $item.name)
                    Spacer()
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: $item.priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                }
            }
            .onDelete { indexSet in
                draftItems.remove(atOffsets: indexSet)
            }
            .onMove { source, destination in
                draftItems.move(fromOffsets: source, toOffset: destination)
            }

            Button {
                draftItems.append(DraftItem(name: "", priceText: ""))
            } label: {
                Label("Add Item", systemImage: "plus.circle")
            }
        }
    }

    private var taxSection: some View {
        Section("Tax") {
            HStack {
                Text("Tax Amount")
                Spacer()
                Text("$")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $taxText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
            }
        }
    }

    private var ocrTextSheet: some View {
        NavigationStack {
            ScrollView {
                Text(ocrText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Scanned Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingOCRText = false }
                }
            }
        }
    }

    private func confirm() {
        let tax = Double(taxText) ?? 0
        receipt.taxAmount = tax

        for draft in draftItems {
            guard !draft.name.trimmingCharacters(in: .whitespaces).isEmpty,
                  let price = draft.price else { continue }
            let item = LineItem(name: draft.name.trimmingCharacters(in: .whitespaces), price: price)
            item.receipt = receipt
            modelContext.insert(item)
        }
        dismiss()
    }
}

private struct DraftItem: Identifiable {
    let id = UUID()
    var name: String
    var priceText: String
    var price: Double? { Double(priceText) }
}

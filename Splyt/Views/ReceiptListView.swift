import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.createdAt, order: .reverse) private var receipts: [Receipt]

    @State private var showingScanView = false
    @State private var showingPersonManager = false
    @State private var pendingReceipt: Receipt?
    @State private var pendingImage: UIImage?
    @State private var navigateToReceipt = false

    var body: some View {
        NavigationStack {
            Group {
                if receipts.isEmpty {
                    ContentUnavailableView(
                        "No Receipts Yet",
                        systemImage: "receipt",
                        description: Text("Tap the camera button to scan your first bill.")
                    )
                } else {
                    List {
                        ForEach(receipts) { receipt in
                            NavigationLink(value: receipt) {
                                ReceiptRowView(receipt: receipt)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { modelContext.delete(receipts[$0]) }
                        }
                    }
                }
            }
            .navigationTitle("Splyt")
            .navigationDestination(for: Receipt.self) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            .navigationDestination(isPresented: $navigateToReceipt) {
                if let receipt = pendingReceipt, let image = pendingImage {
                    ReceiptDetailView(receipt: receipt, capturedImage: image)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("People", systemImage: "person.2") {
                        showingPersonManager = true
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingScanView = true
                    } label: {
                        Label("Scan Bill", systemImage: "camera.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .sheet(isPresented: $showingScanView) {
                ScanView { image in
                    handleScannedImage(image)
                }
            }
            .sheet(isPresented: $showingPersonManager) {
                PersonManagerView()
            }
        }
    }

    private func handleScannedImage(_ image: UIImage) {
        let receipt = Receipt()
        receipt.imageData = image.jpegData(compressionQuality: 0.8)
        modelContext.insert(receipt)
        pendingReceipt = receipt
        pendingImage = image
        navigateToReceipt = true
    }
}

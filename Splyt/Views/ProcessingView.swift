import SwiftUI

enum ProcessingPhase: Equatable {
    case ocr
    case parsing
    case failed(String)

    static func == (lhs: ProcessingPhase, rhs: ProcessingPhase) -> Bool {
        switch (lhs, rhs) {
        case (.ocr, .ocr), (.parsing, .parsing): return true
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}

struct ProcessingView: View {
    let receipt: Receipt
    let image: UIImage

    @Environment(\.modelContext) private var modelContext
    @State private var phase: ProcessingPhase = .ocr
    @State private var navigateToManualReview = false
    @State private var manualDrafts: [(name: String, price: Double)] = []
    @State private var ocrText: String = ""

    private let ocrService = OCRService()
    private let parsingService = BillParsingService()

    var onComplete: () -> Void

    var body: some View {
        Group {
            switch phase {
            case .ocr:
                statusView(icon: "doc.viewfinder", message: "Reading your bill…", isLoading: true)
            case .parsing:
                statusView(icon: "brain", message: "Understanding items…", subtitle: "Apple Intelligence is at work", isLoading: true)
            case .failed(let message):
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        phase = .ocr
                        Task { await process() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
            }
        }
        .navigationDestination(isPresented: $navigateToManualReview) {
            ManualReviewView(receipt: receipt, ocrText: ocrText, initialDrafts: manualDrafts)
                .onDisappear { onComplete() }
        }
        .task { await process() }
    }

    @ViewBuilder
    private func statusView(icon: String, message: String, subtitle: String? = nil, isLoading: Bool) -> some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .controlSize(.extraLarge)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
            }
            Text(message)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
    }

    private func process() async {
        do {
            // Step 1: OCR
            phase = .ocr
            let text = try await ocrService.recognizeText(from: image)
            ocrText = text
            receipt.rawOCRText = text

            if parsingService.isAvailable {
                // Step 2a: AI parsing
                phase = .parsing
                let parsed = try await parsingService.parse(ocrText: text)

                receipt.restaurantName = parsed.restaurantName
                receipt.taxAmount = parsed.taxAmount

                for item in parsed.lineItems {
                    let lineItem = LineItem(name: item.name, price: item.price)
                    lineItem.receipt = receipt
                    modelContext.insert(lineItem)
                }
                onComplete()
            } else {
                // Step 2b: Fallback — regex best-effort then manual review
                manualDrafts = ocrService.bestEffortLineItems(from: text)
                navigateToManualReview = true
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

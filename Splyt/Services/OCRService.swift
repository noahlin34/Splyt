import Vision
import UIKit

final class OCRService {
    enum OCRError: Error, LocalizedError {
        case imageConversionFailed
        case noTextFound

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed: return "Could not process the image."
            case .noTextFound: return "No text could be read from the image."
            }
        }
    }

    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw OCRError.imageConversionFailed }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = ImageRequestHandler(cgImage, orientation: orientation)
        let request = RecognizeDocumentsRequest()
        let observations: [DocumentObservation] = try await handler.perform(request)

        let text = observations
            .compactMap { $0.document.text?.transcript }
            .joined(separator: "\n")

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OCRError.noTextFound
        }
        return text
    }

    // Best-effort regex parse for the manual review fallback
    func bestEffortLineItems(from ocrText: String) -> [(name: String, price: Double)] {
        // Match lines like: "Burger        12.99" or "Burger $12.99"
        let pattern = #"^(.+?)\s+\$?(\d{1,3}(?:\.\d{2}))$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return []
        }
        var results: [(name: String, price: Double)] = []
        let range = NSRange(ocrText.startIndex..., in: ocrText)
        for match in regex.matches(in: ocrText, range: range) {
            guard match.numberOfRanges == 3,
                  let nameRange = Range(match.range(at: 1), in: ocrText),
                  let priceRange = Range(match.range(at: 2), in: ocrText),
                  let price = Double(ocrText[priceRange]) else { continue }
            let name = String(ocrText[nameRange]).trimmingCharacters(in: .whitespaces)
            // Skip obvious non-item lines
            let lowered = name.lowercased()
            if lowered.contains("total") || lowered.contains("tax") ||
               lowered.contains("tip") || lowered.contains("subtotal") ||
               lowered.contains("balance") || lowered.contains("amount") { continue }
            results.append((name: name, price: price))
        }
        return results
    }
}

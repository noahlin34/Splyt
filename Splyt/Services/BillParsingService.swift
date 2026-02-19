import Foundation
import FoundationModels

@Generable
struct ParsedBill {
    @Guide(description: "The name of the restaurant, if visible on the bill")
    var restaurantName: String?

    @Guide(description: "Individual food and drink line items only. Do not include tax, tip, subtotal, or total rows.")
    var lineItems: [ParsedLineItem]

    @Guide(description: "The tax amount in dollars extracted from the bill")
    var taxAmount: Double
}

@Generable
struct ParsedLineItem {
    @Guide(description: "The name or description of the menu item")
    var name: String

    @Guide(description: "The price of this item in dollars")
    var price: Double
}

final class BillParsingService {
    enum ParseError: Error, LocalizedError {
        case modelUnavailable(SystemLanguageModel.Availability.UnavailableReason)
        case parsingFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelUnavailable(let reason):
                switch reason {
                case .appleIntelligenceNotEnabled:
                    return "Apple Intelligence is not enabled. You can enable it in Settings > Apple Intelligence & Siri."
                case .deviceNotEligible:
                    return "This device does not support Apple Intelligence."
                case .modelNotReady:
                    return "The on-device model is not ready yet. Please try again in a moment."
                @unknown default:
                    return "Apple Intelligence is not available."
                }
            case .parsingFailed(let detail):
                return "Could not parse the bill: \(detail)"
            }
        }
    }

    var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    func parse(ocrText: String) async throws -> ParsedBill {
        guard case .available = SystemLanguageModel.default.availability else {
            if case .unavailable(let reason) = SystemLanguageModel.default.availability {
                throw ParseError.modelUnavailable(reason)
            }
            throw ParseError.parsingFailed("Unknown availability state")
        }

        let session = LanguageModelSession()
        let response = try await session.respond(generating: ParsedBill.self) {
            """
            Parse this restaurant receipt text. Extract all food and drink line items with their prices.
            Do not include totals, subtotals, tax lines, or tip lines as lineItems.
            Receipt text:
            \(ocrText)
            """
        }
        return response.content
    }
}

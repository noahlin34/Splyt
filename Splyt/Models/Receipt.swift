import Foundation
import SwiftData

@Model
final class Receipt {
    var createdAt: Date
    var imageData: Data?
    var rawOCRText: String?
    var taxAmount: Double
    var tipPercentage: Double
    var restaurantName: String?

    @Relationship(deleteRule: .cascade, inverse: \LineItem.receipt)
    var lineItems: [LineItem] = []

    var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.price }
    }

    var tipAmount: Double {
        subtotal * tipPercentage
    }

    var total: Double {
        subtotal + taxAmount + tipAmount
    }

    init(createdAt: Date = .now, taxAmount: Double = 0, tipPercentage: Double = 0) {
        self.createdAt = createdAt
        self.taxAmount = taxAmount
        self.tipPercentage = tipPercentage
    }
}

import Foundation
import SwiftData

struct PersonSplit: Identifiable {
    let id: PersistentIdentifier
    let person: Person
    let items: [LineItem]
    let taxShare: Double
    let tipShare: Double

    var subtotal: Double {
        items.reduce(0) { $0 + $1.price }
    }

    var total: Double {
        subtotal + taxShare + tipShare
    }

    static func calculate(for receipt: Receipt) -> [PersonSplit] {
        let receiptSubtotal = receipt.subtotal
        guard receiptSubtotal > 0 else { return [] }

        let assigned = receipt.lineItems.filter { $0.assignedPerson != nil }
        let grouped = Dictionary(grouping: assigned) { $0.assignedPerson! }

        return grouped.map { person, items in
            let personSubtotal = items.reduce(0) { $0 + $1.price }
            let proportion = personSubtotal / receiptSubtotal
            return PersonSplit(
                id: person.persistentModelID,
                person: person,
                items: items,
                taxShare: receipt.taxAmount * proportion,
                tipShare: receipt.tipAmount * proportion
            )
        }
        .sorted { $0.person.name < $1.person.name }
    }
}

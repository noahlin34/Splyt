import Foundation
import SwiftData

@Model
final class LineItem {
    var name: String
    var price: Double
    var receipt: Receipt?

    @Relationship(deleteRule: .nullify)
    var assignedPerson: Person?

    init(name: String, price: Double) {
        self.name = name
        self.price = price
    }
}

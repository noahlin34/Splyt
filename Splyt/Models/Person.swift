import SwiftUI
import SwiftData

@Model
final class Person {
    var name: String
    var colorHex: String

    @Relationship(inverse: \LineItem.assignedPerson)
    var assignedItems: [LineItem] = []

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
    }
}

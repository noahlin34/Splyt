import SwiftUI
import SwiftData

@Model
final class Person {
    var name: String
    var colorHex: String
    var isCurrentUser: Bool = false

    @Relationship(inverse: \LineItem.assignedPerson)
    var assignedItems: [LineItem] = []

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    init(name: String, colorHex: String, isCurrentUser: Bool = false) {
        self.name = name
        self.colorHex = colorHex
        self.isCurrentUser = isCurrentUser
    }
}

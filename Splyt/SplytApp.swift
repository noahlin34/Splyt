import SwiftUI
import SwiftData

@main
struct SplytApp: App {
    var body: some Scene {
        WindowGroup {
            ReceiptListView()
        }
        .modelContainer(for: [Receipt.self, LineItem.self, Person.self])
    }
}

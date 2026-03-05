import SwiftUI
import SwiftData

@main
struct SplytApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                ReceiptListView()
                    .tabItem { Label("History", systemImage: "clock") }
            }
            .tint(Color.splytGreen)
        }
        .modelContainer(for: [Receipt.self, LineItem.self, Person.self])
    }
}

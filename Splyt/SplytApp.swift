//
//  SplytApp.swift
//  Splyt
//
//  Created by Noah Lin  on 2026-02-19.
//

import SwiftUI
import CoreData

@main
struct SplytApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

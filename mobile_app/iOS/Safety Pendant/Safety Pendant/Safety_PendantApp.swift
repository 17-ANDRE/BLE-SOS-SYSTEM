//
//  Safety_PendantApp.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-01-26.
//

import SwiftUI
import Firebase //Main Firebase SDK for initialization

@main
//Application entry point
struct Safety_PendantApp: App {
    init() {
        FirebaseApp.configure() //connecting app to Firebase on start
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

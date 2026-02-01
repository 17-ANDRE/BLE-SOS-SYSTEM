//
//  ContentView.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-01-26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()

    var body: some View {
        VStack {
            Text(bleManager.statusText)
                .foregroundColor(.white)
                .padding()

            Button("Scan for Pendant") {
                bleManager.startScan()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-01-26.
//

import SwiftUI
// vibration feedback
import CoreHaptics

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @State private var showingAlert = false //alert showing?
    @State private var engine: CHHapticEngine? //Vibration
    
    //show pendant status
    var body: some View {
        VStack(spacing: 20) {
            Text(bleManager.statusText)
                .foregroundColor(.white)
                .padding()
    //Button to scan for the pendant
            Button("Scan for Pendant") {
                bleManager.startScan()
            }
            .padding()
        }
    //Prepare haptics when ContentView is loaded on the screen
        .onAppear{
            prepareHaptics()
        }
        //Listen for changes in BLEManager status text
        .onChange(of: bleManager.statusText) {
            // Trigger SOS actions when button pressed
            if bleManager.statusText.contains("SOS BUTTON PRESSED") {
                triggerHaptic()
                showingAlert = true
            }
        }
        //Popup alert when SOS Button is Pressed
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("SOS!"),
                message: Text("SOS TRIGGERED!"),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // Prepare the haptic engine
    func prepareHaptics() {
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        }
        //Control for phones that do not support haptics
        catch {
            print("Haptics not supported: \(error.localizedDescription)")
        }
    }
    
    // Play a short vibration
    func triggerHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()
        
        // vibration intensity and sharpness
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error.localizedDescription)")
        }
    }
}

//SwiftUI's simulation
#Preview {
    ContentView()
}


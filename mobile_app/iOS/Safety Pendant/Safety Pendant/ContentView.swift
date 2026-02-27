//
//  ContentView.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-01-26.
//

import SwiftUI
// in-app vibration feedback
import CoreHaptics

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @State private var showingAlert = false //alert showing?
    @State private var engine: CHHapticEngine? //Vibration
    
    //show pendant status
    var body: some View {
        VStack(spacing: 20) {
            Text(bleManager.statusText)
                .foregroundColor(.gray)
                .padding()
    //Button to scan for the pendant
            if !bleManager.isConnected {
                Button("Scan for Pendant") {
                    bleManager.startScan()
                }
                .padding()
            } else {
                Button("Disconnect Device") {
                    bleManager.disconnect()
                }
                .padding()
                .foregroundColor(.red)
            }
        }
    //Prepare haptics & initially ask for notification permissions when ContentView is loaded on the screen
        .onAppear{
            bleManager.requestNotificationPermission() //permission pop-up
            prepareHaptics()
        }
        //Listen for changes in BLEManager trigger
        .onChange(of: bleManager.sosTriggered) { oldValue,newValue in
            // Trigger SOS actions when button pressed
            if newValue {
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
        
        // Safety net in case of hapticEngine fail
        if engine == nil {
            engine = try? CHHapticEngine()
        }

        try? engine?.start()
        
        var events = [CHHapticEvent]()
        
        // stronger pattern of vibration
        for i in 0..<3 {
            let startTime = Double(i) * 0.4 // Spaced 0.4 seconds apart
            
            // High intensity and High sharpness (1.0) for an aggressive feel
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            
            // Ensures app has a long and heavy vibration not a tap
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: startTime,
                duration: 0.5
            )
            events.append(event)
        }
        
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


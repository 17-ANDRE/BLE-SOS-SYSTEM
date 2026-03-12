//
//  BLEManager.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-01-26.
//

import Foundation
import CoreBluetooth //SWIFT's BLE operator
import Combine    //To update the UI
import UserNotifications //To add banner alerts
import AudioToolbox //To implement background vibrations
import CoreLocation //To get location of the user
import FirebaseFirestore //storage of events to cloud
import FirebaseAuth //Ensuring user is signed in

//class for the entire BLE Management(scanning,connecting and notifications)
class BLEManager: NSObject, ObservableObject {
    
    @Published var statusText = "Initializing Bluetooth…" //message when app is opened
    @Published var isConnected = false   //Connection property
    
    @Published var sosTriggered = false  //defines state of the system
    
    private var centralManager: CBCentralManager!  // Manager to scan and connect to BLE peripherals
    private var sosPeripheral: CBPeripheral? //peripheral property
    
    private var locationManager: CLLocationManager?
    private var latestLocation: CLLocation?
    // UUIDs
    private let sosServiceUUID = CBUUID(
        string: "524208a3-bb12-46e1-bdb4-7a080a8c5739"
    )
    
    // Handling Automatic reconnection
       private var userDisconnected = false           // Tracks if user manually disconnected
       private var reconnectTimer: Timer?             // Timer to throttle auto-reconnect attempts
       private let reconnectInterval: TimeInterval = 5.0 // Seconds between auto-reconnect attempts
    
    //initializing the central manager
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "SafetyPendantCentral"]) //receives central manager callbacks & Allows iOS to relaunch app in background
        
        //setting up the GPS system
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
    }
    
//To request notification permission for alerts and sounds
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { print("Notifications allowed") }
        }
    }

    func sendSOSNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SOS ALERT"
        content.body = "HELP! DEVICE PRESSED!"
        content.sound = UNNotificationSound.default
        
        // Background vibration matching the CoreHaptic in-app
            for i in 0..<3 {
                let delay = Double(i) * 0.4
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
            }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    func grabLocationOnce() {
        locationManager?.requestLocation()
    }
}
extension BLEManager: CBCentralManagerDelegate {
    //Function for state change
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusText = "Bluetooth is ON, ready to scan"
        case .poweredOff:
            statusText = "Bluetooth is OFF"
        default:
            statusText = "Bluetooth unavailable"
        }
    }
    // function called when the scan button is hit on the screen
    func startScan() {
        // Stop any previous scans
           centralManager.stopScan()
        // Resetting peripheral
             sosPeripheral = nil
             isConnected = false
        //checking whether the user disconnected
             userDisconnected = false
        statusText = "Scanning for Safety Pendant…"
        centralManager.scanForPeripherals(withServices: [sosServiceUUID], options: nil)
        
        //Stop scanning timer to prevent infinite scanning.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self, self.sosPeripheral == nil else { return }
            self.centralManager.stopScan()
            self.statusText = "Unable to find device, Please make sure device is nearby and try again."
        }
    }
    //function for when the disconnect button is hit
    func disconnect() {
        userDisconnected = true  // User intentionally disconnected
        reconnectTimer?.invalidate()  // Stop any pending reconnect attempts
        
        if let peripheral = sosPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    //Function for each time a peripheral is discovered
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        //Checking for the peripheral's name
        guard let name = peripheral.name, name.contains("Safety Pendant") else {
            return
        }
        //Double checking. Ensures that MY device is connected using UUID
        if let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], services.contains(sosServiceUUID){
            
            statusText = "Found Safety Pendant, connecting…"
            sosPeripheral = peripheral       // save reference
            centralManager.stopScan()        // stop scanning
            centralManager.connect(peripheral, options: nil)  // start connection
        }
    }
    //function call once the device is successfully connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusText = "Connected to Safety Pendant"
        peripheral.delegate = self
        peripheral.discoverServices([sosServiceUUID])
    }
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        // Scenario 1: User manually disconnected
        if userDisconnected {
            statusText = "Device Disconnected"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.statusText = "Scan for Pendant"
            }
            userDisconnected = false  // Reset for future disconnects
            return
        }

        //Scenario 2: Unexpected disconnect (out of range, signal drop, etc.)
        statusText = "Device out of range…"
        reconnectTimer?.invalidate()  // Prevent multiple auto reconnecting attempts
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval,
                                              repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // Only try reconnecting if still disconnected
            if !self.isConnected {
                self.statusText = "Reconnecting…"
                self.startScan()
            }
        }
    }
    
    //Function call to ensure that the app regains peripheral reference if app is killed.
    func centralManager(_ central: CBCentralManager,
                        willRestoreState dict: [String : Any]) {

        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral],
           let restoredPeripheral = peripherals.first {

            sosPeripheral = restoredPeripheral
            sosPeripheral?.delegate = self

            statusText = "Restored connection"
        }
    }
}
//Delegate to receive events from microcontroller
extension BLEManager: CBPeripheralDelegate {
    // function call to discover SOS characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == sosServiceUUID {
                peripheral.discoverCharacteristics(
                    [CBUUID(string: "cd0e8ecb-44b2-4319-8116-8523c80ba903")],
                    for: service
                )
            }
        }
    }
    // function call after characteristics are reported
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == CBUUID(string: "cd0e8ecb-44b2-4319-8116-8523c80ba903") {
                peripheral.setNotifyValue(true, for: characteristic)
                statusText = "Listening for SOS button"
            }
        }
    }
    //function call for notifications
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value,
              let value = String(data: data, encoding: .utf8) else { return }
    //Have boolean state 
        if value == "1" {
            sosTriggered = true
            sendSOSNotification()
            grabLocationOnce()
        } else {
            sosTriggered = false
        }
    }
}
//Delegate to get the user location at time of SOS pressing
extension BLEManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.last else { return }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        print("Latitude: \(latitude)")
        print("Longitude: \(longitude)")

        // Make sure user is signed in before saving alert
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in, alert not saved")
            return
        }
        //storage of events to database
        let db = Firestore.firestore()
        let alertData: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": FieldValue.serverTimestamp(), //write the exact time the SOS was triggered
            "triggered": true
        ]
        //Database management and creation of a new document with each event
        db.collection("users")
          .document(uid)
          .collection("alerts")
          .addDocument(data: alertData)
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

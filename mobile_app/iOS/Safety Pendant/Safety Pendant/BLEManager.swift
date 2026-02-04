//
//  BLEManager.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-01-26.
//

import Foundation
import CoreBluetooth //SWIFT's BLE operator
import Combine    //To update the UI
//class for the entire BLE Management(scanning,connecting and notifications)
class BLEManager: NSObject, ObservableObject {
    
    @Published var statusText = "Initializing Bluetooth…" //message when app is opened
    
    private var centralManager: CBCentralManager!  // Manager to scan and connect to BLE peripherals
    private var sosPeripheral: CBPeripheral? //peripheral property
    
    // UUIDs
    private let sosServiceUUID = CBUUID(
        string: "524208a3-bb12-46e1-bdb4-7a080a8c5739"
    )
    //initializing the central manager
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil) //receives central manager callbacks
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
        statusText = "Scanning for Safety Pendant…"
        centralManager.scanForPeripherals(withServices: [sosServiceUUID], options: nil)
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
        statusText = "Connected to Safety Pendant"
        peripheral.delegate = self
        peripheral.discoverServices([sosServiceUUID])
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

        if value == "1" {
            statusText = "🚨 SOS BUTTON PRESSED"
        } else {
            statusText = "Button released"
        }
    }
}

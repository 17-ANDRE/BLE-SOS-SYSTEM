//
//  BLEManager.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-01-26.
//

import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    
    @Published var statusText = "Initializing Bluetooth…"
    
    private var centralManager: CBCentralManager!
    
    // UUIDs exactly from your firmware
    private let sosServiceUUID = CBUUID(
        string: "524208a3-bb12-46e1-bdb4-7a080a8c5739"
    )
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}
extension BLEManager: CBCentralManagerDelegate {
    
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
    func startScan() {
        statusText = "Scanning for Safety Pendant…"
        centralManager.scanForPeripherals(withServices: [sosServiceUUID], options: nil)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        guard let name = peripheral.name, name.contains("Safety Pendant") else {
            return
        }
        
        if let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], services.contains(sosServiceUUID){
            
            statusText = "Found Safety Pendant: \(peripheral.name ?? "Unknown")"
            centralManager.stopScan()
        }
    }
}

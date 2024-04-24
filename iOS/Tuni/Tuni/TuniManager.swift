//
//  TuniManager.swift
//  Tuni
//
//  Created by Prarthana Gajjala on 4/23/24.
//

import Foundation
import CoreBluetooth

import Foundation

class TuniManager: NSObject, ObservableObject {
    @Published var isScanning = true

    var foundLampis: [Lampi] {
        return Array(lampis.values)
    }

    private var lampis = [String: Tuni]()

    private var bluetoothManager: CBCentralManager!

    override init() {
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension TuniManager: CBCentralManagerDelegate {
    func scanForLampis() {
        if bluetoothManager.state == .poweredOn {
            isScanning = true
            print("Scanning for Lampis")
            bluetoothManager.scanForPeripherals(withServices: [Lampi.SERVICE_UUID])
            scheduleStopScan()
        }
    }

    private func scheduleStopScan() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            if !(self?.lampis.isEmpty ?? true) {
                self?.bluetoothManager.stopScan()
                self?.isScanning = false
            } else {
                print("Still scanning for lampis")
                self?.scheduleStopScan()
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        scanForLampis()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        if let peripheralName = peripheral.name {
            print("Manager found Lampi: \(peripheralName)")

            let lampi = Lampi(lampiPeripheral: peripheral)
            lampis[peripheralName] = lampi

            bluetoothManager.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Manager Connected to peripheral \(peripheral)")
        peripheral.discoverServices([Lampi.SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let peripheralName = peripheral.name,
           let lampi = lampis[peripheralName] {
            print("Manager Disconnected from peripheral \(peripheral)")

            lampi.state.isConnected = false
            bluetoothManager.connect(peripheral)
        }
    }
}

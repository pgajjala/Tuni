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

    var foundTunis: [Tuni] {
        return Array(tunis.values)
    }

    private var tunis = [String: Tuni]()

    private var bluetoothManager: CBCentralManager!

    override init() {
        print("initting Tuni Manager")
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension TuniManager: CBCentralManagerDelegate {
    func scanForTunis() {
        print("scanning")
        if bluetoothManager.state == .poweredOn {
            isScanning = true
            print("Scanning for Lampis")
            bluetoothManager.scanForPeripherals(withServices: [Tuni.SERVICE_UUID])
            scheduleStopScan()
        }
    }

    private func scheduleStopScan() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            if !(self?.tunis.isEmpty ?? true) {
                self?.bluetoothManager.stopScan()
                self?.isScanning = false
            } else {
                print("Still scanning for lampis")
                self?.scheduleStopScan()
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        scanForTunis()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        if let peripheralName = peripheral.name {
            print("Manager found Tuni: \(peripheralName)")

            let tuni = Tuni(tuniPeripheral: peripheral)
            tunis[peripheralName] = tuni

            bluetoothManager.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Manager Connected to peripheral \(peripheral)")
        peripheral.discoverServices([Tuni.SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let peripheralName = peripheral.name,
           let tuni = tunis[peripheralName] {
            print("Manager Disconnected from peripheral \(peripheral)")

            tuni.state.isConnected = false
            bluetoothManager.connect(peripheral)
        }
    }
}

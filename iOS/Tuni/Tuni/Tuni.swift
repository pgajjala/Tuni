//
//  Tuni.swift
//  Tuni
//
//  Created by Prarthana Gajjala on 3/26/24.
//
//  Code modified from AudioKit Cookbook
//  https://github.com/AudioKit/Cookbook
//

import Foundation
import AudioKit
import AudioKitEX
import SoundpipeAudioKit
import CoreBluetooth
import Combine
import SwiftUI


@Observable class Tuni: NSObject {
    let name: String
    var state = State() {
        didSet {
            if oldValue != state {
                updateDevice()
            }
        }
    }

    private func setupPeripheral() {
        if let tuniPeripheral = tuniPeripheral  {
            tuniPeripheral.delegate = self
        }
    }

    private var bluetoothManager: CBCentralManager?

    var tuniPeripheral: CBPeripheral? {
        didSet {
            setupPeripheral()
        }
    }
    
    private var currentCharacteristic: CBCharacteristic?
    private var desiredCharacteristic: CBCharacteristic?
    private var onOffCharacteristic: CBCharacteristic?
    private var sharpsCharacteristic: CBCharacteristic?
    private var disabledCharacteristic: CBCharacteristic?

    // MARK: State Tracking
    private var skipNextDeviceUpdate = false
    private var pendingBluetoothUpdate = false

    init(name: String) {
        self.name = name
        super.init()

        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }

    init(tuniPeripheral: CBPeripheral) {
        print("initting tuni object")
        guard let peripheralName = tuniPeripheral.name else {
            fatalError("Tuni must initialized with a peripheral with a name")
        }

        self.tuniPeripheral = tuniPeripheral
        self.name = peripheralName
        
        super.init()

        self.setupPeripheral() // properties set in init() do not trigger didSet
    }
}

extension Tuni {
    static let SERVICE_UUID = CBUUID(string: "0001A7D3-6486-4761-87D7-B937D41781A2")
    static let CURRENT_UUID = CBUUID(string: "0002A7D3-6486-4761-87D7-B937D41781A2")
    static let DESIRED_UUID = CBUUID(string: "0003A7D3-6486-4761-87D7-B937D41781A2")
    static let ON_OFF_UUID = CBUUID(string: "0004A7D3-6486-4761-87D7-B937D41781A2")
    static let SHARPS_UUID = CBUUID(string: "0005A7D3-6486-4761-87D7-B937D41781A2")
    static let DISABLED_UUID = CBUUID(string: "0006A7D3-6486-4761-87D7-B937D41781A2")
    
    private var shouldSkipUpdateDevice: Bool {
        return skipNextDeviceUpdate || pendingBluetoothUpdate
    }
    
    private func updateDevice(force: Bool = false) {
        if state.isConnected && (force || !shouldSkipUpdateDevice) {
            pendingBluetoothUpdate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.writeOnOff()
                self?.writeDesired()
                self?.writeCurrent()
                self?.writeSharps()
                
                self?.pendingBluetoothUpdate = false
            }
        }
        
        skipNextDeviceUpdate = false
    }
    
    private func writeOnOff() {
        if let onOffCharacteristic = onOffCharacteristic {
            let data = Data(bytes: &state.isOn, count: 1)
            tuniPeripheral?.writeValue(data, for: onOffCharacteristic, type: .withResponse)
        }
    }
    
    private func writeDisabled(isDisabled: Bool) {
        var d = isDisabled
        if let disabledCharacteristic = disabledCharacteristic {
            let data = Data(bytes: &d, count: 1)
            tuniPeripheral?.writeValue(data, for: disabledCharacteristic, type: .withResponse)
        }
    }
    
    private func writeDesired() {
        if let desiredCharacteristic = desiredCharacteristic {
            var desiredChar = UInt8(state.desiredTick / 11 * 255) // times?
            let data = Data(bytes: &desiredChar, count: 1)
            tuniPeripheral?.writeValue(data, for: desiredCharacteristic, type: .withResponse)
        }
    }
    
    private func writeCurrent() {
        if let currentCharacteristic = currentCharacteristic {
            if (state.frequency < state.lastFrequency - 0.1 || state.frequency > state.lastFrequency + 0.1) {
                state.lastFrequency = state.frequency
                var val: Float = state.frequency
                if (state.frequency <= state.desiredTone / state.NOTE_RATIO) {
                    val = state.desiredTone/state.NOTE_RATIO
                } else if (state.frequency >= state.desiredTone * state.NOTE_RATIO) {
                    val = state.desiredTone * state.NOTE_RATIO
                }
                var convert = (val - (state.desiredTone/state.NOTE_RATIO))/(state.desiredTone*state.NOTE_RATIO - state.desiredTone/state.NOTE_RATIO)
                
                var currentChar = UInt8(convert*255)// backwards?
                let data = Data(bytes: &currentChar, count: 1)
                tuniPeripheral?.writeValue(data, for: currentCharacteristic, type: .withResponse)
                if (state.frequency == -1) {
                    writeDisabled(isDisabled: true)
                } else {
                    writeDisabled(isDisabled: false)
                }
            }
        }
    }
    
    private func writeSharps() {
        if let sharpsCharacteristic = sharpsCharacteristic {
            let data = Data(bytes: &state.namesInSharps, count: 1)
            tuniPeripheral?.writeValue(data, for: sharpsCharacteristic, type: .withResponse)
        }
    }
    
}


extension Tuni {
    struct State: Equatable {
        var isConnected = false
        var isOn = false
        var pitch: Float = 0.0
        var frequency: Float = 0.0
        var lastFrequency: Float = 0.0
        var amplitude: Float = 0.0
        var currNoteNameWithSharps = "-"
        var currNoteNameWithFlats = "-"
        
        let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
        
        var currNoteNames: [String] = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        
        let noteFrequencies: [Float] = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
        
        var namesInSharps: Bool = true {
            didSet {
                currNoteNames = namesInSharps ? noteNamesWithSharps : noteNamesWithFlats
            }
        }
        
        var desiredTone: Float = 16.35
        
        var desiredTick: Float = 0.0 {
            didSet {
                desiredTone = Float(noteFrequencies[Int(floor(desiredTick))]) * pow(1.05,desiredTick - floor(desiredTick))
            }
        }
        
        let NOTE_RATIO: Float = 1.059463
    }
}

extension Tuni: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            bluetoothManager?.scanForPeripherals(withServices: [Tuni.SERVICE_UUID])
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == name {
            print("Found \(name)")

            tuniPeripheral = peripheral

            bluetoothManager?.stopScan()
            bluetoothManager?.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral \(peripheral)")
        peripheral.delegate = self
        peripheral.discoverServices([Tuni.SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral \(peripheral)")
        state.isConnected = false
        bluetoothManager?.connect(peripheral)
    }
}

extension Tuni: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            print("Found: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case Tuni.CURRENT_UUID:
                self.currentCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

            case Tuni.DESIRED_UUID:
                self.desiredCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

            case Tuni.ON_OFF_UUID:
                self.onOffCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
                
            case Tuni.SHARPS_UUID:
                self.sharpsCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
                
            case Tuni.DISABLED_UUID:
                self.disabledCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

            default:
                continue
            }
        }

        // not connected until all characteristics are discovered
        if self.currentCharacteristic != nil && self.desiredCharacteristic != nil && self.onOffCharacteristic != nil && self.sharpsCharacteristic != nil && self.disabledCharacteristic != nil {
            print("All characteristics discovered")
            skipNextDeviceUpdate = true
            state.isConnected = true
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        skipNextDeviceUpdate = true

        guard let updatedValue = characteristic.value,
              !updatedValue.isEmpty else { return }

        switch characteristic.uuid {
        case Tuni.CURRENT_UUID:
            break
            
        case Tuni.DISABLED_UUID:
            break
            
        case Tuni.DESIRED_UUID:
            state.desiredTick = parseDesired(for: updatedValue)

        case Tuni.ON_OFF_UUID:
            state.isOn = parseBool(for: updatedValue)
            
        case Tuni.SHARPS_UUID:
            state.namesInSharps = parseBool(for: updatedValue)
        
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }

    private func parseBool(for value: Data) -> Bool {
        return value.first == 1
    }

    private func parseDesired(for value: Data) -> Float {
        print(value[0])
        return Float(value[0]) * 11.0 / 255.0 // divide?
    }
}


class TunerConductor: NSObject, ObservableObject, HasAudioEngine {
    @Published var data = Tuni(name:"LAMPI-b827eba30b35")
    
    let engine = AudioEngine()
    let initialDevice: Device
    
    let mic: AudioEngine.InputNode
    let tappableNodeA: Fader
    let tappableNodeB: Fader
    let tappableNodeC: Fader
    let silence: Fader
    var tracker: PitchTap!
    
    let noteFrequencies: [Float] = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    
    let lowC: Float = 16.35
    let lowB: Float = 15.435
    let highC: Float = 32.7
    let highB: Float = 30.87
    
    override init() {
        print("Instantiating TunerConductor Object")
        guard let input = engine.input else { fatalError() }

        guard let device = engine.inputDevice else { fatalError() }

        initialDevice = device

        mic = input
        tappableNodeA = Fader(mic)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        silence = Fader(tappableNodeC, gain: 0)
        engine.output = silence
        
        super.init()
        
        data.state.desiredTone = Float(noteFrequencies[Int(floor(data.state.desiredTick))]) * pow(1.05,data.state.desiredTick - floor(data.state.desiredTick))
        data.state.namesInSharps = true
        
        data.state.currNoteNames = data.state.noteNamesWithSharps

        tracker = PitchTap(mic) { pitch, amp in
            DispatchQueue.main.async {
                if (self.data.state.isOn) {
                    self.update(pitch[0], amp[0])
                }
               
            }
        }
        tracker.start()
    }
    
    func update(_ pitch: AUValue, _ amp: AUValue) {
        // Reduces sensitivity to background noise to prevent random / fluctuating data.
        guard amp > 0.2 else {
            if (data.state.frequency != -1) {
                data.state.frequency = -1
            }
            data.state.currNoteNameWithSharps = "-"
            data.state.currNoteNameWithFlats = "-"
            return
        }
        data.state.pitch = pitch
        data.state.amplitude = amp
        
        var frequency = pitch
        while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
            frequency /= 2.0
        }
        while frequency < Float(noteFrequencies[0]) {
            frequency *= 2.0
        }
        data.state.frequency = frequency
        
        if (data.state.desiredTone < 17.32 && data.state.frequency > 29.14) {
            data.state.frequency /= 2.0
        } else if (data.state.desiredTone > 29.14 && data.state.frequency < 17.32) {
            data.state.frequency *= 2.0
        }
        
        var minDistance: Float = 10000.0
        var index = 0
        
        for possibleIndex in 0 ..< noteFrequencies.count {
            let distance = fabsf(Float(noteFrequencies[possibleIndex]) - frequency)
            if distance < minDistance {
                index = possibleIndex
                minDistance = distance
            }
        }
        let octave = Int(log2f(pitch / frequency))
        data.state.currNoteNameWithSharps = "\(data.state.noteNamesWithSharps[index])\(octave)"
        data.state.currNoteNameWithFlats = "\(data.state.noteNamesWithFlats[index])\(octave)"
        //        print("NOTE WITH FLATS: ", data.state.currNoteNameWithFlats)
    }
}

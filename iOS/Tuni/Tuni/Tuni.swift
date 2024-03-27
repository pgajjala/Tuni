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

struct TunerData {
    var pitch: Float = 0.0
    var frequency: Float = 0.0
    var amplitude: Float = 0.0
    var noteNameWithSharps = "-"
    var noteNameWithFlats = "-"
}


class TunerConductor: NSObject, ObservableObject, HasAudioEngine {
    @Published var data = TunerData()
    
    var desiredTone: Int = 1
    
    let engine = AudioEngine()
    let initialDevice: Device
    
    let mic: AudioEngine.InputNode
    let tappableNodeA: Fader
    let tappableNodeB: Fader
    let tappableNodeC: Fader
    let silence: Fader
    var tracker: PitchTap!
    
    let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
    
    let lowB: Float = 15.435
    let highC: Float = 32.7
    
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

        tracker = PitchTap(mic) { pitch, amp in
            DispatchQueue.main.async {
                self.update(pitch[0], amp[0])
            }
        }
        tracker.start()
    }
    
    func update(_ pitch: AUValue, _ amp: AUValue) {
        // Reduces sensitivity to background noise to prevent random / fluctuating data.
        guard amp > 0.1 else {
            return
        }

        data.pitch = pitch
        data.amplitude = amp

        var frequency = pitch
        while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
            frequency /= 2.0
        }
        while frequency < Float(noteFrequencies[0]) {
            frequency *= 2.0
        }
        data.frequency = convertOutOfBounds(val: frequency)
        
        print("FREQUENCY: ", data.frequency)
        print("PITCH: ", data.pitch)

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
        data.noteNameWithSharps = "\(noteNamesWithSharps[index])\(octave)"
        data.noteNameWithFlats = "\(noteNamesWithFlats[index])\(octave)"
        print("NOTE WITH FLATS: ", data.noteNameWithFlats)
    }
    
    func convertOutOfBounds(val: Float) -> Float {
        var toRet: Float = val
        if val > highB {
            toRet = lowB + (val - highB)/(highC - highB) * (lowC - lowB)
        }
        else if (val < lowC) {
            toRet = highB + (lowC - val)/(lowC - lowB) * (highC - highB)
        }
        return toRet
    }
}

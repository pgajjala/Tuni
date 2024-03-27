//
//  ContentView.swift
//  Tuni
//
//  Created by Prarthana Gajjala on 3/26/24.
//

import SwiftUI

let lowB: Float = 15.435
let highB: Float = 30.87
let lowC: Float = 16.35
let highC: Float = 32.7

struct TuniView: View {
    @StateObject var tuni = TunerConductor()
    
    var body: some View {
        VStack {
            Text(tuni.data.noteNameWithSharps)
            Slider(value: $tuni.data.frequency,
                   in: convertOutOfBounds(val: Float(tuni.noteFrequencies[tuni.desiredTone - 1]))...convertOutOfBounds(val: Float(tuni.noteFrequencies[tuni.desiredTone + 1])))
        }
        .onAppear {
            tuni.start()
        }
        .onDisappear {
            tuni.stop()
        }
        .padding()
    }
}

//func convertToInterval(low: Float, high:Float) -> (Float, Float) {
//    var newLow: Float = low
//    var newHigh: Float = high
//    if low > highB {
//        newLow = lowB
//    }
//    if high < lowC {
//        newHigh = highC
//    }
//    return (newLow, newHigh)
//}

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

#Preview {
    TuniView()
}

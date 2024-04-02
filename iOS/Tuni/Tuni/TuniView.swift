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

let NOTE_RATIO: Float = 1.059463

struct TuniView: View {
    @StateObject var tuni = TunerConductor()
    
    var body: some View {
        VStack {
            Text(tuni.data.noteNameWithSharps)
            
            Slider(value: $tuni.desiredTick,
                   in: 0 ... 11,
                   step: 0.25)
            .frame(width:360)
            .overlay(
                
                HStack{
                    ForEach(1..<12) { i in
                        Rectangle().frame(width: 2, height: 30)
                        Spacer().frame(width:28)
                    }
                    Rectangle().frame(width: 2, height: 30)
                }.frame(width: 360)
            
            )
            
            HStack{
                ForEach(0..<11) { i in
                    Text(tuni.noteNamesWithSharps[i])
                        .frame(width: 22)
                }
                Text(tuni.noteNamesWithSharps[11])
                    .frame(width: 25)
            }.frame(width: 360)
            
           
            
            
            Spacer()
                .frame(height: 50)
            if(tuni.data.frequency != -1) {
                Slider(value: $tuni.data.frequency,
                       in: tuni.desiredTone / NOTE_RATIO ... tuni.desiredTone * NOTE_RATIO)
            } else {
                Slider(value: $tuni.desiredTone,
                       in: tuni.desiredTone / NOTE_RATIO ... tuni.desiredTone * NOTE_RATIO)
            }
            
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

func convertOutOfBounds(val: Float) -> Float {
    print("convert out of bounds", val)
    var toRet: Float = val
    if val > highB {
        toRet = lowB + (val - highB)/(highC - highB) * (lowC - lowB)
    }
    else if (val < lowC) {
        toRet = highB + (lowC - val)/(lowC - lowB) * (highC - highB)
    }
    print("converted to", toRet)
    return toRet
}

#Preview {
    TuniView()
}

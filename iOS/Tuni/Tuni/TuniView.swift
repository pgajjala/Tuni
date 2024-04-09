//
//  ContentView.swift
//  Tuni
//
//  Created by Prarthana Gajjala on 3/26/24.
//  Checkbox code modified from https://sarunw.com/posts/swiftui-checkbox/
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
            
            Toggle(isOn: $tuni.namesInSharps) {
                Text("Express Note Names in Sharps")
            }.toggleStyle(iOSCheckboxToggleStyle())
            
            Spacer()
                    .frame(height: 50)
            
//            Text(tuni.data.noteNameWithSharps) // either "-" or current note
            
            ZStack {
                HStack{
                    ForEach(1..<12) { i in
                        Rectangle()
                            .frame(width: 2, height: 40)
                            .foregroundColor(.blue)
                        Spacer().frame(width:28)
                    }
                    Rectangle()
                        .frame(width: 2, height: 40)
                        .foregroundColor(.blue)
                }.frame(width: 360)
                
                Slider(value: $tuni.desiredTick,
                       in: 0 ... 11,
                       step: 0.25)
                .frame(width:360)
            }
            
            HStack{
                ForEach(0..<11) { i in
                    Text(tuni.currNoteNames[i])
                        .frame(width: 22)
                }
                Text(tuni.currNoteNames[11])
                    .frame(width: 25)
            }.frame(width: 360)
            
            // when no sound is picked up, thumb will default to the center of the slider
            let sliderVal = tuni.data.frequency != -1 ? $tuni.data.frequency : $tuni.desiredTone
            
            ZStack {
                VStack {
                    Rectangle()
                        .frame(width: 2, height: 40)
                        .foregroundColor(.blue)
                    Text(getDesiredToneString(tone:tuni.desiredTone, frequencies:tuni.noteFrequencies, noteNames:tuni.currNoteNames))
                }
                .offset(x: -5.5, y: 13) // exact positioning of ticker & text
                
                // the note value slider is not slidable
                LinearGradient(
                    gradient: Gradient(colors: [.red, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(Slider(value: sliderVal, in: tuni.desiredTone / NOTE_RATIO ... tuni.desiredTone * NOTE_RATIO))
                
            }.frame(height: 100)
        
            
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

struct iOSCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        // 1
        Button(action: {

            // 2
            configuration.isOn.toggle()

        }, label: {
            HStack {
                // 3
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")

                configuration.label
            }
        })
    }
}

func getDesiredToneString(tone: Float, frequencies: [Float], noteNames: [String]) -> String {
    for possibleIndex in 0 ..< frequencies.count {
        if tone == frequencies[possibleIndex] {
            return noteNames[possibleIndex]
        }
    }
    return String(format: "%.2f", tone)
}


//func convertOutOfBounds(val: Float) -> Float {
//    print("convert out of bounds", val)
//    var toRet: Float = val
//    if val > highB {
//        toRet = lowB + (val - highB)/(highC - highB) * (lowC - lowB)
//    }
//    else if (val < lowC) {
//        toRet = highB + (lowC - val)/(lowC - lowB) * (highC - highB)
//    }
//    print("converted to", toRet)
//    return toRet
//}

#Preview {
    TuniView()
}

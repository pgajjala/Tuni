//
//  ContentView.swift
//  Tuni
//
//  Created by Prarthana Gajjala on 3/26/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var tuni = TunerConductor()
    
    var body: some View {
        VStack {
            Text(tuni.data.noteNameWithSharps)
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

#Preview {
    ContentView()
}

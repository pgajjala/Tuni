//
//  TuniApp.swift
//  Tuni
//
//  Created by Prarthana Gajjala on 3/26/24.
//

import SwiftUI

@main
struct TuniApp: App {
    let DEVICE_NAME = "LAMPI-b827eba30b35"
    var body: some Scene {
        WindowGroup {
            TuniView(tuni: Tuni(name: DEVICE_NAME))
        }
    }
}

//
//  app_attest_iosApp.swift
//  app-attest-ios
//
//  Created by Craig Pearson on 7/11/2025.
//

import SwiftUI
import TipKit

@main
struct AppAttestApp: App {
    var storage = Storage()
    
    init() {
        //try? Tips.resetDatastore()
        try? Tips.configure([.displayFrequency(.immediate)])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storage)
        }
    }
}

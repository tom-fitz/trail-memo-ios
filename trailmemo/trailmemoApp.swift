//
//  trailmemoApp.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import SwiftUI
import FirebaseCore

@main
struct TrailMemoApp: App {
    // Initialize Firebase when app starts
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

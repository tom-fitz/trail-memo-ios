//
//  ContentView.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // User is logged in - show main app
                MainTabView(authViewModel: authViewModel)
                    .onAppear {
                        print("DEBUG: Showing MainTabView - User is authenticated")
                        print("DEBUG: User email: \(authViewModel.user?.email ?? "none")")
                    }
            } else {
                // User is not logged in - show login
                LoginView()
                    .onAppear {
                        print("DEBUG: Showing LoginView - User NOT authenticated")
                    }
            }
        }
        .onAppear {
            print("DEBUG: ContentView appeared")
            print("DEBUG: isAuthenticated = \(authViewModel.isAuthenticated)")
            print("DEBUG: user = \(String(describing: authViewModel.user))")
        }
    }
}

#Preview {
    ContentView()
}

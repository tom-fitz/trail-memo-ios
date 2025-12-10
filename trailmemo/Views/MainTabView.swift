//
//  MainTabView.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        
        // Force tab bar to show
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
    
    var body: some View {
        TabView {
            // Map view
            MapView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(0)
            
            // Profile view
            ProfileView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(1)
        }
        .accentColor(.blue)
    }
}

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    if let user = authViewModel.user {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(user.displayName ?? "No name")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email ?? "No email")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel())
}

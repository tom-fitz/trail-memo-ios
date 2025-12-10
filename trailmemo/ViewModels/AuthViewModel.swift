//
//  AuthViewModel.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
internal import Combine

@MainActor
class AuthViewModel: ObservableObject {
    // Published properties update the UI automatically
    @Published var user: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Check if user is logged in
    var isAuthenticated: Bool {
        user != nil
    }
    
    init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create user in Firebase
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // Register user with your API
            try await registerUserWithAPI(userId: result.user.uid, email: email, displayName: displayName)
            
            self.user = result.user
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("Sign up error: \(error)")
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("Sign in error: \(error)")
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("Sign out error: \(error)")
        }
    }
    
    // MARK: - Register with API
    private func registerUserWithAPI(userId: String, email: String, displayName: String) async throws {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/v1/auth/register") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get Firebase token
        guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create request body
        let body: [String: Any] = [
            "display_name": displayName,
            "department": "Parks & Recreation"  // You can make this editable later
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Validation
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}

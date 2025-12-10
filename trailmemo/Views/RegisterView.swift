//
//  RegisterView.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showingError = false
    @State private var validationError = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Information")) {
                    TextField("Full Name", text: $displayName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .autocorrectionDisabled()
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Text("Password must be at least 6 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let errorMessage = authViewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: handleSignUp) {
                        if authViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationError)
            }
        }
    }
    
    private var isFormValid: Bool {
        !displayName.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }
    
    private func handleSignUp() {
        // Validate inputs
        guard authViewModel.validateEmail(email) else {
            validationError = "Please enter a valid email address"
            showingError = true
            return
        }
        
        guard authViewModel.validatePassword(password) else {
            validationError = "Password must be at least 6 characters"
            showingError = true
            return
        }
        
        guard password == confirmPassword else {
            validationError = "Passwords do not match"
            showingError = true
            return
        }
        
        // Sign up
        Task {
            await authViewModel.signUp(email: email, password: password, displayName: displayName)
            
            // If successful, dismiss the sheet
            if authViewModel.user != nil {
                dismiss()
            }
        }
    }
}

#Preview {
    RegisterView(authViewModel: AuthViewModel())
}

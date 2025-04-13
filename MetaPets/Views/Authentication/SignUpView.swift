import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo
                        Image("PetopiaLaunch")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .padding(.top)
                        
                        // Title
                        VStack(spacing: 10) {
                            Text("Create Account")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Join Meta Pets today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Sign up form
                        VStack(spacing: 20) {
                            TextField("Username", text: $username)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disabled(isLoading)
                            
                            // Add helper text about username login
                            Text("You'll use your username to login")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 5)
                                .padding(.top, -10)
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(isLoading)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.newPassword)
                                .disabled(isLoading)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.newPassword)
                                .disabled(isLoading)
                            
                            Button(action: signUp) {
                                ZStack {
                                    Text("Sign Up")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(10)
                                    
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                }
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, 30)
                        
                        // Terms and conditions
                        Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func signUp() {
        // Validate input
        guard !username.isEmpty else {
            alertMessage = "Please enter a username"
            showingAlert = true
            return
        }
        
        guard !email.isEmpty else {
            alertMessage = "Please enter an email"
            showingAlert = true
            return
        }
        
        guard !password.isEmpty else {
            alertMessage = "Please enter a password"
            showingAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return
        }
        
        guard password.count >= 8 else {
            alertMessage = "Password must be at least 8 characters"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if try await authManager.signUp(email: email, password: password, username: username) {
                    isLoading = false
                    dismiss()
                }
            } catch AuthError.invalidInput {
                isLoading = false
                alertMessage = "Invalid input. Please check your details."
                showingAlert = true
            } catch {
                isLoading = false
                alertMessage = "Failed to create account. Please try again."
                showingAlert = true
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
} 
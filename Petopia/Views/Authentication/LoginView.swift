import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
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
                
                VStack(spacing: 30) {
                    // Logo and title
                    VStack(spacing: 20) {
                        Image("PetopiaLaunch")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                        
                        Text("Welcome to Petopia")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Login to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Login form
                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(isLoading)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(.password)
                            .disabled(isLoading)
                        
                        Button(action: login) {
                            ZStack {
                                Text("Login")
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
                    
                    // Sign up button
                    Button(action: { showingSignUp = true }) {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if try await authManager.login(email: email, password: password) {
                    isLoading = false
                } else {
                    throw AuthError.invalidCredentials
                }
            } catch {
                isLoading = false
                alertMessage = "Invalid email or password"
                showingAlert = true
            }
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 
import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var username = ""
    @State private var password = ""
    @State private var rememberMe = false
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
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .autocapitalization(.none)
                            .disabled(isLoading)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(.password)
                            .disabled(isLoading)
                        
                        // Add Remember Me checkbox
                        Toggle(isOn: $rememberMe) {
                            Text("Remember Me")
                                .foregroundColor(.secondary)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .padding(.horizontal, 5)
                        
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
            .onAppear {
                // Load saved Remember Me preference
                rememberMe = authManager.isRememberMeEnabled()
            }
        }
    }
    
    private func login() {
        guard !username.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if try await authManager.login(username: username, password: password, rememberMe: rememberMe) {
                    isLoading = false
                } else {
                    throw AuthError.invalidCredentials
                }
            } catch {
                isLoading = false
                alertMessage = "Invalid username or password"
                showingAlert = true
            }
        }
    }
}

// Custom checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    withAnimation(.spring()) {
                        configuration.isOn.toggle()
                    }
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
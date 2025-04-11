import Foundation

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    
    private init() {
        loadUser()
    }
    
    func signUp(email: String, password: String, username: String) async throws -> Bool {
        guard isValidEmail(email),
              isValidPassword(password),
              !username.isEmpty else {
            throw AuthError.invalidInput
        }
        
        let user = User(
            id: UUID(),
            username: username,
            email: email,
            joinDate: Date()
        )
        
        // Save user
        currentUser = user
        isAuthenticated = true
        saveUser(user)
        
        // Important: Don't set onboarding as complete yet - this will happen after onboarding
        if AppDataManager.shared.hasCompletedOnboarding() {
            AppDataManager.shared.setOnboardingComplete(false)
        }
        
        return true
    }
    
    func login(email: String, password: String) async throws -> Bool {
        guard let savedUser = loadUser(),
              savedUser.email == email else {
            throw AuthError.invalidCredentials
        }
        
        currentUser = savedUser
        isAuthenticated = true
        
        // For a better user experience, ensure existing users don't need to redo onboarding
        // New users or existing users with incomplete onboarding will still go through it
        if !AppDataManager.shared.hasCompletedOnboarding() {
            // No need to reset onboarding for existing users
            // The flow will still check onboarding status after authentication
        }
        
        return true
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: userKey)
        
        // Note: We don't reset onboarding status on logout
        // This allows returning users to skip onboarding after re-authentication
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: userKey)
        }
    }
    
    private func loadUser() -> User? {
        if let userData = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isAuthenticated = true
            return user
        }
        return nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Password must be at least 8 characters
        return password.count >= 8
    }
}

enum AuthError: Error {
    case invalidInput
    case invalidCredentials
} 
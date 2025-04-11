import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var petViewModel = PetViewModel()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(petViewModel)
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
} 
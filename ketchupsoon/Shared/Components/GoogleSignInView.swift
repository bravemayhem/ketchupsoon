import SwiftUI

struct GoogleSignInView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Connect Google Calendar")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Sign in with your Google account to sync and manage your calendar events")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else {
                GoogleSignInButton {
                    signInWithGoogle()
                }
                .frame(height: 50)
                .padding(.horizontal)
                
                Text("This will allow Ketchup Soon to create and manage events in your Google Calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.bottom)
        }
        .padding()
    }
    
    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get the root view controller to present the Google Sign-In UI
                guard let rootViewController = UIApplication.shared.rootController else {
                    throw NSError(
                        domain: "GoogleSignInView",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Cannot find root view controller"]
                    )
                }
                
                // Sign in with Google
                try await authManager.signInWithGoogle(from: rootViewController)
                
                // Success - dismiss this view
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Sign-in failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// Helper extension moved to UIExtensions.swift in Shared/Utils

#Preview {
    GoogleSignInView()
} 

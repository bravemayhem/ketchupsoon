import SwiftUI
import FirebaseAuth
import UIKit

struct AuthMethodSelectionView: View {
    @StateObject private var socialAuthManager = SocialAuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showEmailAuth = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var onCompletion: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // Header
                Image(systemName: "person.2.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(AppColors.accent)
                    .padding(.top)
                
                Text("Sign In for Social Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose a sign-in method to activate your social profile")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Auth options
                VStack(spacing: 15) {
                    // Google Sign In
                    AuthButtonView(
                        icon: "g.circle.fill",
                        text: "Continue with Google",
                        backgroundColor: .white,
                        textColor: .black,
                        borderColor: Color.gray.opacity(0.3)
                    ) {
                        signInWithGoogle()
                    }
                    
                    // Email/Password Sign In
                    AuthButtonView(
                        icon: "envelope.fill",
                        text: "Continue with Email",
                        backgroundColor: AppColors.accent,
                        textColor: .white
                    ) {
                        showEmailAuth = true
                    }
                }
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
                
                Text("Your information is only shared with friends you explicitly connect with.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .alert("Authentication Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showEmailAuth) {
                EmailAuthView(onSuccess: {
                    onCompletion()
                    showEmailAuth = false
                }, onCancel: {
                    showEmailAuth = false
                })
            }
            .disabled(isLoading)
        }
    }
    
    private func signInWithGoogle() {
        isLoading = true
        
        Task {
            do {
                // Get the root view controller to present the Google Sign-In UI
                guard let rootViewController = UIApplication.shared.rootController else {
                    throw NSError(
                        domain: "AuthMethodSelectionView",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Cannot find root view controller"]
                    )
                }
                
                // Sign in with Google for social profile
                try await socialAuthManager.signInWithGoogle(from: rootViewController)
                
                // Success - call completion handler
                await MainActor.run {
                    isLoading = false
                    onCompletion()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Sign-in failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// Helper view for auth buttons
struct AuthButtonView: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    let textColor: Color
    var borderColor: Color?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                
                Text(text)
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor ?? Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    AuthMethodSelectionView(
        onCompletion: {},
        onCancel: {}
    )
} 
import SwiftUI
import FirebaseAuth

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialAuthManager = SocialAuthManager.shared
    
    @State private var isSignIn = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var onSuccess: () -> Void
    var onCancel: () -> Void
    
    private var isFormValid: Bool {
        let emailIsValid = !email.isEmpty && email.contains("@")
        let passwordIsValid = password.count >= 6
        
        if isSignIn {
            return emailIsValid && passwordIsValid
        } else {
            return emailIsValid && passwordIsValid && password == confirmPassword && !name.isEmpty
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("", selection: $isSignIn) {
                        Text("Sign In").tag(true)
                        Text("Create Account").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                } header: {
                    HStack {
                        Spacer()
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accent)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    if !isSignIn {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                    }
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textContentType(isSignIn ? .password : .newPassword)
                    
                    if !isSignIn {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                }
                
                Section {
                    Button(action: performAuth) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text(isSignIn ? "Sign In" : "Create Account")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
                
                if isSignIn {
                    Section {
                        Button("Forgot Password?") {
                            // TODO: Implement password reset
                        }
                        .foregroundColor(AppColors.accent)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(isSignIn ? "Sign In" : "Create Account")
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
            .onChange(of: isSignIn) { oldValue, newValue in
                // Clear fields when switching between sign in and create account
                if oldValue != newValue {
                    password = ""
                    confirmPassword = ""
                    errorMessage = ""
                }
            }
        }
    }
    
    private func performAuth() {
        isLoading = true
        
        Task {
            do {
                if isSignIn {
                    try await socialAuthManager.signIn(withEmail: email, password: password)
                } else {
                    if password != confirmPassword {
                        throw NSError(
                            domain: "EmailAuth",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Passwords do not match"]
                        )
                    }
                    
                    try await socialAuthManager.createUser(
                        withEmail: email,
                        password: password,
                        name: name
                    )
                }
                
                await MainActor.run {
                    isLoading = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    EmailAuthView(
        onSuccess: {},
        onCancel: {}
    )
} 
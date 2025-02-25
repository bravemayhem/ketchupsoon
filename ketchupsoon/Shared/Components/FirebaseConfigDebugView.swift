import SwiftUI
import GoogleSignIn

struct FirebaseConfigDebugView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var configValues: [String: String] = [:]
    @State private var showFullDetails = false
    
    var body: some View {
        List {
            Section("Firebase Configuration") {
                ForEach(configValues.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.headline)
                        Spacer()
                        Text(showFullDetails ? configValues[key] ?? "" : maskedValue(configValues[key] ?? ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle("Show Full Details", isOn: $showFullDetails)
            }
            
            Section {
                Button(action: {
                    configValues = authManager.verifyFirebaseConfiguration()
                }) {
                    Text("Refresh Configuration")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Section("Google Sign-In") {
                if let user = authManager.googleUser {
                    VStack(alignment: .leading) {
                        Text("Signed in as:")
                            .font(.headline)
                        Text(user.profile?.email ?? "Unknown email")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                    
                    Button(action: {
                        Task {
                            try? await authManager.signOut()
                        }
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Text("Not signed in with Google")
                        .foregroundColor(.secondary)
                    
                    GoogleSignInButtonWrapper()
                        .frame(height: 50)
                }
            }
        }
        .onAppear {
            configValues = authManager.verifyFirebaseConfiguration()
        }
    }
    
    private func maskedValue(_ value: String) -> String {
        guard !value.isEmpty else { return "Not found" }
        
        if value.count <= 8 {
            return String(repeating: "•", count: value.count)
        } else {
            let prefix = String(value.prefix(4))
            let suffix = String(value.suffix(4))
            return "\(prefix)••••\(suffix)"
        }
    }
}

struct GoogleSignInButtonWrapper: UIViewRepresentable {
    typealias UIViewType = GIDSignInButton
    
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.style = .wide
        button.colorScheme = .light
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {}
}

#Preview {
    FirebaseConfigDebugView()
} 

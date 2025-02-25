import SwiftUI
import UIKit
import GoogleSignIn

struct GoogleSignInButton: UIViewRepresentable {
    var action: () -> Void
    
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.style = .wide
        button.colorScheme = .light
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonPressed), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonPressed() {
            action()
        }
    }
}

struct CustomGoogleSignInButton: View {
    var action: () -> Void
    var label: String = "Sign in with Google"
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image("google_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    .background(Color.white)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        GoogleSignInButton(action: {})
            .frame(height: 50)
            .padding()
        
        CustomGoogleSignInButton(action: {})
            .padding()
    }
} 
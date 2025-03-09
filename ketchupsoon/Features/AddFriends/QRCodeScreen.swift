import SwiftUI

// MARK: - QR Code Content Component
/// This component contains just the QR code content without the full screen navigation elements.
/// It can be reused in other views like AddFriendViewOne for dynamic tab content.
public struct QRCodeContent: View {
    public init() {}
    public var body: some View {
        VStack(spacing: 20) {
            // QR Code card
            qrCodeCard
            
            // Scan QR section
            scanQRSection
            
            // Extra space at bottom
            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - QR Code Card
    private var qrCodeCard: some View {
        VStack(spacing: 20) {
            Text("your personal qr code")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            // QR Code with Logo
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 240, height: 240)
                    .cornerRadius(12)
                    .shadow(color: Color.white.opacity(0.5), radius: 3, x: 0, y: 0)
                
                // Simplified QR pattern
                GeneratedQRCode()
                
            }
            
            Text("have a friend scan to connect")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.7))
                .padding(.top, 10)
            
            // Share button
            Button(action: {}) {
                Text("share my qr code")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 40)
                    .background(AppColors.accentGradient3)
                    .cornerRadius(20)
                    .shadow(color: AppColors.accent.opacity(0.5), radius: 6, x: 0, y: 0)
            }
            .padding(.bottom, 10)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Scan QR Section
    private var scanQRSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("scan a friend's qr code")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 5)
            
            Button(action: {}) {
                VStack(spacing: 10) {
                    // Camera icon
                    Circle()
                        .fill(AppColors.purple.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("📷")
                                .font(.system(size: 26))
                        )
                    
                    Text("tap to open camera")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(AppColors.cardBackground)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColors.gradient2Start.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
            }
        }
        .padding(.top, 10)
    }
}

struct QRCodeScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background with decorative elements
            backgroundLayer
            
            // Main content
            VStack(spacing: 0) {
                // Custom header with back button
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Method selection tabs
                        methodTabs
                        
                        // Use the shared QR code content component
                        QRCodeContent()
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Bottom navigation
            VStack {
                Spacer()
                bottomNavBar
            }
        }
        .background(
            AppColors.backgroundGradient
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Large blurred circles
            Circle()
                .fill(AppColors.purple.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 50)
                .offset(x: 150, y: -50)
            
            Circle()
                .fill(AppColors.accent.opacity(0.2))
                .frame(width: 360, height: 360)
                .blur(radius: 50)
                .offset(x: -150, y: 300)
            
            // Small decorative elements
            Circle()
                .fill(AppColors.mint.opacity(0.8))
                .frame(width: 16, height: 16)
                .offset(x: -140, y: 180)
            
            Circle()
                .fill(AppColors.accentSecondary.opacity(0.8))
                .frame(width: 10, height: 10)
                .offset(x: 150, y: 400)
            
            Rectangle()
                .fill(AppColors.purple.opacity(0.8))
                .frame(width: 15, height: 15)
                .cornerRadius(3)
                .rotationEffect(.degrees(30))
                .offset(x: 120, y: 220)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack(alignment: .trailing) {
            HStack {
                // Screen title
                Text("add")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(-0.5)
                
                Text("friends")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColors.accent)
                    .kerning(-0.5)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            // Back button
            Button(action: {
                dismiss()
            }) {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .overlay(
                        Text("←")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    )
            }
            .padding(.trailing, 20)
        }
        .frame(height: 60)
        .background(Color(AppColors.backgroundPrimary).opacity(0.7))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.05)),
            alignment: .bottom
        )
    }
    
    // MARK: - Method Selection Tabs
    private var methodTabs: some View {
        HStack(spacing: 10) {
            // Contacts tab
            Button(action: {}) {
                Text("contacts")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(AppColors.cardBackground)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            // QR Code tab (active)
            Button(action: {}) {
                Text("qr code")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(AppColors.accentGradient2)
                    .cornerRadius(20)
                    .shadow(color: AppColors.purple.opacity(0.5), radius: 6, x: 0, y: 0)
            }
            
            // Invite via text tab
            Button(action: {}) {
                Text("invite via text")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(AppColors.cardBackground)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Bottom Navigation Bar
    private var bottomNavBar: some View {
        HStack(spacing: 0) {
            // Home tab (active)
            QRTabButton(icon: "🏠", label: "home", isActive: true)
            
            // Hangouts tab
            QRTabButton(icon: "📅", label: "hangouts", isActive: false)
            
            // Create tab
            QRTabButton(icon: "✨", label: "create", isActive: false)
            
            // Profile tab
            QRTabButton(icon: "😎", label: "profile", isActive: false)
        }
        .padding(.vertical, 10)
        .background(Color(AppColors.backgroundPrimary).opacity(0.9))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.05)), 
            alignment: .top
        )
    }
}

// MARK: - Tab Button Component
struct QRTabButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Pill indicator for active tab
            if isActive {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(AppColors.accentGradient1)
                    .frame(width: 36, height: 5)
                    .offset(y: -2)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 5)
                    .offset(y: -2)
            }
            
            Text(icon)
                .font(.system(size: 24))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Generated QR Code
struct GeneratedQRCode: View {
    var body: some View {
        ZStack {
            // Base white background
            Rectangle()
                .fill(Color.black)
                .frame(width: 200, height: 200)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: 180, height: 180)
            
            // QR Code Corner Squares
            VStack(alignment: .leading, spacing: 120) {
                HStack(spacing: 120) {
                    qrCornerSquare()
                    qrCornerSquare()
                }
                
                HStack(spacing: 120) {
                    qrCornerSquare()
                    Spacer()
                }
            }
            .frame(width: 180, height: 180)
            
            // Simplified QR pattern
            VStack(spacing: 10) {
                qrPatternRow([1, 3, 7, 9])
                qrPatternRow([1, 4, 6, 8])
                qrPatternRow([2, 4, 6, 9])
                qrPatternRow([1, 3, 5, 5, 6, 9])
                qrPatternRow([1, 4, 7])
                qrPatternRow([2, 5, 7, 9])
            }
            .frame(width: 120, height: 120)
            .offset(y: 5)
        }
        .frame(width: 200, height: 200)
        .cornerRadius(12)
    }
    
    private func qrCornerSquare() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .frame(width: 40, height: 40)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
        }
    }
    
    private func qrPatternRow(_ positions: [Int]) -> some View {
        HStack(spacing: 0) {
            ForEach(1...10, id: \.self) { i in
                Rectangle()
                    .fill(positions.contains(i) ? Color.black : Color.clear)
                    .frame(width: 10, height: 10)
            }
        }
    }
}

// MARK: - Preview
struct QRCodeScreen_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScreen()
    }
} 

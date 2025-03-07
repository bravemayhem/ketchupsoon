import SwiftUI

struct PermissionCard: View {
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("SpaceGrotesk-Medium", size: 16))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.custom("SpaceGrotesk-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Status/Button
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isEnabled ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                        .frame(width: 60, height: 32)
                    
                    Text(isEnabled ? "On" : "Off")
                        .font(.custom("SpaceGrotesk-Medium", size: 12))
                        .foregroundColor(isEnabled ? .green : .white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
} 
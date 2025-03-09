import SwiftUI

// MARK: - Invite Via Text Content Component
/// This component contains just the invite via text content without full screen navigation elements.
/// It can be reused in other views like AddFriendViewOne for dynamic tab content.
public struct InviteViaTextContent: View {
    // State variables
    @State private var searchText = ""
    @State private var invitationMessage = "Hey! I want to ketchup with you!\nDownload this app so we can\nschedule time to hang out:\nketchupsoon.app/download\n- Alex"
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Search box
            searchBox()
            
            // Selected Contacts Section
            selectedContactsSection()
            
            // Invitation Message Section
            invitationMessageSection()
            
            // Message Preview Section
            messagePreviewSection()
            
            // Send Button
            sendButton()
                .padding(.top, 10)
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Component Views
    
    private func searchBox() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textPrimary.opacity(0.6))
                .padding(.leading, 15)
            
            TextField("search contacts...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
                .padding(.vertical, 15)
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(AppColors.cardBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(AppColors.separator, lineWidth: 1)
                )
        )
    }
    
    private func selectedContactsSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("selected contacts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            // Contact chips container
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Contact chip 1
                    ContactChip(initials: "AS", name: "avery singh")
                    
                    // Contact chip 2
                    ContactChip(initials: "JL", name: "jordan lee")
                    
                    // Add more chip
                    AddMoreChip()
                }
                .padding(.vertical, 27) // Center content in the container
                .padding(.horizontal, 20)
            }
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
            )
        }
    }
    
    private func invitationMessageSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("invitation message")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            // Message Editor with nested containers matching reference photo
            ZStack {
                // Outer container
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.backgroundPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
                
                // Inner content
                VStack {
                    ZStack(alignment: .topLeading) {
                        // Inner container
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.backgroundSecondary)
                        
                        // Editable Text Content
                        TextEditor(text: $invitationMessage)
                            .scrollContentBackground(.hidden) // Hide default background
                            .background(Color.clear)
                            .font(.system(size: 15.5))
                            .foregroundColor(AppColors.textPrimary.opacity(0.9))
                            .padding(10)
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
        }
    }
    
    private func messagePreviewSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("preview")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            // Message Preview Bubble
            HStack {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentGradient2.opacity(0.6))
                        .frame(width: 250, height: 40)
                    
                    Text("Hey! I want to ketchup with you!...")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textPrimary.opacity(0.9))
                        .padding(.leading, 15)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.cardBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
            )
        }
    }
    
    private func sendButton() -> some View {
        Button(action: {}) {
            Text("send invites")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule()
                        .fill(AppColors.accentGradient2)
                        .glow(color: AppColors.purple, radius: 6, opacity: 0.5)
                )
        }
    }
}

// MARK: - Supporting Components

struct ContactChip: View {
    let initials: String
    let name: String
    
    var body: some View {
        HStack(spacing: 4) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 28, height: 28)
                
                Text(initials)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Name
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 4)
            
            // Remove button
            ZStack {
                Circle()
                    .fill(AppColors.textPrimary.opacity(0.2))
                    .frame(width: 20, height: 20)
                
                Text("×")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(
            Capsule()
                .fill(AppColors.accentGradient2)
                .glow(color: AppColors.purple, radius: 6, opacity: 0.5)
        )
    }
}

struct AddMoreChip: View {
    var body: some View {
        Text("+ more")
            .font(.system(size: 12))
            .foregroundColor(AppColors.textPrimary.opacity(0.7))
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(
                Capsule()
                    .fill(AppColors.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Preview
struct InviteViaTextContent_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            InviteViaTextContent()
        }
    }
} 

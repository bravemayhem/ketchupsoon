import SwiftUI
import Contacts

/// Component for displaying contacts that are not matched with KetchupSoon users
struct NonMatchedContactsList: View {
    // MARK: - Properties
    
    @ObservedObject var contactMatchingManager: ContactMatchingManager
    var onInvite: (CNContact) -> Void
    @State private var invitedContactIds: Set<String> = []
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Section header with count
            sectionHeader
            
            if contactMatchingManager.isLoading {
                loadingView
            } else if contactMatchingManager.nonMatchedContacts.isEmpty && contactMatchingManager.hasLoadedContacts {
                emptyStateView
            } else if contactMatchingManager.hasLoadedContacts {
                contactsListView
            }
            
            // Invite multiple button
            if !contactMatchingManager.nonMatchedContacts.isEmpty && contactMatchingManager.hasLoadedContacts {
                inviteMultipleButton
            }
        }
    }
    
    // MARK: - Subviews
    
    private var sectionHeader: some View {
        HStack {
            Text("invite to ketchupsoon")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text("\(contactMatchingManager.nonMatchedContacts.count)")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppColors.cardBackground)
                )
        }
        .padding(.horizontal, 20)
    }
    
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                .scaleEffect(1.2)
            Spacer()
        }
        .padding(.vertical, 30)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
            
            Text("All your contacts are already on KetchupSoon!")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var contactsListView: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Limit to a reasonable number for the UI
                contactItems
                
                // If there are more contacts than we're showing
                if contactMatchingManager.nonMatchedContacts.count > 20 {
                    moreContactsIndicator
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxHeight: 350)
    }
    
    private var contactItems: some View {
        ForEach(Array(contactMatchingManager.nonMatchedContacts.prefix(20)), id: \.identifier) { contact in
            NonMatchedContactRow(
                contact: contact,
                isInvited: invitedContactIds.contains(contact.identifier),
                onInviteTapped: {
                    // Invite the contact and update local state
                    onInvite(contact)
                    invitedContactIds.insert(contact.identifier)
                }
            )
        }
    }
    
    private var moreContactsIndicator: some View {
        HStack {
            Spacer()
            
            Text("+ \(contactMatchingManager.nonMatchedContacts.count - 20) more contacts")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
    
    private var inviteMultipleButton: some View {
        Button(action: {
            // Switch to the invite via text tab
            // This would need to be implemented in the parent view
        }) {
            Text("invite multiple")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    AppColors.accentGradient2
                        .cornerRadius(25)
                )
                .glow(color: AppColors.purple, radius: 8, opacity: 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

/// Row component for a non-matched contact
struct NonMatchedContactRow: View {
    // MARK: - Properties
    
    let contact: CNContact
    let isInvited: Bool
    let onInviteTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Initials
            contactInitialsView
            
            // Contact info
            contactInfoView
                .padding(.leading, 10)
            
            Spacer()
            
            // Action button
            actionButton
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(rowBackground)
    }
    
    // MARK: - Subviews
    
    private var contactInitialsView: some View {
        ZStack {
            Circle()
                .stroke(AppColors.outline, lineWidth: 1)
                .background(Circle().fill(AppColors.cardBackground.opacity(0.7)))
                .frame(width: 50, height: 50)
            
            Text(getContactInitials())
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    private var contactInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(getContactDisplayName().lowercased())
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
            
            if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                Text(phoneNumber)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private var actionButton: some View {
        Button(action: {
            if !isInvited {
                onInviteTapped()
            }
        }) {
            Group {
                if isInvited {
                    invitedButtonContent
                } else {
                    inviteButtonContent
                }
            }
        }
        .disabled(isInvited)
    }
    
    private var invitedButtonContent: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark")
                .font(.system(size: 12))
            
            Text("invited")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(AppColors.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .stroke(AppColors.accent, lineWidth: 1)
        )
    }
    
    private var inviteButtonContent: some View {
        Text("invite")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppColors.accent)
            )
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.cardBackground.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.separator, lineWidth: 1)
            )
    }
    
    // Get contact display name
    private func getContactDisplayName() -> String {
        let firstName = contact.givenName
        let lastName = contact.familyName
        
        if firstName.isEmpty && lastName.isEmpty {
            return "Unknown"
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }
    
    // Get contact initials
    private func getContactInitials() -> String {
        let firstName = contact.givenName
        let lastName = contact.familyName
        
        var initials = ""
        
        if !firstName.isEmpty, let firstInitial = firstName.first {
            initials.append(firstInitial)
        }
        
        if !lastName.isEmpty, let lastInitial = lastName.first {
            initials.append(lastInitial)
        }
        
        return initials.uppercased()
    }
}

// MARK: - Previews

struct NonMatchedContactsList_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            NonMatchedContactsList(
                contactMatchingManager: ContactMatchingManager.shared, 
                onInvite: { _ in }
            )
        }
    }
} 
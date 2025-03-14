import SwiftUI
import Contacts

/// Component for displaying contacts that are matched with KetchupSoon users
struct MatchedContactsList: View {
    // MARK: - Properties
    
    @ObservedObject var contactMatchingManager: ContactMatchingManager
    var onAddFriend: (UserModel) -> Void
    @State private var addedFriendIds: Set<String> = []
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Section header with count
            HStack {
                Text("contacts on ketchupsoon")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(contactMatchingManager.matchedContacts.count)")
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
            
            if contactMatchingManager.isLoading {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                        .scaleEffect(1.2)
                    Spacer()
                }
                .padding(.vertical, 30)
            } else if contactMatchingManager.matchedContacts.isEmpty {
                // No matches found
                VStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textSecondary.opacity(0.7))
                    
                    Text("None of your contacts are on KetchupSoon yet")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // List of matched contacts
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(contactMatchingManager.matchedContacts) { matchedContact in
                            MatchedContactRow(
                                matchedContact: matchedContact,
                                isAdded: addedFriendIds.contains(matchedContact.user.id),
                                onAddTapped: {
                                    // Add the friend and update local state
                                    onAddFriend(matchedContact.user)
                                    addedFriendIds.insert(matchedContact.user.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 350)
            }
        }
    }
}

/// Row component for a matched contact
struct MatchedContactRow: View {
    // MARK: - Properties
    
    let matchedContact: MatchedContact
    let isAdded: Bool
    let onAddTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Avatar/Initials
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: getGradientForUser(matchedContact.user)
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(matchedContact.initials)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AddFriendViewColors.textPrimary)
            }
            
            // Contact info
            VStack(alignment: .leading, spacing: 2) {
                Text(matchedContact.displayName.lowercased())
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary)
                
                if let phoneNumber = matchedContact.contact.phoneNumbers.first?.value.stringValue {
                    Text(phoneNumber)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.leading, 10)
            
            Spacer()
            
            // Action button
            Button(action: {
                if !isAdded {
                    onAddTapped()
                }
            }) {
                Group {
                    if isAdded {
                        // Already added state
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                            
                            Text("added")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(AppColors.mint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(AppColors.mint, lineWidth: 1)
                        )
                    } else {
                        // Add button
                        Text("add")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppColors.mint)
                            )
                    }
                }
            }
            .disabled(isAdded)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.separator, lineWidth: 1)
                )
        )
    }
    
    // Get gradient colors for a user
    private func getGradientForUser(_ user: UserModel) -> [Color] {
        let index = user.gradientIndex
        
        switch index % 5 {
        case 0: return [AddFriendViewColors.mint, AddFriendViewColors.purple]
        case 1: return [AddFriendViewColors.bluePurple, AddFriendViewColors.mint]
        case 2: return [AddFriendViewColors.pinkRed, AddFriendViewColors.purple]
        case 3: return [AddFriendViewColors.mint, AddFriendViewColors.pinkRed]
        case 4: return [AddFriendViewColors.purple, AddFriendViewColors.bluePurple]
        default: return [AddFriendViewColors.mint, AddFriendViewColors.purple]
        }
    }
}

// MARK: - Previews

// Preview isn't fully functional without sample data and environment objects
struct MatchedContactsList_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            MatchedContactsList(
                contactMatchingManager: ContactMatchingManager.shared,
                onAddFriend: { _ in }
            )
        }
    }
} 
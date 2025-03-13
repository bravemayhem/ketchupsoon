import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import OSLog

struct FriendProfileView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    @State private var isFavorite = false
    @State private var isRefreshing = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var userDocumentListener: ListenerRegistration?
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FriendProfileView")
    
    let friend: UserModel
    
    // State to hold the refreshed friend data
    @State private var refreshedFriend: UserModel?
    
    // Profile appearance (using the friend's gradient index)
    private var profileRingGradient: LinearGradient {
        // Safely access the avatar gradients array
        let gradients = AppColors.avatarGradients
        let friendToUse = refreshedFriend ?? friend
        let safeIndex = min(max(friendToUse.gradientIndex, 0), gradients.count - 1)
        return gradients[safeIndex]
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background with decorative elements
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Use our shared decorative elements
            DecorativeBubbles.profile
            BackgroundElementFactory.profileElements()
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Profile content view
                    friendProfileContentView
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .foregroundColor(.white)
            .refreshable {
                // Using SwiftUI's native refreshable which provides better system integration
                print("🔄 Native refreshable: Starting friend profile refresh")
                await refreshFriendData()
                print("✅ Native refreshable: Completed friend profile refresh")
            }
            
            // Action buttons at bottom
         //   bottomActionButtons
            
            // Back button
            backButton
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                // Initial data load when view appears
                await refreshFriendData()
                // Start listening for real-time updates
                startRealTimeUpdates()
            }
        }
        .onDisappear {
            // Clean up listener when view disappears
            stopRealTimeUpdates()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") {
                errorMessage = nil
            }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
    }
    
    // MARK: - Friend Profile Content View
    private var friendProfileContentView: some View {
        VStack(spacing: 20) {
            // Profile picture
            ZStack {
                // Gradient ring with enhanced glow effect
                Circle()
                    .fill(profileRingGradient)
                    .frame(width: 150, height: 150)
                    .modifier(GlowModifier(color: AppColors.purple, radius: 12, opacity: 0.8))
                    .shadow(color: AppColors.purple.opacity(0.5), radius: 8, x: 0, y: 0)
                
                // Profile image or emoji
                let friendToUse = refreshedFriend ?? friend
                if let profileImageURL = friendToUse.profileImageURL, !profileImageURL.isEmpty, let url = URL(string: profileImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } placeholder: {
                        ZStack {
                            // Show emoji placeholder while loading
                            Text("😎")
                                .font(.system(size: 50))
                                .frame(width: 140, height: 140)
                            
                            // Add a progress indicator
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                } else {
                    // Emoji placeholder when no image is available
                    Text("😎")
                        .font(.system(size: 50))
                        .frame(width: 140, height: 140)
                }
            }
            .padding(.top, 20)
            
            // User name
            let friendToUse = refreshedFriend ?? friend
            Text(friendToUse.name ?? "Friend")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.top, 10)
            
            // User bio (as regular text)
            if let bio = friendToUse.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 2)
            }
            
            // User info as simple text lines with emoji
            VStack(spacing: 12) {
                let friendToUse = refreshedFriend ?? friend
                
                if let phoneNumber = friendToUse.phoneNumber, !phoneNumber.isEmpty {
                    HStack(spacing: 8) {
                        Text("📱")
                        Text(formatPhoneForDisplay(phoneNumber))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if let birthday = friendToUse.birthday {
                    HStack(spacing: 8) {
                        Text("🎂")
                        Text(formatBirthdayForDisplay(birthday))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .clayMorphism(cornerRadius: 30)
        .padding(.horizontal, 10)
    }
    
    
    
    // MARK: - Bottom Action Buttons
    //Removing for MVP
    /*
    private var bottomActionButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Button(action: {
                    // Handle message action
                }) {
                    Text("message")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 41/255, green: 37/255, blue: 97/255),
                                Color(red: 21/255, green: 17/255, blue: 50/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 41/255, green: 37/255, blue: 97/255, opacity: 0.5), radius: 4)
                }
                
                Button(action: {
                    // Handle schedule action
                }) {
                    HStack {
                        Text("schedule")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(LinearGradient(
                        gradient: Gradient(colors: [AppColors.gradient2Start, AppColors.gradient2End]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .cornerRadius(25)
                    .shadow(color: AppColors.gradient2Start.opacity(0.5), radius: 5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
    }
    
    */
    
    // MARK: - Back Button
    private var backButton: some View {
        VStack {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 21/255, green: 17/255, blue: 50/255))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    
    // Helper to format phone number for display
    private func formatPhoneForDisplay(_ phone: String) -> String {
        // Only keep digits
        let cleaned = phone.filter { $0.isNumber }
        
        // For short numbers, just return the original
        if cleaned.count < 10 {
            return phone
        }
        
        var formatted = ""
        
        // If there are more than 10 digits, add the extra digits at the beginning
        if cleaned.count > 10 {
            let extraDigits = String(cleaned.prefix(cleaned.count - 10))
            formatted += extraDigits + " "
        }
        
        // Get the last 10 digits for standard formatting
        let lastTenDigits = cleaned.count > 10 ? 
            String(cleaned.suffix(10)) : cleaned
        
        // Format the last 10 digits as (XXX) XXX-XXXX
        for (index, character) in lastTenDigits.enumerated() {
            if index == 0 {
                formatted += "("
            }
            if index == 3 {
                formatted += ") "
            }
            if index == 6 {
                formatted += "-"
            }
            formatted.append(character)
        }
        
        return formatted
    }
    
    // Helper to format birthday for display
    private func formatBirthdayForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Helper Methods
extension FriendProfileView {
    
    // Refresh friend data from Firebase
    private func refreshFriendData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Get the latest user data from Firebase using the friendID
        let userRepository = UserRepositoryFactory.createRepository(modelContext: modelContext)
        do {
            let updatedFriend = try await userRepository.getUser(id: friend.id)
            await MainActor.run {
                self.refreshedFriend = updatedFriend
                self.isRefreshing = false
                self.isLoading = false
                logger.info("Successfully refreshed friend data for \(friend.id)")
            }
        } catch {
            await MainActor.run {
                self.isRefreshing = false
                self.isLoading = false
                errorMessage = "Could not find friend data: \(error.localizedDescription)"
                logger.warning("Friend not found with ID \(friend.id): \(error)")
            }
        }
    }
    
    // Set up real-time updates for this friend
    private func startRealTimeUpdates() {
        // Create a listener for this specific user document
        let userRef = Firestore.firestore().collection("users").document(friend.id)
        
        // Create a listener and store it for later cleanup
        let listener = userRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                self.logger.error("Error fetching user document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // If the document exists and has data, update our friend model
            if document.exists, let userData = document.data() {
                // Create a UserModel from firestore data
                // Get existing user to update
                let friendID = document.documentID
                let descriptor = FetchDescriptor<UserModel>(predicate: #Predicate { user in 
                    user.id == friendID
                })
                do {
                    let existingUser = try self.modelContext.fetch(descriptor).first
                    
                    if let existingUser = existingUser {
                        // Update existing user
                        let updatedFriend = existingUser
                        // Update properties from firestore data
                        updatedFriend.name = userData["name"] as? String ?? updatedFriend.name
                        updatedFriend.profileImageURL = userData["profileImageURL"] as? String ?? updatedFriend.profileImageURL
                        updatedFriend.bio = userData["bio"] as? String ?? updatedFriend.bio
                        // Update on the main thread since this impacts UI
                        DispatchQueue.main.async {
                            self.refreshedFriend = updatedFriend
                            self.logger.info("Real-time update received for friend \(updatedFriend.id)")
                        }
                    }
                } catch {
                    self.logger.error("Error updating friend from Firestore: \(error)")
                }
            }
        }
        
        // Store the listener in our state variable
        self.userDocumentListener = listener
    }
    
    // Track our listener is managed with @State above
    
    // Clean up listeners when the view disappears
    private func stopRealTimeUpdates() {
        // Remove the listener if it exists
        userDocumentListener?.remove()
        userDocumentListener = nil
        logger.info("Stopped real-time updates for friend profile")
    }
}

// Refreshable scroll view implementation
// RefreshableView has been moved to ImprovedRefreshableView.swift
// as SimpleRefreshableView for better debouncing and performance

// MARK: - Preview
#Preview {
    // Create a sample friend for preview
    let sampleFriend = UserModel(
        id: "123456",
        name: "Jordan Chen",
        profileImageURL: nil,
        email: "jordan@example.com",
        phoneNumber: "+1 (555) 123-4567",
        bio: "Gaming enthusiast and craft beer connoisseur. Ask me about: 🎮 Elden Ring, 🏀 Warriors, 🍺 IPAs",
        birthday: Date()
    )
    
    // Set up preview with Firebase service
    let previewContainer = try! ModelContainer(for: UserModel.self, FriendshipModel.self, MeetupModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    return FriendProfileView(friend: sampleFriend)
        .modelContainer(previewContainer)
        .environmentObject(FirebaseSyncServiceFactory.preview)
        .preferredColorScheme(.dark)
}

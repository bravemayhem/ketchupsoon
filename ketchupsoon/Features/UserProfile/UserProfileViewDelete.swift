/*
import SwiftUI
import FirebaseAuth
import PhotosUI
import OSLog
import SwiftData

/// Bridge that forwards to the ProfileFactory pattern
/// This ensures consistency in how profiles are loaded and displayed
struct UserProfileView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Dependencies
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    
    // MARK: - Body
    var body: some View {
        // Simply delegate to the ProfileFactory to create a consistent profile view
        // This ensures we're using the same profile loading logic everywhere
        ProfileFactory.createProfileView(
            for: .currentUser,
            modelContext: modelContext,
            firebaseSyncService: firebaseSyncService
        )
        .onAppear {
            print("UserProfileView using ProfileFactory bridge - this ensures consistent profile loading")
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: UserModel.self)
    let firebaseSyncService = FirebaseSyncService(modelContext: container.mainContext)
    
    UserProfileView()
        .preferredColorScheme(.dark)
        .environmentObject(firebaseSyncService)
        .modelContainer(container)
}
*/

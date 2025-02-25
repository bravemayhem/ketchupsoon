import SwiftUI
import SwiftData

struct WishlistPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CreateHangoutViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppColors.accent)
                
                Text("Remove from Wishlist?")
                    .font(.title2)
                    .bold()
                
                Text("You've scheduled time with \(viewModel.selectedFriends.map(\.name).joined(separator: ", ")). Would you like to remove them from your wishlist?")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Keep on Wishlist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        viewModel.removeFromWishlist()
                        dismiss()
                    }) {
                        Text("Remove")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(300)])
    }
}

#Preview {
    let friend = Friend(name: "Test Friend", needsToConnectFlag: true)
    let viewModel = CreateHangoutViewModel(
        modelContext: ModelContext(try! ModelContainer(for: Friend.self, Hangout.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    )
    viewModel.selectedFriends = [friend]
    return WishlistPromptView(viewModel: viewModel)
} 

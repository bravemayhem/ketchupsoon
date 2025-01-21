import SwiftUI
import SwiftData
#if canImport(MessageUI)
import MessageUI
#endif

/// FriendExistingView provides the interface for viewing and editing existing friend details.
///
/// # Overview
/// This view serves as the primary interface for managing an existing friend's information.
/// It can be presented either through navigation or as a modal sheet, and provides
/// full editing capabilities for all friend properties.

// MARK: - Updated FriendExistingView
struct FriendExistingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FriendDetail.ViewModel
    let presentationStyle: FriendDetail.PresentationStyle
    
    init(friend: Friend, presentationStyle: FriendDetail.PresentationStyle) {
        self._viewModel = State(initialValue: FriendDetail.ViewModel(friend: friend))
        self.presentationStyle = presentationStyle
    }
    
    var body: some View {
        BaseFriendForm(configuration: FormConfiguration.existing) { config in
            Group {
                if config.showsLocation || config.showsLastSeen || config.showsName {
                    FriendInfoSection(
                        friend: viewModel.friend,
                        onLastSeenTap: {
                            viewModel.showingDatePicker = true
                        },
                        onCityTap: {
                            viewModel.showingCityPicker = true
                        }
                    )
                }
                
                if config.showsTags {
                    FriendTagsSection(
                        friend: viewModel.friend,
                        onManageTags: {
                            viewModel.showingTagsManager = true
                        }
                    )
                }
                
                if config.showsActions {
                    FriendActionSection(
                        friend: viewModel.friend,
                        onMessageTap: {
                            viewModel.showingMessageSheet = true
                        },
                        onScheduleTap: {
                            viewModel.showingScheduler = true
                        },
                        onMarkSeenTap: {
                            viewModel.markAsSeen()
                        }
                    )
                }
                
                if config.showsHangouts {
                    FriendHangoutsSection(hangouts: viewModel.friend.scheduledHangouts)
                }
            }
        }
        .navigationTitle(viewModel.friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .sheet(let isPresented) = presentationStyle {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented.wrappedValue = false
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .datePickerSheet(
            isPresented: $viewModel.showingDatePicker,
            date: $viewModel.lastSeenDate,
            onSave: viewModel.updateLastSeenDate
        )
        .cityPickerSheet(
            isPresented: $viewModel.showingCityPicker,
            searchText: $viewModel.citySearchText,
            selectedCity: $viewModel.selectedCity,
            onSave: viewModel.updateCity
        )
        .sheet(isPresented: $viewModel.showingTagsManager) {
            TagsSelectionView(friend: viewModel.friend)
        }
        .sheet(isPresented: $viewModel.showingScheduler) {
            SchedulerView(initialFriend: viewModel.friend)
        }
    }
}

#Preview {
    NavigationStack {
        FriendExistingView(
            friend: Friend(
                name: "Aleah Goldstein",
                lastSeen: Date(),
                location: "Los Angeles, CA",
                phoneNumber: "+1234567890"
            ),
            presentationStyle: .navigation
        )
    }
    .modelContainer(for: Friend.self)
} 


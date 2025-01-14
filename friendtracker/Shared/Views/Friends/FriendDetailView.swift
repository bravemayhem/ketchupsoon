import SwiftUI
import SwiftData
import MessageUI

@Observable
class FriendDetailViewModel {
    let friend: Friend
    var showingDatePicker = false
    var showingScheduler = false
    var showingMessageSheet = false
    var showingCityPicker = false
    var showingTagsManager = false
    var lastSeenDate = Date()
    var citySearchText = ""
    var selectedCity: String?
    
    init(friend: Friend) {
        self.friend = friend
        self.citySearchText = friend.location ?? ""
        self.selectedCity = friend.location
    }
    
    func markAsSeen() {
        friend.updateLastSeen()
    }
    
    func updateLastSeenDate(to date: Date) {
        friend.updateLastSeen(to: date)
    }
    
    func updateCity() {
        friend.location = selectedCity
    }
}

struct FriendDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FriendDetailViewModel
    let presentationMode: PresentationMode
    
    init(friend: Friend, presentationMode: PresentationMode) {
        self._viewModel = State(initialValue: FriendDetailViewModel(friend: friend))
        self.presentationMode = presentationMode
    }
    
    enum PresentationMode {
        case sheet(Binding<Bool>)
        case navigation
    }
    
    var body: some View {
        List {
            FriendInfoSection(
                friend: viewModel.friend,
                onLastSeenTap: {
                    viewModel.lastSeenDate = viewModel.friend.lastSeen ?? Date()
                    viewModel.showingDatePicker = true
                },
                onCityTap: {
                    viewModel.showingCityPicker = true
                }
            )
            
            FriendTagsSection(
                friend: viewModel.friend,
                onManageTags: {
                    viewModel.showingTagsManager = true
                }
            )
            
            FriendActionSection(
                friend: viewModel.friend,
                onMessageTap: { viewModel.showingMessageSheet = true },
                onScheduleTap: { viewModel.showingScheduler = true },
                onMarkSeenTap: { viewModel.markAsSeen() }
            )
            
            FriendHangoutsSection(hangouts: viewModel.friend.scheduledHangouts)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .listSectionSpacing(20)
        .environment(\.defaultMinListHeaderHeight, 0)
        .navigationTitle(viewModel.friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .sheet(let isPresented) = presentationMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented.wrappedValue = false
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $viewModel.lastSeenDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Last Seen Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.showingDatePicker = false
                        }
                        .foregroundColor(AppColors.accent)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.updateLastSeenDate(to: viewModel.lastSeenDate)
                            viewModel.showingDatePicker = false
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showingCityPicker) {
            NavigationStack {
                Form {
                    CitySearchField(searchText: $viewModel.citySearchText, selectedCity: $viewModel.selectedCity)
                }
                .navigationTitle("Update City")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.showingCityPicker = false
                        }
                        .foregroundColor(AppColors.accent)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.updateCity()
                            viewModel.showingCityPicker = false
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showingScheduler) {
            NavigationStack {
                SchedulerView(initialFriend: viewModel.friend)
            }
        }
        .sheet(isPresented: $viewModel.showingMessageSheet) {
            MessageComposeView(recipient: viewModel.friend.phoneNumber ?? "")
        }
        .sheet(isPresented: $viewModel.showingTagsManager) {
            NavigationStack {
                TagsManagementView(friend: viewModel.friend)
            }
        }
        .background(AppColors.systemBackground)
    }
}

#Preview {
    NavigationStack {
        FriendDetailView(
            friend: Friend(
                name: "Preview Friend",
                lastSeen: Date(),
                location: "Local",
                phoneNumber: "+1234567890"
            ),
            presentationMode: .navigation
        )
    }
    .modelContainer(for: Friend.self)
} 
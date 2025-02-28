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

struct FriendExistingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FriendDetail.ViewModel
    @State private var cityService = CitySearchService()
    @State private var showingBirthdayPicker = false
    @State private var selectedBirthday: Date?
    
    init(friend: Friend) {
        self._viewModel = State(initialValue: FriendDetail.ViewModel(friend: friend))
        // Initialize cityService with friend's location
        let service = CitySearchService()
        if let location = friend.location {
            service.searchInput = location
            service.selectedCity = location
        }
        self._cityService = State(initialValue: service)
        self._selectedBirthday = State(initialValue: friend.birthday)
    }
    
    var body: some View {
        BaseFriendForm(configuration: FormConfiguration.existing) { config in
            Group {
                if config.showsLocation || config.showsLastSeen || config.showsName || config.showsCatchUpFrequency {
                    FriendInfoExistingSection(
                        friend: viewModel.friend,
                        cityService: cityService
                    )
                    .onTapGesture {
                        if viewModel.friend.contactIdentifier != nil {
                            viewModel.showingContactSheet = true
                        }
                    }
                    
                    FriendKetchupSection(
                        friend: viewModel.friend,
                        onLastSeenTap: {
                            viewModel.showingDatePicker = true
                        },
                        onFrequencyTap: {
                            viewModel.showingFrequencyPicker = true
                        }
                    )
                    
                    // Birthday Section
                    Section {
                        Button(action: {
                            showingBirthdayPicker = true
                        }) {
                            HStack {
                                Text("Birthday")
                                    .foregroundColor(AppColors.label)
                                
                                Spacer()
                                
                                if let birthday = viewModel.friend.birthday {
                                    Text(birthdayFormatter.string(from: birthday))
                                        .foregroundColor(AppColors.secondaryLabel)
                                } else {
                                    Text("Not set")
                                        .foregroundColor(AppColors.secondaryLabel)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(AppColors.tertiaryLabel)
                            }
                        }
                    } header: {
                        Text("Personal")
                    }
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
        .datePickerSheet(
            isPresented: $viewModel.showingDatePicker,
            date: $viewModel.lastSeenDate,
            onSave: viewModel.updateLastSeenDate
        )
        .sheet(isPresented: $showingBirthdayPicker) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "Birthday",
                        selection: Binding(
                            get: { selectedBirthday ?? Date() },
                            set: { selectedBirthday = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                }
                .navigationTitle("Select Birthday")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingBirthdayPicker = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.friend.birthday = selectedBirthday
                            showingBirthdayPicker = false
                        }
                    }
                    
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            selectedBirthday = nil
                            viewModel.friend.birthday = nil
                            showingBirthdayPicker = false
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingFrequencyPicker) {
            NavigationStack {
                FrequencyPickerView(friend: viewModel.friend)
            }
        }
        .sheet(isPresented: $viewModel.showingTagsManager) {
            TagsSelectionView(friend: viewModel.friend)
        }
        .sheet(isPresented: $viewModel.showingScheduler) {
            CreateHangoutView(initialSelectedFriends: [viewModel.friend])
        }
        .sheet(isPresented: $viewModel.showingMessageSheet) {
            if let phoneNumber = viewModel.friend.phoneNumber {
                MessageComposeView(recipient: phoneNumber)
            }
        }
        .sheet(isPresented: $viewModel.showingContactSheet) {
            if let contactIdentifier = viewModel.friend.contactIdentifier {
                ContactDisplayView(
                    contactIdentifier: contactIdentifier,
                    position: "friend_existing",
                    isPresented: $viewModel.showingContactSheet
                )
            }
        }
        .onChange(of: cityService.selectedCity) { _, newCity in
            viewModel.friend.location = newCity
        }
    }
    
    // Date formatter specifically for displaying birthdays
    private var birthdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
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
            )
        )
    }
    .modelContainer(for: Friend.self)
} 


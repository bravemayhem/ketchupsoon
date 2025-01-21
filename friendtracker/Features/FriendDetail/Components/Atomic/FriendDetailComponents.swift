import SwiftUI
import SwiftData

// MARK: - CURRENTLY USED FOR NEW FRIENDS
//USED FOR IMPORTING NEW CONTACTS NAMES FROM THE CONTACT LIST OR MANUALLY FOR THE FIRST TIME
struct FriendNameSection: View {
    let isFromContacts: Bool
    let contactName: String?
    @Binding var manualName: String
    
    var body: some View {
        Section("Name") {
            if isFromContacts {
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    Text(contactName ?? "")
                        .foregroundColor(AppColors.secondaryLabel)
                }
            } else {
                TextField("Name", text: $manualName)
                    .foregroundColor(AppColors.label)
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

//USED FOR SETTING UP ADDING SOMEONE TO THE "WISH LIST" FOR THE FIRST TIME
struct FriendConnectSection: View {
    @Binding var wantToConnectSoon: Bool
    
    var body: some View {
        Section("Connect Soon") {
            Toggle("Want to connect soon?", isOn: $wantToConnectSoon)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

//USED FOR SETTING UP CATCH UP FREQUENCY FOR THE FIRST TIME
struct FriendCatchUpSection: View {
    @Binding var hasCatchUpFrequency: Bool
    @Binding var selectedFrequency: CatchUpFrequency
    
    var body: some View {
        Section("Catch Up Frequency") {
            Toggle("Set catch up goal?", isOn: $hasCatchUpFrequency)
            
            if hasCatchUpFrequency {
                Picker("Frequency", selection: $selectedFrequency) {
                    ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayText).tag(frequency)
                    }
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

//USED FOR SETTING UP LAST SEEN DATE FOR THE FIRST TIME
struct FriendLastSeenSection: View {
    @Binding var hasLastSeen: Bool
    @Binding var lastSeenDate: Date
    @State private var showingDatePicker = false
    
    var body: some View {
        Section("Last Seen") {
            Toggle("Add last seen date?", isOn: $hasLastSeen)
            
            if hasLastSeen {
                Button {
                    showingDatePicker = true
                } label: {
                    HStack {
                        Text("Last Seen Date")
                        Spacer()
                        Text(lastSeenDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
        .datePickerSheet(
            isPresented: $showingDatePicker,
            date: $lastSeenDate,
            onSave: { date in
                lastSeenDate = date
            }
        )
    }
}


// MARK: - CURRENTLY USED FOR EXISTING FRIENDS
struct FriendInfoSection: View {
    let friend: Friend
    let onLastSeenTap: () -> Void
    let onCityTap: () -> Void
    
    var body: some View {
        Section("Friend Details") {
            // Last Seen
            HStack {
                Text("Last Seen")
                    .foregroundColor(AppColors.label)
                Spacer()
                Button {
                    onLastSeenTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                        Text(friend.lastSeenText)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
            }
            
            // Location
            Button(action: onCityTap) {
                HStack {
                    Text("City")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    if let location = friend.location {
                        Text(location)
                            .foregroundColor(AppColors.secondaryLabel)
                    } else {
                        Text("Not set")
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

struct FriendActionSection: View {
    @Bindable var friend: Friend
    let onMessageTap: () -> Void
    let onScheduleTap: () -> Void
    let onMarkSeenTap: () -> Void
    
    var body: some View {
        Section("Actions") {
            if !(friend.phoneNumber?.isEmpty ?? true) {
                Button(action: onMessageTap) {
                    Label("Send Message", systemImage: "message.fill")
                        .actionLabelStyle()
                }
            }
            
            Button(action: onScheduleTap) {
                Label("Schedule Hangout", systemImage: "calendar")
                    .actionLabelStyle()
            }
            
            Button(action: onMarkSeenTap) {
                Label("Mark as Seen Today", systemImage: "checkmark.circle.fill")
                    .actionLabelStyle()
            }
            
            Button {
                friend.needsToConnectFlag.toggle()
            } label: {
                HStack {
                    Label(friend.needsToConnectFlag ? "Remove from Wishlist" : "Add to Wishlist",
                          systemImage: friend.needsToConnectFlag ? "star.slash" : "star")
                        .actionLabelStyle()
                    Spacer()
                    Toggle("", isOn: $friend.needsToConnectFlag)
                        .labelsHidden()
                        .tint(AppColors.accent)
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}


struct FriendHangoutsSection: View {
    let hangouts: [Hangout]
    
    var body: some View {
        if !hangouts.isEmpty {
            Section("Upcoming Hangouts") {
                ForEach(hangouts) { hangout in
                    VStack(alignment: .leading, spacing: AppTheme.spacingTiny) {
                        Text(hangout.activity)
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.label)
                        Text(hangout.location)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                        Text(hangout.formattedDate)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                    .padding(.vertical, AppTheme.spacingTiny)
                }
            }
            .listRowBackground(AppColors.secondarySystemBackground)
        }
    }
}

// MARK: - USED FOR BOTH EXISTING AND NEW FRIENDS
struct FriendTagsSection: View {
    private var displayTags: [Tag]  // Store the tags directly
    let onManageTags: () -> Void
    
    // Init for existing friends
    init(friend: Friend, onManageTags: @escaping () -> Void) {
        self.displayTags = friend.tags
        self.onManageTags = onManageTags
    }
    
    // Init for new friends (onboarding)
    init(tags: Set<Tag>, onManageTags: @escaping () -> Void) {
        self.displayTags = Array(tags)
        self.onManageTags = onManageTags
    }
    
    private var tagsContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(displayTags) { tag in
                    TagView(tag: tag)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var manageTags: some View {
        Button(action: onManageTags) {
            Label("Manage Tags", systemImage: "tag")
                .actionLabelStyle()
        }
    }
    
    var body: some View {
        Section("Tags") {
            if displayTags.isEmpty {
                Text("No tags added")
                    .foregroundColor(AppColors.secondaryLabel)
            } else {
                tagsContent
            }
            manageTags
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

// Helper view for individual tags
struct TagView: View {
    let tag: Tag
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag.name)")
                .font(AppTheme.captionFont)
                .foregroundColor(AppColors.label)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.systemBackground)  // Changed to systemBackground (F2F2F7)
        .clipShape(Capsule())
    }
}


// MARK: - PREVIEW SECTION
#Preview("FriendInfoSection") {
    NavigationStack {
        List {
            FriendInfoSection(
                friend: Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "San Francisco",
                    phoneNumber: "(415) 555-0123",
                    catchUpFrequency: .monthly
                ),
                onLastSeenTap: {},
                onCityTap: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}

#Preview("FriendActionSection") {
    NavigationStack {
        List {
            FriendActionSection(
                friend: Friend(
                    name: "John Doe",
                    lastSeen: Date(),
                    location: "New York",
                    needsToConnectFlag: true,
                    phoneNumber: "(212) 555-0123",
                    catchUpFrequency: .weekly
                ),
                onMessageTap: {},
                onScheduleTap: {},
                onMarkSeenTap: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}

#Preview("FriendHangoutsSection - With Hangouts") {
    let schema = Schema([Friend.self, Tag.self, Hangout.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = container.mainContext
    
    let friend = Friend(
        name: "Alice Smith",
        lastSeen: Date(),
        location: "Local",
        phoneNumber: "(555) 123-4567"
    )
    context.insert(friend)
    
    let hangouts = [
        Hangout(
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            activity: "Coffee",
            location: "Starbucks",
            isScheduled: true,
            friend: friend
        ),
        Hangout(
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            activity: "Lunch",
            location: "Italian Restaurant",
            isScheduled: true,
            friend: friend
        )
    ]
    hangouts.forEach { context.insert($0) }
    
    return NavigationStack {
        List {
            FriendHangoutsSection(hangouts: hangouts)
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(container)
}

#Preview("FriendTagsSection") {
    let schema = Schema([Friend.self, Tag.self, Hangout.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = container.mainContext
    
    let friend = Friend(
        name: "Bob Wilson",
        lastSeen: Date(),
        location: "Remote"
    )
    
    let tags = [
        Tag(name: "college"),
        Tag(name: "book club"),
        Tag(name: "hiking")
    ]
    tags.forEach { context.insert($0) }
    friend.tags = tags
    context.insert(friend)
    
    return NavigationStack {
        List {
            FriendTagsSection(
                friend: friend,
                onManageTags: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(container)
}

#Preview("TagView") {
    HStack {
        TagView(tag: Tag(name: "college"))
        TagView(tag: Tag(name: "book club"))
        TagView(tag: Tag(name: "hiking"))
    }
    .padding()
    .background(AppColors.secondarySystemBackground)
    .modelContainer(for: [Tag.self])
}

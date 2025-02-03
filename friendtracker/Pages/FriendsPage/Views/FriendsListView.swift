import SwiftUI
import SwiftData
import MessageUI

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFriends: [Friend]
    @Query private var allTags: [Tag]
    @State private var selectedFriend: Friend?
    @State private var searchText = ""
    @State private var selectedTags: Set<Tag> = []
    @State private var sortOption: SortOption = .name
    @State private var sortDirection: SortDirection = .none
    @State private var showingTagPicker = false
    @State private var showingSortPicker = false
    
    init() {
        let sortDescriptor = SortDescriptor(\Friend.name)
        _allFriends = Query(sort: [sortDescriptor])
        _allTags = Query()
    }
    
    enum SortDirection {
        case ascending
        case descending
        case none
        
        var systemImage: String {
            switch self {
            case .ascending:
                return "arrow.up"
            case .descending:
                return "arrow.down"
            case .none:
                return "arrow.up.arrow.down"
            }
        }
        
        mutating func toggle() {
            switch self {
            case .none:
                self = .ascending
            case .ascending:
                self = .descending
            case .descending:
                self = .none
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case lastSeen = "Last Seen"
        
        var descriptor: SortDescriptor<Friend> {
            switch self {
            case .name:
                return SortDescriptor(\Friend.name)
            case .lastSeen:
                return SortDescriptor(\Friend.lastSeen, order: .reverse)
            }
        }
    }
    
    var filteredFriends: [Friend] {
        var result = allFriends
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply tag filter
        if !selectedTags.isEmpty {
            result = result.filter { friend in
                !selectedTags.isDisjoint(with: Set(friend.tags))
            }
        }
        
        // Apply sort based on direction and option
        if sortDirection != .none {
            switch sortOption {
            case .name:
                result.sort { friend1, friend2 in
                    sortDirection == .ascending ? 
                        friend1.name < friend2.name :
                        friend1.name > friend2.name
                }
            case .lastSeen:
                result.sort { friend1, friend2 in
                    guard let date1 = friend1.lastSeen else { return false }
                    guard let date2 = friend2.lastSeen else { return true }
                    return sortDirection == .ascending ? date1 < date2 : date1 > date2
                }
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 8) {
                // Search Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.secondaryLabel)
                        .font(.system(size: 16))
                    TextField("Search friends", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Sort and Filter Controls
                HStack(spacing: 8) {
                    // Sort Controls Group
                    HStack(spacing: 0) {
                        // Direction Toggle Button
                        Button(action: { sortDirection.toggle() }) {
                            Image(systemName: sortDirection.systemImage)
                                .font(.system(size: 14))
                        }
                        .frame(width: 32, height: 32)
                        .background(sortDirection == .none ? Color(.systemGray6) : AppColors.accent)
                        .foregroundColor(sortDirection == .none ? AppColors.label : .white)
                        
                        // Sort Label
                        Text("Sort")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.label)
                            .padding(.horizontal, 8)
                        
                        Spacer(minLength: 0)
                        
                        // Sort Option Button
                        Button(action: { showingSortPicker = true }) {
                            HStack(spacing: 4) {
                                Text(sortOption.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.secondaryLabel)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.secondaryLabel)
                            }
                            .frame(minWidth: 80, alignment: .leading)
                        }
                        .padding(.trailing, 8)
                    }
                    .padding(.leading, 0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Filter Button
                    Button(action: { showingTagPicker = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                                .font(.system(size: 14))
                            Text("Filter")
                                .font(.system(size: 14))
                            if !selectedTags.isEmpty {
                                Text("\(selectedTags.count)")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.secondaryLabel)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .foregroundColor(selectedTags.isEmpty ? AppColors.label : AppColors.accent)
                }
                .frame(height: 32)
                
                // Selected Tags
                if !selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedTags), id: \.self) { tag in
                                FilterTagView(tag: tag) {
                                    selectedTags.remove(tag)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(height: 28)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.systemBackground)
            
            // Friends List
            List {
                if filteredFriends.isEmpty {
                    emptyStateView
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredFriends) { friend in
                        NavigationLink(value: friend) {
                            FriendListCard(friend: friend)
                                .friendCardStyle()
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                friend.needsToConnectFlag.toggle()
                            } label: {
                                Label(friend.needsToConnectFlag ? "Remove" : "Add", 
                                      systemImage: friend.needsToConnectFlag ? "star.slash.fill" : "star.fill")
                            }
                            .tint(friend.needsToConnectFlag ? .red : AppColors.success)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: Friend.self) { friend in
                FriendExistingView(friend: friend)
            }
        }
        .friendListStyle()
        .friendSheetPresenter(selectedFriend: $selectedFriend)
        .sheet(isPresented: $showingTagPicker) {
            TagPickerView(selectedTags: $selectedTags, allTags: allTags)
        }
        .sheet(isPresented: $showingSortPicker) {
            SortPickerView(sortOption: $sortOption)
        }
        .onAppear {
            #if DEBUG
            debugLog("FriendsListView appeared with \(allFriends.count) friends")
            #endif
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if searchText.isEmpty && selectedTags.isEmpty {
            ContentUnavailableView("No Friends Added", systemImage: "person.2.badge.plus")
                .foregroundColor(AppColors.label)
        } else {
            ContentUnavailableView("No Matches Found", systemImage: "magnifyingglass")
                .foregroundColor(AppColors.label)
        }
    }
}

struct FilterTagView: View {
    let tag: Tag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.system(size: 12))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: Set<Tag>
    let allTags: [Tag]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allTags) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        HStack {
                            Text(tag.name)
                                .foregroundColor(AppColors.label)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .listRowBackground(AppColors.systemBackground)
                }
            }
            .navigationTitle("Filter by Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear All") {
                        selectedTags.removeAll()
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .opacity(selectedTags.isEmpty ? 0.5 : 1)
                    .disabled(selectedTags.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct SortPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sortOption: FriendsListView.SortOption
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(FriendsListView.SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        sortOption = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundColor(AppColors.label)
                            Spacer()
                            if option == sortOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .listRowBackground(AppColors.systemBackground)
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct FriendsListPreviewContainer: View {
    enum PreviewState {
        case empty
        case withFriends
    }
    
    let state: PreviewState
    let container: ModelContainer
    
    init(state: PreviewState) {
        self.state = state
        
        let schema = Schema([Friend.self, Tag.self, Hangout.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        if state == .withFriends {
            // Create sample friends with various states
            let friends = [
                Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                    location: "San Francisco",
                    needsToConnectFlag: true,
                    phoneNumber: "(415) 555-0123",
                    catchUpFrequency: .weekly
                ),
                Friend(
                    name: "James Wilson",
                    lastSeen: Date(),
                    location: "Local",
                    phoneNumber: "(555) 123-4567",
                    catchUpFrequency: .monthly
                ),
                Friend(
                    name: "Sarah Chen",
                    lastSeen: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                    location: "Remote",
                    needsToConnectFlag: true,
                    phoneNumber: "(650) 555-0199",
                    catchUpFrequency: .quarterly
                ),
                Friend(
                    name: "Alex Rodriguez",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "Oakland",
                    phoneNumber: "(510) 555-0145"
                )
            ]
            
            // Add some tags to friends
            let tags = [
                Tag(name: "college"),
                Tag(name: "work"),
                Tag(name: "book club"),
                Tag(name: "hiking")
            ]
            
            friends[0].tags = [tags[0], tags[3]]  // Emma: college, hiking
            friends[1].tags = [tags[1]]           // James: work
            friends[2].tags = [tags[1], tags[2]]  // Sarah: work, book club
            
            // Add some hangouts
            let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            let hangout = Hangout(
                date: futureDate,
                activity: "Coffee",
                location: "Blue Bottle",
                isScheduled: true,
                friends: [friends[0]]
            )
            
            // Insert everything into context
            friends.forEach { context.insert($0) }
            tags.forEach { context.insert($0) }
            context.insert(hangout)
        }
        
        self.container = container
    }
    
    var body: some View {
        NavigationStack {
            FriendsListView()
        }
        .modelContainer(container)
    }
}

#Preview("Empty State") {
    FriendsListPreviewContainer(state: .empty)
}

#Preview("With Friends") {
    FriendsListPreviewContainer(state: .withFriends)
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

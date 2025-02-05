import SwiftUI
import SwiftData
import MessageUI

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFriends: [Friend]
    @Query private var allTags: [Tag]
    @State private var selectedFriend: Friend?
    @StateObject private var viewModel = FriendsListViewModel()
    
    init() {
        let sortDescriptor = SortDescriptor(\Friend.name)
        _allFriends = Query(sort: [sortDescriptor])
        _allTags = Query()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            FriendsSearchFilterBar(
                searchText: $viewModel.searchText,
                selectedTags: $viewModel.selectedTags,
                sortDirection: $viewModel.sortDirection,
                sortOption: $viewModel.sortOption,
                showingTagPicker: $viewModel.showingTagPicker,
                showingSortPicker: $viewModel.showingSortPicker
            )
            
            // Friends List
            List {
                if viewModel.filteredFriends(allFriends).isEmpty {
                    emptyStateView
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.filteredFriends(allFriends)) { friend in
                        BetterNavigationLink {
                            FriendListCard(friend: friend)
                                .friendCardStyle()
                        } destination: {
                            FriendExistingView(friend: friend)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .tint(.clear)
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
        .sheet(isPresented: $viewModel.showingTagPicker) {
            TagPickerView(selectedTags: $viewModel.selectedTags, allTags: allTags)
        }
        .sheet(isPresented: $viewModel.showingSortPicker) {
            SortPickerView(sortOption: $viewModel.sortOption)
        }
        .onAppear {
            let stopMeasuring = PerformanceMonitor.shared.measureAsync("FriendsListView-Load")
            DispatchQueue.main.async {
                debugLog("FriendsListView appeared with \(allFriends.count) friends")
                stopMeasuring()
            }
        }
        #if DEBUG
        .measurePerformance(name: "FriendsListView-Render")
        #endif
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if viewModel.searchText.isEmpty && viewModel.selectedTags.isEmpty {
            ContentUnavailableView("No Friends Added", systemImage: "person.2.badge.plus")
                .foregroundColor(AppColors.label)
        } else {
            ContentUnavailableView("No Matches Found", systemImage: "magnifyingglass")
                .foregroundColor(AppColors.label)
        }
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

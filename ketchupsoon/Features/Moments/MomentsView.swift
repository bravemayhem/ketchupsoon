import SwiftUI
import SwiftData

struct MomentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Query milestones from SwiftData
    @Query private var milestones: [Milestone]
    
    @State private var selectedFilter: MomentFilter = .all
    @State private var showAddMomentSheet = false
    
    enum MomentFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case upcoming = "Upcoming"
        case recent = "Recent"
        
        var id: String { self.rawValue }
    }
    
    var filteredMilestones: [Milestone] {
        switch selectedFilter {
        case .all:
            return milestones
        case .upcoming:
            return milestones.filter { $0.isUpcoming }
        case .recent:
            return milestones.filter { $0.isRecent }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(MomentFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)
                
                if filteredMilestones.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "party.popper")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.secondaryLabel)
                            .padding(.bottom, 8)
                            .padding(.top, 40)
                        
                        Text("No \(selectedFilter.rawValue) Moments")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Create a moment to keep track of important events in your friends' lives.")
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredMilestones) { milestone in
                            MomentCard(milestone: milestone)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
                
                Spacer(minLength: 80)
            }
        }
        .navigationTitle("Moments")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddMomentSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(AppColors.label)
                }
            }
        }
        .sheet(isPresented: $showAddMomentSheet) {
            AddMomentView(onSave: { newMilestone in
                modelContext.insert(newMilestone)
                try? modelContext.save()
                showAddMomentSheet = false
            })
        }
        .background(AppColors.systemBackground)
    }
}

// Add Moment View
struct AddMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var friends: [Friend]
    
    let onSave: (Milestone) -> Void
    
    @State private var selectedFriendId: UUID?
    @State private var selectedType = MilestoneType.other
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("MOMENT DETAILS")) {
                    Picker("Friend", selection: $selectedFriendId) {
                        Text("Select a friend").tag(Optional<UUID>.none)
                        ForEach(friends) { friend in
                            Text(friend.name).tag(Optional(friend.id))
                        }
                    }
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(MilestoneType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .foregroundColor(type.color)
                                .tag(type)
                        }
                    }
                    
                    TextField("Title", text: $title)
                    
                    TextField("Description (optional)", text: $description)
                        .frame(height: 80)
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }
            }
            .navigationTitle("Add Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMoment()
                    }
                    .disabled(selectedFriendId == nil || title.isEmpty)
                }
            }
        }
    }
    
    private func saveMoment() {
        guard let friendId = selectedFriendId,
              let friend = friends.first(where: { $0.id == friendId }) else {
            return
        }
        
        let newMilestone = Milestone(
            friendId: friendId,
            friendName: friend.name,
            type: selectedType,
            title: title,
            milestoneDescription: description.isEmpty ? nil : description,
            date: date
        )
        
        // Add to the friend's milestones collection for the relationship
        friend.milestones.append(newMilestone)
        
        // Save the milestone (also handled by the onSave callback)
        onSave(newMilestone)
    }
}

#Preview {
    NavigationStack {
        MomentsView()
    }
} 
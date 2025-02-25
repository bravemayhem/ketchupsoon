/*
import SwiftUI
import Foundation

struct Poll: Identifiable {
    let id: String
    let title: String
    let createdAt: Date
    let expiresAt: Date
    let selectionType: SelectionType
    let responses: [PollResponse]
    let timeSlots: [TimeRange]
    
    var responseCount: Int {
        responses.count
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

struct PollResponse {
    let respondentName: String
    let respondentEmail: String
    let selectedSlots: [TimeRange]
    let responseDate: Date
}

@MainActor
class PollResponsesViewModel: ObservableObject {
    @Published var polls: [Poll] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedPoll: Poll?
    
    func fetchPolls() async {
        print("🔄 Starting to fetch polls")
        isLoading = true
        defer { isLoading = false }
        
        do {
            polls = try await SupabaseManager.shared.fetchUserPolls()
            print("📊 Fetched \(polls.count) polls")
            
            // Log details for each poll
            for (index, poll) in polls.enumerated() {
                print("\n📋 Poll \(index + 1):")
                print("   Title: \(poll.title)")
                print("   ID: \(poll.id)")
                print("   Type: \(poll.selectionType)")
                print("   Created: \(poll.createdAt)")
                print("   Expires: \(poll.expiresAt)")
                print("   Response count: \(poll.responseCount)")
                
                print("   🕒 Time slots (\(poll.timeSlots.count)):")
                for (slotIndex, slot) in poll.timeSlots.enumerated() {
                    print("      Slot \(slotIndex + 1): \(slot.formattedDate) \(slot.formattedTimeRange)")
                }
                
                print("   👥 Responses:")
                for (responseIndex, response) in poll.responses.enumerated() {
                    print("      Response \(responseIndex + 1):")
                    print("         From: \(response.respondentName) (\(response.respondentEmail))")
                    print("         Date: \(response.responseDate)")
                    print("         Selected slots (\(response.selectedSlots.count)):")
                    for (selectedSlotIndex, selectedSlot) in response.selectedSlots.enumerated() {
                        print("            Slot \(selectedSlotIndex + 1): \(selectedSlot.formattedDate) \(selectedSlot.formattedTimeRange)")
                    }
                }
            }
        } catch {
            print("❌ Error fetching polls: \(error)")
            self.error = error
        }
    }
}

struct PollResponsesView: View {
    @StateObject private var viewModel = PollResponsesViewModel()
    @State private var showingPollDetails = false
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.polls.isEmpty {
                Text("No polls created yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.polls) { poll in
                    Button {
                        print("📱 Selected poll: \(poll.title)")
                        viewModel.selectedPoll = poll
                        showingPollDetails = true
                    } label: {
                        PollRow(poll: poll)
                    }
                }
            }
        }
        .navigationTitle("Your Polls")
        .task {
            print("🚀 PollResponsesView appeared, fetching polls...")
            await viewModel.fetchPolls()
        }
        .sheet(isPresented: $showingPollDetails) {
            NavigationStack {
                if let poll = viewModel.selectedPoll {
                    PollDetailsView(poll: poll)
                }
            }
        }
        .refreshable {
            print("🔄 Manually refreshing polls...")
            await viewModel.fetchPolls()
        }
    }
}

struct PollRow: View {
    let poll: Poll
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(poll.title)
                .font(.headline)
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.secondary)
                Text("\(poll.responseCount) \(poll.responseCount == 1 ? "response" : "responses")")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: poll.selectionType == .oneOnOne ? "person.2.fill" : "person.3.fill")
                    .foregroundColor(.secondary)
                Text(poll.selectionType == .oneOnOne ? "1:1 Meeting" : "Group Poll")
                    .foregroundColor(.secondary)
                
                if poll.isExpired {
                    Spacer()
                    Text("Expired")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PollDetailsView: View {
    let poll: Poll
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    private var shareURL: URL? {
        let baseUrl = Bundle.main.infoDictionary?["SUPABASE_PROJECT_URL"] as? String ?? "https://friendtracker.app"
        return URL(string: "\(baseUrl)/schedule/\(poll.id)")
    }
    
    var body: some View {
        List {
            Section {
                Text(poll.title)
                    .font(.headline)
                
                HStack {
                    Image(systemName: poll.selectionType == .oneOnOne ? "person.2.fill" : "person.3.fill")
                        .foregroundColor(.secondary)
                    Text(poll.selectionType == .oneOnOne ? "1:1 Meeting" : "Group Poll")
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    if shareURL != nil {
                        print("🔗 Sharing poll URL: \(String(describing: shareURL))")
                        showingShareSheet = true
                    }
                }) {
                    HStack {
                        Text("Share Poll Link")
                            .foregroundColor(AppColors.accent)
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppColors.accent)
                    }
                }
            } header: {
                Text("Poll Details")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Section {
                ForEach(poll.timeSlots) { slot in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(slot.formattedDate)
                            .font(.headline)
                        Text(slot.formattedTimeRange)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Available Times")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Section {
                if poll.responses.isEmpty {
                    Text("No responses yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(poll.responses, id: \.respondentEmail) { response in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(response.respondentName)
                                    .font(.headline)
                                Spacer()
                                Text(response.responseDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(response.respondentEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !response.selectedSlots.isEmpty {
                                Text("Selected Times:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                
                                ForEach(poll.timeSlots) { slot in
                                    let isSelected = response.selectedSlots.contains { $0.startSlot.date == slot.startSlot.date && 
                                                                                     $0.startSlot.hour == slot.startSlot.hour && 
                                                                                     $0.startSlot.minute == slot.startSlot.minute }
                                    HStack(spacing: 4) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isSelected ? AppColors.accent : .secondary)
                                            .font(.system(size: 14))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(slot.formattedDate)
                                                .font(.subheadline)
                                            Text(slot.formattedTimeRange)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if response.respondentEmail != poll.responses.last?.respondentEmail {
                            Divider()
                        }
                    }
                }
            } header: {
                Text("Responses")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .navigationTitle("Poll Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    print("👋 Dismissing poll details")
                    dismiss()
                }
                .foregroundColor(AppColors.accent)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            print("\n📊 Showing poll details:")
            print("   Title: \(poll.title)")
            print("   ID: \(poll.id)")
            print("   Type: \(poll.selectionType)")
            print("   Time slots (\(poll.timeSlots.count)):")
            poll.timeSlots.forEach { slot in
                print("      \(slot.formattedDate) \(slot.formattedTimeRange)")
            }
            print("   Responses (\(poll.responses.count)):")
            poll.responses.forEach { response in
                print("      From: \(response.respondentName)")
                print("      Selected slots: \(response.selectedSlots.count)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        PollResponsesView()
    }
} 
*/

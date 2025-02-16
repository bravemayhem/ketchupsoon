import SwiftUI

struct PollResponse {
    let respondentName: String
    let respondentEmail: String
    let selectedSlots: [TimeRange]
    let responseDate: Date
}

struct TimeSlotResponse {
    let timeRange: TimeRange
    let respondents: [PollResponse]
    
    var respondentCount: Int {
        respondents.count
    }
}

@MainActor
class PollResponsesViewModel: ObservableObject {
    @Published var responses: [TimeSlotResponse] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var connectionStatus: String = "Not tested"
    
    let eventName: String
    let selectionType: SelectionType
    
    init(eventName: String, selectionType: SelectionType) {
        self.eventName = eventName
        self.selectionType = selectionType
    }
    
    func testSupabaseConnection() async {
        isLoading = true
        connectionStatus = "Testing..."
        
        do {
            let success = try await SupabaseManager.shared.testConnection()
            connectionStatus = success ? "✅ Connected to Supabase" : "❌ Connection failed"
            if success {
                // If connected successfully, fetch responses
                await fetchResponses()
            }
        } catch {
            connectionStatus = "❌ Error: \(error.localizedDescription)"
            self.error = error
        }
        
        isLoading = false
    }
    
    func fetchResponses() async {
        isLoading = true
        
        do {
            let fetchedResponses = try await SupabaseManager.shared.fetchPollResponses(eventId: eventName)
            
            // Group responses by time slot
            var slotResponses: [String: [PollResponse]] = [:]
            for response in fetchedResponses {
                for slot in response.selectedSlots {
                    let key = "\(slot.start.ISO8601Format())_\(slot.end.ISO8601Format())"
                    slotResponses[key, default: []].append(response)
                }
            }
            
            // Convert to TimeSlotResponse array
            responses = slotResponses.map { key, responses in
                let parts = key.split(separator: "_")
                let start = ISO8601DateFormatter().date(from: String(parts[0]))!
                let end = ISO8601DateFormatter().date(from: String(parts[1]))!
                return TimeSlotResponse(
                    timeRange: TimeRange(start: start, end: end),
                    respondents: responses
                )
            }
            
            connectionStatus = "✅ Fetched \(responses.count) time slots with responses"
        } catch {
            self.error = error
            connectionStatus = "❌ Error fetching responses: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct PollResponsesView: View {
    @StateObject private var viewModel: PollResponsesViewModel
    
    init(eventName: String, selectionType: SelectionType) {
        _viewModel = StateObject(wrappedValue: PollResponsesViewModel(eventName: eventName, selectionType: selectionType))
    }
    
    var body: some View {
        List {
            Section {
                Text(viewModel.eventName)
                    .font(.headline)
            } header: {
                Text("Event")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Section {
                Text(viewModel.connectionStatus)
                    .foregroundColor(viewModel.connectionStatus.contains("✅") ? .green : .red)
                
                Button(action: {
                    Task {
                        await viewModel.testSupabaseConnection()
                    }
                }) {
                    Text("Refresh Responses")
                }
                .disabled(viewModel.isLoading)
            } header: {
                Text("Status")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Section {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.responses.isEmpty {
                    Text("No responses yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.responses, id: \.timeRange.id) { response in
                        TimeSlotResponseRow(response: response)
                    }
                }
            } header: {
                Text("Responses")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .navigationTitle("Poll Responses")
        .task {
            await viewModel.testSupabaseConnection()
        }
    }
}

struct TimeSlotResponseRow: View {
    let response: TimeSlotResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(response.timeRange.formattedDate)
                .font(.headline)
            Text(response.timeRange.formattedTimeRange)
                .font(.subheadline)
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.secondary)
                Text("\(response.respondentCount) \(response.respondentCount == 1 ? "response" : "responses")")
                    .foregroundColor(.secondary)
            }
            
            if !response.respondents.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(response.respondents, id: \.respondentEmail) { respondent in
                        Text(respondent.respondentName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PollResponsesView(eventName: "Team Meeting", selectionType: .poll)
    }
} 
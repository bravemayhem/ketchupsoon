import SwiftUI

struct SchedulerView: View {
    @State private var selectedFriend: Friend?
    @State private var activities = SampleData.activities
    
    // Default initializer
    init() {
        self._selectedFriend = State(initialValue: nil)
    }
    
    // Custom initializer for pre-selected friend
    init(selectedFriend: Friend) {
        self._selectedFriend = State(initialValue: selectedFriend)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Friend selector
                VStack(alignment: .leading) {
                    Text("Select a Friend")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SampleData.friends) { friend in
                                Button {
                                    selectedFriend = friend
                                } label: {
                                    Text(friend.name)
                                        .padding()
                                        .background(selectedFriend?.id == friend.id ? Color.blue : Color(.systemGray6))
                                        .foregroundColor(selectedFriend?.id == friend.id ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Activity suggestions
                VStack(alignment: .leading) {
                    Text("Suggested Activities")
                        .font(.headline)
                    
                    ForEach(activities) { activity in
                        HStack {
                            Image(systemName: activity.category.icon)
                                .foregroundColor(.blue)
                            Text(activity.title)
                            Spacer()
                            Text("\(Int(activity.duration/3600))h")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Schedule Hangout")
        }
    }
}

#Preview {
    SchedulerView()
} 
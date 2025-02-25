/*
import SwiftUI

struct FindTimeOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFindTime = false
    @State private var showingPollResponses = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showingFindTime = true
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(AppColors.accent)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading) {
                                Text("Share Availability")
                                    .foregroundColor(.primary)
                                Text("Select times you're free to meet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 4)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    
                    Button(action: {
                        showingPollResponses = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(AppColors.accent)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading) {
                                Text("View Poll Responses")
                                    .foregroundColor(.primary)
                                Text("See who's responded to your polls")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 4)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
            }
            .navigationTitle("Find a Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .sheet(isPresented: $showingFindTime, onDismiss: {
            dismiss()
        }) {
            FindTimeView()
        }
        .sheet(isPresented: $showingPollResponses, onDismiss: {
            dismiss()
        }) {
            NavigationStack {
                PollResponsesView()
            }
        }
    }
}

#Preview {
    FindTimeOptionsView()
} 
*/

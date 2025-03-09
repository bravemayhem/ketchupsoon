import SwiftUI
import FirebaseAuth

struct PreferencesEditView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager.shared
    
    // Availability times selection
    @State private var selectedTimes: Set<String> = []
    private let availableTimeOptions = ["mornings", "evenings", "weekends"]
    
    // Days selection
    @State private var selectedDays: Set<String> = []
    private let dayOptions = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    // Favorite activities selection
    @State private var selectedActivities: Set<String> = []
    private let activityOptions = ["coffee", "food", "outdoors", "games", "local events", "concerts", "other"]
    
    // Calendar connection
    @State private var isGoogleCalendarConnected: Bool = false
    
    // Loading and alert states
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = "Preferences"
    @State private var alertMessage = ""
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Calendar Connection Section
                calendarConnectionSection
                
                // Availability Section
                availabilitySection
                
                // Favorite Activities Section
                favoriteActivitiesSection
                
                // Save Button
                saveButton
            }
            .padding(.horizontal)
        }
        .background(Color(red: 15/255, green: 11/255, blue: 36/255))
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserPreferences()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Calendar Connection Section
    private var calendarConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("calendar connection")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 28/255, green: 21/255, blue: 54/255))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                HStack {
                    // Google Calendar icon
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 36, height: 36)
                        
                        Text("G")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    .padding(.trailing, 8)
                    
                    Text("Google Calendar")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    
                    Spacer()
                    
                    // Connect button
                    Button(action: {
                        toggleGoogleCalendarConnection()
                    }) {
                        Text(isGoogleCalendarConnected ? "connected" : "connect")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 140/255, green: 69/255, blue: 250/255),
                                        Color(red: 235/255, green: 78/255, blue: 131/255)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Availability Section
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("when are you available?")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 28/255, green: 21/255, blue: 54/255))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                VStack(spacing: 20) {
                    // Time of day selection
                    HStack(spacing: 10) {
                        ForEach(availableTimeOptions, id: \.self) { time in
                            TimeOptionButton(
                                title: time,
                                isSelected: selectedTimes.contains(time),
                                action: {
                                    toggleTimeSelection(time)
                                }
                            )
                        }
                    }
                    
                    // Day selection
                    HStack(spacing: 8) {
                        ForEach(dayOptions, id: \.self) { day in
                            DayOptionButton(
                                title: day,
                                isSelected: selectedDays.contains(day),
                                action: {
                                    toggleDaySelection(day)
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Favorite Activities Section
    private var favoriteActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("favorite activities")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 28/255, green: 21/255, blue: 54/255))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Activity selection
                HStack(spacing: 10) {
                    ForEach(activityOptions, id: \.self) { activity in
                        ActivityOptionButton(
                            title: activity,
                            isSelected: selectedActivities.contains(activity),
                            action: {
                                toggleActivitySelection(activity)
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            savePreferences()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 140/255, green: 69/255, blue: 250/255),
                                Color(red: 235/255, green: 78/255, blue: 131/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 60)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("save preferences")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }
        .padding(.top, 16)
        .disabled(isLoading)
    }
    
    // MARK: - Helper Methods
    private func loadUserPreferences() {
        guard let currentProfile = profileManager.currentUserProfile else { return }
        
        // Load availability times
        if let times = currentProfile.availabilityTimes {
            selectedTimes = Set(times)
        }
        
        // Load available days
        if let days = currentProfile.availableDays {
            selectedDays = Set(days)
        }
        
        // Load favorite activities
        if let activities = currentProfile.favoriteActivities {
            selectedActivities = Set(activities)
        }
        
        // Load calendar connection status
        if let connections = currentProfile.calendarConnections {
            isGoogleCalendarConnected = connections.contains("Google")
        }
    }
    
    private func toggleTimeSelection(_ time: String) {
        if selectedTimes.contains(time) {
            selectedTimes.remove(time)
        } else {
            selectedTimes.insert(time)
        }
    }
    
    private func toggleDaySelection(_ day: String) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private func toggleActivitySelection(_ activity: String) {
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }
    
    private func toggleGoogleCalendarConnection() {
        // In a real implementation, this would initiate OAuth for Google Calendar
        // For now, we'll just toggle the state
        isGoogleCalendarConnected.toggle()
    }
    
    private func savePreferences() {
        isLoading = true
        
        // Create updates dictionary
        var updates: [String: Any] = [
            "availabilityTimes": Array(selectedTimes),
            "availableDays": Array(selectedDays),
            "favoriteActivities": Array(selectedActivities)
        ]
        
        // Add calendar connections if connected
        if isGoogleCalendarConnected {
            updates["calendarConnections"] = ["Google"]
        } else {
            updates["calendarConnections"] = []
        }
        
        // Save to Firestore via UserProfileManager
        Task {
            do {
                try await profileManager.updateUserProfile(updates: updates)
                
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Success"
                    alertMessage = "Your preferences have been saved."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to save preferences: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Helper Views
struct TimeOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 140/255, green: 69/255, blue: 250/255),
                                Color(red: 140/255, green: 69/255, blue: 250/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(red: 37/255, green: 29/255, blue: 69/255)
                    }
                }
                .cornerRadius(25)
        }
    }
}

struct DayOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 40, height: 40)
                .background {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 140/255, green: 69/255, blue: 250/255),
                                Color(red: 140/255, green: 69/255, blue: 250/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(red: 37/255, green: 29/255, blue: 69/255)
                    }
                }
                .cornerRadius(20)
        }
    }
}

struct ActivityOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 255/255, green: 68/255, blue: 94/255),
                                Color(red: 255/255, green: 68/255, blue: 94/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(red: 37/255, green: 29/255, blue: 69/255)
                    }
                }
                .cornerRadius(25)
        }
    }
}

// MARK: - Preview
struct PreferencesEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PreferencesEditView()
        }
        .preferredColorScheme(.dark)
    }
} 

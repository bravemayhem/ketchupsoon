import SwiftUI

// MARK: - Friend Section
struct FriendSection: View {
    let friendName: String
    
    var body: some View {
        Section("Friend") {
            Text(friendName)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Email Recipients Section
struct EmailRecipientsSection: View {
    @ObservedObject var viewModel: CreateHangoutViewModel
    
    var body: some View {
        Section("Email Recipients") {
            ForEach(viewModel.emailRecipients, id: \.self) { email in
                HStack {
                    Text(email)
                    Spacer()
                    Button(action: {
                        viewModel.removeEmailRecipient(email)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            HStack {
                TextField("Add email", text: $viewModel.newEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button(action: {
                    if !viewModel.newEmail.isEmpty && viewModel.newEmail.contains("@") {
                        viewModel.addEmailRecipient(viewModel.newEmail)
                        viewModel.newEmail = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Date Time Section
struct DateTimeSection: View {
    @ObservedObject var viewModel: CreateHangoutViewModel
    @StateObject private var calendarManager = CalendarManager.shared
    @AppStorage("defaultCalendarType") private var defaultCalendarType: Friend.CalendarType = .apple
    
    var body: some View {
        Section("Date & Time") {
            DatePicker(
                "Date",
                selection: $viewModel.selectedDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            
            Picker("Calendar", selection: $viewModel.selectedCalendarType) {
                Text("Apple Calendar").tag(CalendarManager.CalendarType.apple)
                Text("Google Calendar").tag(CalendarManager.CalendarType.google)
            }
            .onChange(of: viewModel.selectedCalendarType) { _, newType in
                defaultCalendarType = newType == .apple ? .apple : .google
            }
            
            if viewModel.selectedCalendarType == .google {
                if calendarManager.isGoogleAuthorized {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        if let email = calendarManager.googleUserEmail {
                            Text(email)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Button(action: {
                        Task {
                            do {
                                try await calendarManager.requestGoogleAccess()
                            } catch {
                                viewModel.errorMessage = "Failed to connect: \(error.localizedDescription)"
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .foregroundColor(.blue)
                            Text("Sign in with Google")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                }
            } else if viewModel.selectedCalendarType == .apple && calendarManager.isAuthorized {
                if let email = calendarManager.appleUserEmail {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        Text(email)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let duration = viewModel.selectedDuration {
                HStack {
                    Text("Duration")
                    Spacer()
                    Button(viewModel.formatDuration(duration)) {
                        viewModel.showingCustomDurationInput = true
                    }
                    .foregroundColor(.blue)
                }
            } else {
                Button("Set Duration (Optional)") {
                    viewModel.showingCustomDurationInput = true
                }
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Schedule Button Section
struct ScheduleButtonSection: View {
    @ObservedObject var viewModel: CreateHangoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Section {
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
                    .padding(.bottom, 8)
            }
            
            Button {
                Task {
                    await viewModel.scheduleHangout()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                } else {
                    Text("Schedule Hangout")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.isScheduleButtonDisabled ? Color.gray : Color.blue)
            )
            .disabled(viewModel.isScheduleButtonDisabled || viewModel.isLoading)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
} 
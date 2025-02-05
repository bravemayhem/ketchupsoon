//
//  AdditionalManualAttendeesSection.swift
//  friendtracker
//
//  Created by Amineh Beltran on 2/5/25.
//

import SwiftUI
import SwiftData

// MARK: - AdditionalManualAttendeesSection
struct AdditionalManualAttendeesSection: View {
    @ObservedObject var viewModel: CreateHangoutViewModel
    
    var body: some View {
        Section {
            ForEach(viewModel.manualAttendees) { attendee in
                HStack {
                    VStack(alignment: .leading) {
                        Text(attendee.name)
                        Text(attendee.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        viewModel.removeManualAttendee(attendee)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            VStack {
                TextField("Name", text: $viewModel.newManualAttendeeName)
                    .textContentType(.name)
                
                HStack {
                    TextField("Email", text: $viewModel.newManualAttendeeEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        viewModel.addManualAttendee(
                            name: viewModel.newManualAttendeeName,
                            email: viewModel.newManualAttendeeEmail
                        )
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.newManualAttendeeName.isEmpty || 
                            !viewModel.newManualAttendeeEmail.contains("@"))
                }
            }
        } header: {
            Text("Additional Attendees")
        } footer: {
            Text("Add people who aren't using KetchupSoon yet")
        }
    }
}

#Preview("Additional Attendees") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    
    // Add a sample manual attendee
    let attendee = ManualAttendee(name: "Bob Wilson", email: "bob@example.com")
    viewModel.manualAttendees = [attendee]
    
    return Form {
        AdditionalManualAttendeesSection(viewModel: viewModel)
    }
}

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $name)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.name)
                        .onChange(of: name) { _, newValue in
                            userSettings.updateName(newValue.isEmpty ? nil : newValue)
                        }
                }
                
                HStack {
                    Text("Phone")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $phoneNumber)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .onChange(of: phoneNumber) { _, newValue in
                            userSettings.updatePhoneNumber(newValue.isEmpty ? nil : newValue)
                        }
                }
                
                HStack {
                    Text("Email")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $email)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: email) { _, newValue in
                            userSettings.updateEmail(newValue.isEmpty ? nil : newValue)
                        }
                }
            } header: {
                Text("PROFILE INFORMATION")
            } footer: {
                Text("Your phone number is required to create hangouts. This helps your friends identify you when they receive invites.")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Load existing values
            name = userSettings.name ?? ""
            phoneNumber = userSettings.phoneNumber ?? ""
            email = userSettings.email ?? ""
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
} 
import SwiftUI
import SwiftData
import ContactsUI


// MARK: - Friend Details Section for Onboarding
struct FriendOnboardingDetailsSection: View {
    let isFromContacts: Bool
    let contact: FriendDetail.NewFriendInput?
    @Binding var manualName: String
    @Binding var phoneNumber: String
    @Binding var email: String
    @Bindable var cityService: CitySearchService
    @State private var showingContactView = false
    
    var body: some View {
        Section("Friend Details") {
            if !isFromContacts {
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $manualName)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                }
                
                HStack {
                    Text("Phone")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $phoneNumber)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                }
                
                HStack {
                    Text("Email")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $email)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                }
            } else if let contact = contact {
                if contact.identifier != nil {
                    Button {
                        showingContactView = true
                    } label: {
                        HStack {
                            Text("Name")
                                .foregroundColor(AppColors.label)
                            Spacer()
                            Text(contact.name)
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    
                    if let phone = contact.phoneNumber {
                        Button {
                            showingContactView = true
                        } label: {
                            HStack {
                                Text("Phone")
                                    .foregroundColor(AppColors.label)
                                Spacer()
                                Text(phone)
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    
                    if let email = contact.email {
                        Button {
                            showingContactView = true
                        } label: {
                            HStack {
                                Text("Email")
                                    .foregroundColor(AppColors.label)
                                Spacer()
                                Text(email)
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                }
            }
            
            CitySearchField(service: cityService)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}






// MARK: - PREVIEW SECTION



#Preview("FriendOnboardingDetailsSection") {
    NavigationStack {
        List {
            // Contact Import Scenario
            FriendOnboardingDetailsSection(
                isFromContacts: true,
                contact: FriendDetail.NewFriendInput(
                    name: "John Smith",
                    identifier: "123",
                    phoneNumber: "(555) 123-4567",
                    email: "john.smith@email.com",
                    imageData: nil,
                    city: "San Francisco"
                ),
                manualName: .constant(""),
                phoneNumber: .constant(""),
                email: .constant(""),
                cityService: CitySearchService()
            )
            
            // Manual Entry Scenario
            FriendOnboardingDetailsSection(
                isFromContacts: false,
                contact: nil,
                manualName: .constant("Jane Doe"),
                phoneNumber: .constant("(555) 987-6543"),
                email: .constant(""),
                cityService: {
                    let service = CitySearchService()
                    service.selectedCity = "New York"
                    return service
                }()
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}


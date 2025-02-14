import SwiftUI
import ContactsUI
import EventKit
import UserNotifications

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var notificationsManager = NotificationsManager.shared
    @StateObject private var contactsManager = ContactsManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var phoneNumber = ""
    @State private var name = ""
    @State private var currentPage = 0
    @State private var showingPermissionsError = false
    @State private var permissionsErrorMessage = ""
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to Ketchup Soon",
            description: "Keep track of your friends and never lose touch",
            imageName: "person.2.fill",
            backgroundColor: AppColors.accent
        ),
        OnboardingPage(
            title: "Keep your running social to-do list in one place",
            description: "Prioritize over-due connections by adding friends to your wish list",
            imageName: "person.fill.checkmark",
            backgroundColor: AppColors.accent
        ),
        OnboardingPage(
            title: "Never forget to reach out again",
            description: "Set frequency reminders and we'll send you push notifications as a gentle nudge",
            imageName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90",
            backgroundColor: AppColors.accent
        ),
        OnboardingPage(
            title: "Schedule hang-outs straight from the app",
            description: "Faciliate the scheduling and coordination of your hang out straight from the app",
            imageName: "calendar",
            backgroundColor: AppColors.accent
        )
    ]
    
    private var permissionsView: some View {
        PermissionsSetupView(
            notificationsStatus: notificationsManager.authorizationStatus,
            contactsStatus: contactsManager.authorizationStatus,
            calendarStatus: calendarManager.isAuthorized,
            onRequestNotifications: {
                Task {
                    try? await notificationsManager.requestAuthorization()
                }
            },
            onRequestContacts: {
                Task {
                    _ = await contactsManager.requestAccess()
                }
            },
            onRequestCalendar: {
                Task {
                    _ = await calendarManager.requestAccess()
                }
            }
        )
    }
    
    private var isProfileValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phoneNumber.filter { $0.isNumber }.count == 10
    }
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Feature introduction pages
            OnboardingPageView(page: pages[0])
                .tag(0)
            
            OnboardingPageView(page: pages[1])
                .tag(1)
            
            OnboardingPageView(page: pages[2])
                .tag(2)
            
            OnboardingPageView(page: pages[3])
                .tag(3)
            
            // Profile setup view
            ProfileSetupView(name: $name, phoneNumber: $phoneNumber)
                .tag(pages.count)
            
            // Permissions setup view
            permissionsView
                .tag(pages.count + 1)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay(alignment: .bottom) {
            if currentPage >= pages.count {
                Button(action: handleNextStep) {
                    Text(currentPage == pages.count + 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (currentPage == pages.count && !isProfileValid) 
                                ? AppColors.secondaryLabel 
                                : AppColors.accent
                        )
                        .cornerRadius(10)
                }
                .disabled(currentPage == pages.count && !isProfileValid)
                .padding()
            }
        }
        .alert("Permissions Required", isPresented: $showingPermissionsError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(permissionsErrorMessage)
        }
    }
    
    private func handleNextStep() {
        if currentPage == pages.count {
            // Save profile information
            userSettings.updateName(name)
            userSettings.updatePhoneNumber(phoneNumber)
            currentPage += 1
        } else if currentPage == pages.count + 1 {
            // Complete onboarding
            onboardingManager.completeOnboarding()
            dismiss()
        }
    }
}

struct ProfileSetupView: View {
    @Binding var name: String
    @Binding var phoneNumber: String
    @State private var formattedPhoneNumber = ""
    
    private func formatPhoneNumber(_ input: String) -> String {
        // Remove any non-numeric characters
        let cleaned = input.filter { $0.isNumber }
        
        // Format the number as (XXX) XXX-XXXX
        var result = ""
        for (index, char) in cleaned.enumerated() {
            if index == 0 {
                result += "("
            }
            if index == 3 {
                result += ") "
            }
            if index == 6 {
                result += "-"
            }
            if index < 10 { // Only allow up to 10 digits
                result.append(char)
            }
        }
        return result
    }
    
    private var isValidPhoneNumber: Bool {
        let cleaned = phoneNumber.filter { $0.isNumber }
        return cleaned.count == 10
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppColors.accent)
                    .padding(.top, 60)
                
                Text("Set Up Your Profile")
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text("This information helps your friends identify you when coordinating hangouts")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TextField("Your Name", text: $name)
                        .textContentType(.name)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(AppColors.secondarySystemBackground)
                        .cornerRadius(10)
                    
                    TextField("(555) 555-5555", text: $formattedPhoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(AppColors.secondarySystemBackground)
                        .cornerRadius(10)
                        .onChange(of: formattedPhoneNumber) { _, newValue in
                            let formatted = formatPhoneNumber(newValue)
                            if formatted != newValue {
                                formattedPhoneNumber = formatted
                            }
                            // Update the actual phone number with just the digits
                            phoneNumber = newValue.filter { $0.isNumber }
                        }
                }
                .padding(.horizontal)
                
                if !phoneNumber.isEmpty && !isValidPhoneNumber {
                    Text("Please enter a valid 10-digit phone number")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer(minLength: 200) // Add extra space at bottom for keyboard
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct PermissionsSetupView: View {
    let notificationsStatus: UNAuthorizationStatus
    let contactsStatus: CNAuthorizationStatus
    let calendarStatus: Bool
    let onRequestNotifications: () -> Void
    let onRequestContacts: () -> Void
    let onRequestCalendar: () -> Void
    
    private var isCalendarAuthorized: Bool {
        calendarStatus
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "gear.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppColors.accent)
                    .padding(.top, 60)
                
                Text("Enable Features")
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text("Get the most out of Ketchup Soon by enabling these features")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 24) {
                    PermissionButton(
                        title: "Push Notifications",
                        description: "Get reminders about upcoming hangouts",
                        iconName: "bell.badge.fill",
                        status: notificationsStatus == .authorized,
                        action: onRequestNotifications
                    )
                    
                    PermissionButton(
                        title: "Contacts Access",
                        description: "Easily add friends from your contacts",
                        iconName: "person.crop.circle.fill.badge.plus",
                        status: contactsStatus == .authorized,
                        action: onRequestContacts
                    )
                    
                    PermissionButton(
                        title: "Calendar Access",
                        description: "Sync hangouts with your calendar",
                        iconName: "calendar.badge.plus",
                        status: isCalendarAuthorized,
                        action: onRequestCalendar
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 200) // Add extra space at bottom for keyboard
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct PermissionButton: View {
    let title: String
    let description: String
    let iconName: String
    let status: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppColors.label)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryLabel)
                }
                
                Spacer()
                
                Image(systemName: status ? "checkmark.circle.fill" : "chevron.right.circle.fill")
                    .foregroundColor(status ? .green : AppColors.accent)
            }
            .padding()
            .background(AppColors.secondarySystemBackground)
            .cornerRadius(10)
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: page.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(page.backgroundColor)
                .padding(.top, 60)
            
            Text(page.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
} 

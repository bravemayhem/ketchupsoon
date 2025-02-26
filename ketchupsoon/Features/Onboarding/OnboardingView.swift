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
    @State private var permissionsRefreshToggle = false
    
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
            onRequestNotifications: {
                Task {
                    print("🔔 OnboardingView: Requesting notification permission...")
                    print("🔔 OnboardingView: Current status before request: \(notificationsManager.authorizationStatus.rawValue)")
                    do {
                        try await notificationsManager.requestAuthorization()
                        print("🔔 OnboardingView: Permission request completed")
                        print("🔔 OnboardingView: New status: \(notificationsManager.authorizationStatus.rawValue)")
                    } catch {
                        print("🔔 OnboardingView: Error requesting permission: \(error)")
                    }
                }
            },
            onRequestContacts: {
                Task {
                    _ = await contactsManager.requestAccess()
                }
            }
        )
    }
    
    private var calendarIntegrationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.accent)
                .padding(.top, 60)
            
            Text("Connect Your Calendars")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Choose which calendars to use for scheduling hangouts")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Text("Note: Calendar invites with attendee notifications are only supported with Google Calendar at this time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 24) {
                // Google Calendar Permission Button (Now First)
                PermissionButton(
                    title: "Google Calendar",
                    description: "Sync hangouts and send calendar invites to friends",
                    iconName: "calendar.badge.plus",
                    status: calendarManager.isGoogleAuthorized,
                    action: {
                        Task {
                            if !calendarManager.isGoogleAuthorized {
                                try? await calendarManager.requestGoogleAccess(from: (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController ?? UIViewController())
                                if calendarManager.isGoogleAuthorized {
                                    // Set as default calendar when authorized
                                    UserDefaults.standard.set(Friend.CalendarType.google.rawValue, forKey: "defaultCalendarType")
                                    calendarManager.selectedCalendarType = .google
                                }
                            }
                        }
                    }
                )
                
                // Apple Calendar Permission Button (Now Second)
                PermissionButton(
                    title: "Apple Calendar",
                    description: "Sync hangouts with your personal calendar",
                    iconName: "calendar",
                    status: calendarManager.isAuthorized,
                    action: {
                        Task {
                            print("📅 Apple Calendar button tapped - current authorization: \(calendarManager.isAuthorized)")
                            if !calendarManager.isAuthorized {
                                print("📅 Requesting Apple Calendar access...")
                                
                                // Show a temporary alert to inform the user
                                await MainActor.run {
                                    let alertController = UIAlertController(
                                        title: "Calendar Access",
                                        message: "Please allow access to your calendar when prompted",
                                        preferredStyle: .alert
                                    )
                                    // Add a short timer to dismiss the alert
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        alertController.dismiss(animated: true) {
                                            // Request access after alert is dismissed
                                            Task {
                                                await calendarManager.requestAccess()
                                                print("📅 Apple Calendar access request completed - authorized: \(calendarManager.isAuthorized)")
                                                
                                                // Update UI after permission request
                                                if calendarManager.isAuthorized {
                                                    print("📅 Apple Calendar authorized - updating defaults")
                                                    // Set as default calendar if no other calendar is authorized
                                                    if !calendarManager.isGoogleAuthorized {
                                                        UserDefaults.standard.set(Friend.CalendarType.apple.rawValue, forKey: "defaultCalendarType")
                                                        calendarManager.selectedCalendarType = .apple
                                                    }
                                                } else {
                                                    print("📅 Apple Calendar not authorized")
                                                }
                                            }
                                        }
                                    }
                                    // Present the alert
                                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                                    let window = windowScene?.windows.first
                                    window?.rootViewController?.present(alertController, animated: true)
                                }
                            } else {
                                print("📅 Apple Calendar already authorized")
                            }
                        }
                    }
                )
            }
            .padding(.horizontal)
            
            if calendarManager.isAuthorized || calendarManager.isGoogleAuthorized {
                VStack(spacing: 12) {
                    Text("Default Calendar")
                        .font(.headline)
                    
                    Picker("Default Calendar", selection: Binding(
                        get: {
                            let defaultType = UserDefaults.standard.string(forKey: "defaultCalendarType") ?? "apple"
                            return defaultType == "google" ? Friend.CalendarType.google : Friend.CalendarType.apple
                        },
                        set: { newValue in
                            print("Selected calendar type in Picker: \(newValue)")
                            UserDefaults.standard.set(newValue.rawValue, forKey: "defaultCalendarType")
                            Task {
                                await MainActor.run {
                                    calendarManager.selectedCalendarType = newValue == .google ? .google : .apple
                                }
                            }
                        }
                    )) {
                        if calendarManager.isGoogleAuthorized {
                            Text("Google Calendar").tag(Friend.CalendarType.google)
                        }
                        if calendarManager.isAuthorized {
                            Text("Apple Calendar").tag(Friend.CalendarType.apple)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    Text("This calendar will be used for sending hangout invites")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                Text("✓ Calendar setup complete!")
                    .foregroundColor(.green)
                    .padding(.top)
            } else {
                Text("Connect at least one calendar to get started")
                    .foregroundColor(.secondary)
                    .padding(.top)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Only refresh calendar status when this view appears
            print("📅 Calendar Integration View appeared - checking authorization status")
            Task {
                await calendarManager.refreshAuthorizationStatus()
            }
        }
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
            
            // Calendar integration view
            calendarIntegrationView
                .tag(pages.count + 2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onChange(of: currentPage) { oldValue, newValue in
            // Check if we're moving to the calendar integration page
            if newValue == pages.count + 2 {
                print("📅 Moving to Calendar Integration Page")
                Task {
                    await calendarManager.refreshAuthorizationStatus()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if currentPage >= pages.count {
                Button(action: handleNextStep) {
                    Text(currentPage == pages.count + 2 ? "Get Started" : "Next")
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
            // Save profile information and dismiss keyboard
            userSettings.updateName(name)
            userSettings.updatePhoneNumber(phoneNumber)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            currentPage += 1
        } else if currentPage == pages.count + 1 {
            // Move to calendar integration
            currentPage += 1
        } else if currentPage == pages.count + 2 {
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
    // Use StateObject to directly observe the managers
    @StateObject private var notificationsManager = NotificationsManager.shared
    @StateObject private var contactsManager = ContactsManager.shared
    
    // Add explicit state variables to track permission status
    @State private var notificationPermissionGranted = false
    @State private var contactsPermissionGranted = false
    
    // Keep the action closures
    let onRequestNotifications: () -> Void
    let onRequestContacts: () -> Void
    
    init(onRequestNotifications: @escaping () -> Void, onRequestContacts: @escaping () -> Void) {
        self.onRequestNotifications = onRequestNotifications
        self.onRequestContacts = onRequestContacts
        
        // IMPORTANT: iOS Authorization Status Fix
        // There appears to be a mismatch between the UNAuthorizationStatus.authorized enum value (2)
        // and what the system actually returns for authorized status (3).
        // This may be due to API version differences or iOS updates.
        // We use the raw value 3 directly to check authorization instead of the enum comparison.
        let initialNotificationStatus = NotificationsManager.shared.authorizationStatus
        let isAuthorized = initialNotificationStatus.rawValue == 3
        
        // Initialize state variables accurately based on current status
        _notificationPermissionGranted = State(initialValue: isAuthorized)
        _contactsPermissionGranted = State(initialValue: ContactsManager.shared.authorizationStatus == .authorized)
        
        print("🔔🔔 PERMISSIONS SETUP VIEW INITIAL STATE: notificationPermissionGranted = \(isAuthorized)")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
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
                    title: "Notifications",
                    description: "Get reminders about upcoming hangouts",
                    iconName: "bell.badge.fill",
                    status: notificationPermissionGranted,
                    action: {
                        onRequestNotifications()
                        // After requesting, update our state after a short delay
                        Task {
                            // Wait a moment for the permission to be processed
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            await updatePermissionStates()
                        }
                    }
                )
                
                PermissionButton(
                    title: "Contacts Access",
                    description: "Easily add friends from your contacts",
                    iconName: "person.crop.circle.fill.badge.plus",
                    status: contactsPermissionGranted,
                    action: {
                        onRequestContacts()
                        // After requesting, update our state after a short delay
                        Task {
                            // Wait a moment for the permission to be processed
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            await updatePermissionStates()
                        }
                    }
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Update permission states when the view appears with a small delay
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await updatePermissionStates()
            }
        }
    }
    
    // Helper function to update the permission states
    @MainActor
    private func updatePermissionStates() async {
        // Refresh statuses
        await notificationsManager.refreshAuthorizationStatus()
        _ = await contactsManager.requestAccess()
        
        // Add a small delay before updating state to ensure values are settled
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // Update our state variables to trigger UI refresh
        let notificationStatus = notificationsManager.authorizationStatus
        let contactsStatus = contactsManager.authorizationStatus
        
        // Using raw value 3 for authorized status (see comment in init)
        let newNotificationStatus = notificationStatus.rawValue == 3
        let newContactsStatus = contactsStatus == .authorized
        
        // Only update state if there's a change to avoid unnecessary renders
        if newNotificationStatus != notificationPermissionGranted || newContactsStatus != contactsPermissionGranted {
            notificationPermissionGranted = newNotificationStatus
            contactsPermissionGranted = newContactsStatus
        }
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
            HStack(alignment: .top, spacing: 12) {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                
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

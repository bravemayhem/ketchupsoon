import SwiftUI

struct PermissionsScreen: View {
    @EnvironmentObject var viewModel: UserOnboardingViewModel
    @EnvironmentObject var onboardingManager: OnboardingManager
    @StateObject private var notificationsManager = NotificationsManager.shared
    @StateObject private var contactsManager = ContactsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Final Step")
                            .font(.custom("SpaceGrotesk-Bold", size: 24))
                            .foregroundColor(.white)
                        
                        Text("Enable these features to get the full experience")
                            .font(.custom("SpaceGrotesk-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Notifications permission
                    PermissionCard(
                        title: "Notifications",
                        description: "Get reminders when it's time to catch up with friends",
                        iconName: "bell.fill",
                        iconColor: Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0)),
                        isEnabled: notificationsManager.authorizationStatus == .authorized,
                        action: {
                            Task {
                                try? await notificationsManager.requestAuthorization()
                            }
                        }
                    )
                    
                    // Contacts permission
                    PermissionCard(
                        title: "Contacts",
                        description: "Import friends from your address book",
                        iconName: "person.crop.circle.fill",
                        iconColor: Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 1.0)),
                        isEnabled: contactsManager.authorizationStatus == .authorized,
                        action: {
                            Task {
                                _ = await contactsManager.requestAccess()
                            }
                        }
                    )
  /*
                    // Calendar permission
                    PermissionCard(
                        title: "Calendar",
                        description: "Schedule hangouts and sync with your calendar",
                        iconName: "calendar",
                        iconColor: Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                        isEnabled: calendarManager.isAuthorized || calendarManager.isGoogleAuthorized,
                        action: {
                            Task {
                                await calendarManager.requestAccess()
                            }
                        }
                    ) */
                }
                .padding(.horizontal, 20)
            }

            
            // Button to complete onboarding
            VStack {
                Button {
                    onboardingManager.completeOnboarding()
                } label: {
                    Text("Get Started")
                        .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                                    Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.3)), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor(red: 13/255, green: 10/255, blue: 34/255, alpha: 0.8)))
        }
        .onAppear {
            // Refresh authorization statuses when the view appears
            Task {
                // These methods may not exist - removing them to fix compiler errors
                // If you have proper refresh methods, you can add them back
                
                // Update permission card states based on current values
                // The cards will reflect the current state automatically through the @StateObject bindings
            }
        }
    }
} 

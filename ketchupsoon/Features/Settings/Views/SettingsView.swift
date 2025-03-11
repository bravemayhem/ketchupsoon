import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var showingClearDataAlert = false
    @State private var showingDeleteStoreAlert = false
    @State private var showingResetOnboardingAlert = false
    @StateObject private var socialAuthManager = SocialAuthManager.shared
    @State private var isCalendarIntegrated = true
    
    var body: some View {
        ZStack {
            // Use the shared background components and ensure it fills the screen
            CompleteBackground.profile
                .ignoresSafeArea()
            
            // Content layer
            VStack(spacing: 0) {
                // Navigation bar with title and Done button
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "15103A").opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Main content in ScrollView
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Profile Section
                        sectionHeader(title: "profile")
                        
                        VStack(spacing: 0) {
                            NavigationLink {
                                UserProfileView()
                            } label: {
                                menuItem(
                                    title: "Profile Settings",
                                    icon: "person.circle",
                                    iconColor: AppColors.accent,
                                    hasChevron: true,
                                    isLast: true
                                )
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: "15103A").opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .clipped()
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // App Settings Section
                        sectionHeader(title: "app settings")
                        
                        VStack(spacing: 0) {
                            NavigationLink {
                                NotificationSettingsView()
                            } label: {
                                menuItem(
                                    title: "Notifications",
                                    icon: "bell",
                                    hasChevron: true
                                )
                            }
                            
                            appAppearanceItem(selection: $colorSchemeManager.currentAppearanceMode)
                            
                            calendarIntegrationItem(isOn: $isCalendarIntegrated)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: "15103A").opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .clipped()
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // Data Section (Debug only)
                        #if DEBUG
                        sectionHeader(title: "data")
                        
                        VStack(spacing: 0) {
                            Button {
                                showingClearDataAlert = true
                            } label: {
                                menuItem(
                                    title: "Clear All Data",
                                    icon: "trash",
                                    iconColor: Color(hex: "FF2D55"),
                                    textColor: Color(hex: "FF2D55")
                                )
                            }
                            
                            Button {
                                showingDeleteStoreAlert = true
                            } label: {
                                menuItem(
                                    title: "Delete Data Store",
                                    icon: "trash.slash",
                                    iconColor: Color(hex: "FF2D55"),
                                    textColor: Color(hex: "FF2D55")
                                )
                            }
                            
                            Button {
                                showingResetOnboardingAlert = true
                            } label: {
                                menuItem(
                                    title: "Reset Onboarding",
                                    icon: "arrow.triangle.2.circlepath",
                                    iconColor: Color(hex: "FF2D55"),
                                    textColor: Color(hex: "FF2D55"),
                                    isLast: true
                                )
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: "15103A").opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .clipped()
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        #endif
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .background(Color.clear) // Ensure ScrollView has clear background
            }
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task { @MainActor in
                    // await clearAllData()
                }
            }
        } message: {
            Text("This will delete all friends and hangouts. This action cannot be undone.")
        }
        .alert("Delete Data Store", isPresented: $showingDeleteStoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { @MainActor in
                    // await deleteDataStore()
                }
            }
        } message: {
            Text("This will delete the entire data store. This action cannot be undone.")
        }
        .alert("Reset Onboarding", isPresented: $showingResetOnboardingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                onboardingManager.resetOnboardingAndNavigateToOnboarding()
                dismiss()
            }
        } message: {
            Text("This will reset the onboarding flow and take you to the onboarding process immediately.")
        }
    }
    
    // Helper function to create section headers
    func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.custom("SpaceGrotesk-SemiBold", size: 16))
            .foregroundColor(.white)
            .padding(.top, 10)
            .padding(.bottom, 5)
    }
    
    // Helper function to create menu items
    func menuItem(title: String, icon: String? = nil, iconColor: Color = .white, subtitle: String? = nil, textColor: Color = .white, hasChevron: Bool = false, isLast: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                        .foregroundColor(textColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("SpaceGrotesk-Regular", size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if hasChevron {
                    Text("→")
                        .font(.custom("SpaceGrotesk-Medium", size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.leading, 20)
            }
        }
    }
    
    // Helper function for appearance mode picker
    func appAppearanceItem(selection: Binding<AppearanceMode>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                
                Text("Appearance")
                    .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("", selection: selection) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .accentColor(.white)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.leading, 20)
        }
    }
    
    // Calendar integration toggle item
    func calendarIntegrationItem(isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar Integration")
                        .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                        .foregroundColor(.white)
                    
                    Text("Google Calendar")
                        .font(.custom("SpaceGrotesk-Regular", size: 12))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                // Custom toggle
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(hex: "15103A").opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(width: 60, height: 30)
                    
                    Circle()
                        .fill(isOn.wrappedValue ? AnyShapeStyle(AppColors.accentGradient) : AnyShapeStyle(Color.gray.opacity(0.5)))
                        .frame(width: 20, height: 20)
                        .offset(x: isOn.wrappedValue ? 15 : -15)
                }
                .onTapGesture {
                    withAnimation(.spring()) {
                        isOn.wrappedValue.toggle()
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.leading, 20)
        }
    }
}

// Preview provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
    }
}

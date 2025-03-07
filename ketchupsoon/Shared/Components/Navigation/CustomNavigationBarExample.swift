import SwiftUI

/// Example implementation of the CustomNavigationBar to show how it can be used in a real view
struct CustomNavigationBarExample: View {
    @State private var showingSettings = false
    @State private var showingAddOptions = false
    @State private var showingDebugAlert = false
    @State private var selectedDesign: DesignType = .classic
    
    enum DesignType: String, CaseIterable, Identifiable {
        case classic = "Classic Design"
        case new = "New Design"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Design selector
            if !selectedDesign.isNew {
                Picker("Select Design", selection: $selectedDesign) {
                    ForEach(DesignType.allCases) { designType in
                        Text(designType.rawValue).tag(designType)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
            
            // Content with appropriate navigation bar
            if selectedDesign.isNew {
                newDesignExample
            } else {
                classicDesignExample
            }
        }
    }
    
    // Classic design example
    private var classicDesignExample: some View {
        CustomNavigationBarContainer(
            title: "Friends",
            subtitle: "Keep track of the details that matter to you",
            leadingButtonAction: {
                showingSettings = true
            },
            trailingButtonAction: {
                showingAddOptions = true
            },
            content: {
                // Your page content goes here
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(1...10, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 80)
                                .overlay(
                                    Text("Friend \(index)")
                                        .foregroundColor(.primary)
                                )
                        }
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $showingSettings) {
            // Your settings view
            Text("Settings View")
                .padding()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAddOptions) {
            // Your add options view
            Text("Add Options View")
                .padding()
                .presentationDetents([.medium])
        }
    }
    
    // New design example
    private var newDesignExample: some View {
        CustomNavigationBarContainer(
            title: "Friends",
            subtitle: "Keep track of the details that matter to you",
            leadingIcon: "gear",
            trailingIcon: "plus",
            leadingButtonAction: {
                showingSettings = true
            },
            trailingButtonAction: {
                showingAddOptions = true
            },
            useNewDesign: true,
            profileEmoji: "👋",
            content: {
                // Your page content goes here
                ScrollView {
                    VStack(spacing: 20) {
                        // Decorative background elements
                        ZStack {
                            // Background decoration
                            Circle()
                                .fill(AppColors.primary.opacity(0.15))
                                .frame(width: 400, height: 400)
                                .blur(radius: 80)
                                .offset(x: 150, y: -50)
                            
                            Circle()
                                .fill(AppColors.secondary.opacity(0.1))
                                .frame(width: 360, height: 360)
                                .blur(radius: 80)
                                .offset(x: -150, y: 300)
                            
                            // Content cards
                            VStack(alignment: .leading, spacing: 20) {
                                // Friends section
                                Text("your circle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                                
                                // Friend cards
                                ForEach(1...6, id: \.self) { index in
                                    friendCard(name: "Friend \(index)")
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        )
        .sheet(isPresented: $showingSettings) {
            // Your settings view
            ZStack {
                AppColors.background.ignoresSafeArea()
                Text("Settings")
                    .foregroundColor(.white)
                    .font(.title)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAddOptions) {
            // Your add options view
            ZStack {
                AppColors.background.ignoresSafeArea()
                Text("Add Friends")
                    .foregroundColor(.white)
                    .font(.title)
            }
            .presentationDetents([.medium])
        }
    }
    
    // Reusable friend card for new design
    private func friendCard(name: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                )
            
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [AppColors.accent, AppColors.accentSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Text("😀")
                        .font(.system(size: 24))
                }
                
                // Name and details
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Last seen 2 days ago")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Action button
                Button(action: {}) {
                    Text("Ketchup")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [AppColors.accent, AppColors.accentSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }
            }
            .padding()
        }
        .frame(height: 80)
    }
}

// Extension to make design switching more readable
extension CustomNavigationBarExample.DesignType {
    var isNew: Bool {
        self == .new
    }
}

#Preview {
    CustomNavigationBarExample()
} 
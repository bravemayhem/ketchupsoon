import SwiftUI

/// Example showing how to use the shared background components
struct BackgroundUsageExample: View {
    var body: some View {
        // Example 1: Using a complete predefined background
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Using Predefined Background")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    Text("This screen uses CompleteBackground.home")
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Content cards with their own backgrounds
                    ForEach(1...3, id: \.self) { index in
                        ExampleCard(index: index)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Background Example")
            .background(CompleteBackground.home)
        }
    }
}

/// Example 2: Custom background component example
struct CustomBackgroundExample: View {
    var body: some View {
        VStack {
            Text("Custom Background Components")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 30)
            
            Text("This screen uses individual components")
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 30)
            
            Spacer()
        }
        .padding(.horizontal)
        .background(
            // Example of creating a CompleteBackground with different options
            CompleteBackground(
                gradient: KetchupGradientBackground(
                    colors: [
                        AppColors.backgroundPrimary,
                        AppColors.purple.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                bubbles: DecorativeBubbles(bubbles: [
                    DecorativeBubble(
                        color: AppColors.mint.opacity(0.2),
                        width: 300,
                        height: 300,
                        offset: CGPoint(x: 100, y: -50),
                        blurRadius: 50
                    )
                ]),
                decoration: .offsetBased(BackgroundElementFactory.homeElements()),
                noiseTexture: true,
                noiseOpacity: 0.04
            )
        )
    }
}

/// Example 3: Background in a card
struct ExampleCard: View {
    var index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card \(index)")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("This card has its own background")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            HStack {
                Spacer()
                
                Button(action: {}) {
                    Text("Action")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(AppColors.accentGradient1)
                        .cornerRadius(20)
                }
            }
        }
        .padding(20)
        .background(
            // Card-specific background style
            CompleteBackground.card
                .cornerRadius(20)
        )
    }
}

/// Example 4: Using SharedBackgroundView as a drop-in replacement
struct BackgroundReplacementExample: View {
    var body: some View {
        VStack {
            Text("Using SharedBackgroundView")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 30)
            
            Text("This is a drop-in replacement for BackgroundView")
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 30)
            
            Spacer()
        }
        .background(
            // Can be used exactly like the original BackgroundView
            SharedBackgroundView()
        )
    }
}

/// Example of how to migrate from the old BackgroundView
struct MigrationExample: View {
    var body: some View {
        ZStack {
            // Old code:
            // BackgroundView()
            
            // New code:
            SharedBackgroundView()
            
            // The rest of your view remains the same
            VStack {
                Text("Migrated View")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.top, 30)
                
                Spacer()
            }
        }
    }
}

// Alternative example with position-based elements
struct PositionBasedBackgroundExample: View {
    var body: some View {
        VStack {
            Text("Position-Based Decorative Elements")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 30)
            
            Text("Using PositionedElements with CompleteBackground")
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 30)
            
            Spacer()
        }
        .padding(.horizontal)
        .background(
            CompleteBackground(
                gradient: KetchupGradientBackground(
                    colors: [
                        AppColors.backgroundPrimary, 
                        AppColors.backgroundSecondary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                bubbles: DecorativeBubbles.profile,
                decoration: .positionBased(PositionedElementFactory.profileElements()),
                noiseTexture: true
            )
        )
    }
}

#Preview {
    TabView {
        BackgroundUsageExample()
            .tabItem {
                Text("Example 1")
            }
        
        CustomBackgroundExample()
            .tabItem {
                Text("Example 2")
            }
        
        PositionBasedBackgroundExample()
            .tabItem {
                Text("Example 3")
            }
        
        BackgroundReplacementExample()
            .tabItem {
                Text("Example 4")
            }
    }
    .preferredColorScheme(.dark)
} 
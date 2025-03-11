import SwiftUI
import UIKit

struct StatusBarView: View {
    @Binding var currentStep: Int
    @State private var showFontDebug = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app title and progress
            HStack {
                // Updated app title with gradient and glow effect to match SplashScreenView
                Text("ketchupsoon")
                    .font(.custom("SpaceGrotesk-Bold", size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                                Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.7)),
                        radius: 8,
                        x: 0,
                        y: 0
                    )
                    .onTapGesture(count: 3) {
                        // Triple tap to show font debug info
                        showFontDebug = true
                    }
                
                if currentStep < 5 {
                    Spacer()
                    
                    // Progress indicator
                    HStack(spacing: 8) {
                        // Progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)))
                                .frame(width: 100, height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                                            Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: CGFloat((currentStep + 1) * 20), height: 4)
                        }
                        
                        Text("\(currentStep + 1)/5")
                            .font(.custom("SpaceGrotesk-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(height: 75)
            .padding(.horizontal, 20)
            .padding(.top, 24) // Increased padding between system status bar and content
            .background(Color(UIColor(red: 13/255, green: 10/255, blue: 34/255, alpha: 0.75)))
        }
        .sheet(isPresented: $showFontDebug) {
            FontDebugInfo()
        }
    }
}

// A lighter, simpler font debugging view specific for the onboarding component
struct FontDebugInfo: View {
    @Environment(\.dismiss) private var dismiss
    @State private var availableFontFamilies: [String] = []
    @State private var spaceGroteskFontNames: [String] = []
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Onboarding Font Test")) {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SpaceGrotesk-Bold")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Group {
                                Text("Ketchup")
                                    .font(.custom("SpaceGrotesk-Bold", size: 24))
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("System Font")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Group {
                                Text("Ketchup")
                                    .font(.system(size: 24, weight: .bold))
                            }
                        }
                        .padding()
                    }
                }
                
                Section(header: Text("SpaceGrotesk Fonts Found")) {
                    if spaceGroteskFontNames.isEmpty {
                        Text("No SpaceGrotesk fonts found!")
                            .foregroundColor(.red)
                    } else {
                        ForEach(spaceGroteskFontNames, id: \.self) { fontName in
                            Text(fontName)
                                .font(.custom(fontName, size: 16, relativeTo: .body))
                        }
                    }
                }
                
                Section(header: Text("Available Font Families")) {
                    ForEach(availableFontFamilies.prefix(10), id: \.self) { family in
                        Text(family)
                    }
                }
            }
            .navigationTitle("Font Debug")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .onAppear {
                loadFonts()
            }
        }
    }
    
    private func loadFonts() {
        // Get all available font families
        availableFontFamilies = UIFont.familyNames.sorted()
        
        // Look for SpaceGrotesk fonts specifically
        for family in availableFontFamilies {
            let familyFonts = UIFont.fontNames(forFamilyName: family)
            for font in familyFonts {
                if font.contains("SpaceGrotesk") || font.contains("Space") {
                    spaceGroteskFontNames.append(font)
                }
            }
        }
        
        // Debug logging
        print("Available font families: \(availableFontFamilies)")
        print("SpaceGrotesk fonts found: \(spaceGroteskFontNames)")
    }
} 

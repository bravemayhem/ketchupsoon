/*
import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color(red: 236/255, green: 190/255, blue: 96/255) // The yellow-orange background color
                    .ignoresSafeArea()
                
                Image("KetchupMascots") // We'll add this image to the asset catalog
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
            }
            .onAppear {
                // Simulate a loading delay and then show the main content
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
} 
*/

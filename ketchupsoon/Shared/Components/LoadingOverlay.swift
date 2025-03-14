import SwiftUI

struct LoadingOverlay: View {
    // Add a fade-in animation
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Reduce the background opacity for a more subtle effect
            Color.black.opacity(0.25)
                .edgesIgnoringSafeArea(.all)
            
            // Modern looking loading indicator
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.4))
                    .blur(radius: 0.5)
                    .background(.ultraThinMaterial)
            )
            .cornerRadius(16)
            // Add a subtle glow
            .shadow(color: AppColors.purple.opacity(0.3), radius: 15, x: 0, y: 0)
        }
        .opacity(opacity)
        .onAppear {
            // Animate the overlay appearing with a slight delay
            withAnimation(.easeIn(duration: 0.2).delay(0.1)) {
                opacity = 1
            }
        }
    }
}

#Preview {
    LoadingOverlay()
}

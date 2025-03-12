import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject var viewModel: UserOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Welcome card with GIF inside
            WelcomeCardView(
                gifUrl: URL(string: "https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExN3FyZHh3bHo5Y3Z5djU0NW03amh4c3lvbmtmZ3p5NjR3aXF4ancycyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/xThuW7e5tqiYxfSS8o/giphy.gif"),
                onButtonTap: {
                    viewModel.nextStep()
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard) // Prevent keyboard from pushing content
    }
}

// MARK: - Supporting Views

// Welcome Card View
struct WelcomeCardView: View {
    var gifUrl: URL?
    var onButtonTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("welcome! 🌟")
                .font(.custom("SpaceGrotesk-Bold", size: 22))
                .foregroundColor(.white)
            
            // GIF Image inside the card - properly scaled
            HStack {
                Spacer()
                GIFView(url: gifUrl)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer()
            }
            .padding(.vertical, 4)
            
            WelcomeTextView()
                .font(.custom("SpaceGrotesk-Regular", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(2)
            
            GetStartedButton(action: onButtonTap)
                .padding(.top, 4)
        }
        .padding(16) // Reduced padding
        .background(Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Welcome Text Component
struct WelcomeTextView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("for when you ")
            Text("actually").italic()
            Text(" want to ketchupsoon")
        }
    }
}

// Get Started Button Component
struct GetStartedButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("let's get started! 🙌")
                .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10) // Smaller padding
                .background(buttonGradient)
                .cornerRadius(16)
                .shadow(color: Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.3)), radius: 6, x: 0, y: 3)
        }
    }
    
    private var buttonGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// GIF View implementation using UIKit
struct GIFView: UIViewRepresentable {
    private let name: String?
    private let url: URL?
    
    // Initialize with a local resource name
    init(named name: String) {
        self.name = name
        self.url = nil
    }
    
    // Initialize with a URL
    init(url: URL?) {
        self.url = url
        self.name = nil
    }
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        if let url = url {
            // Load the GIF from URL
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    DispatchQueue.main.async {
                        imageView.image = UIImage(systemName: "photo")
                    }
                    return
                }
                
                self.loadGIFFromData(data, into: imageView)
            }.resume()
        } else if let name = name, 
                  let path = Bundle.main.path(forResource: name, ofType: "gif"),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            // Load the GIF from local bundle
            loadGIFFromData(data, into: imageView)
        } else {
            // Fallback to a placeholder if GIF can't be loaded
            imageView.image = UIImage(systemName: "photo")
        }
        
        return imageView
    }
    
    private func loadGIFFromData(_ data: Data, into imageView: UIImageView) {
        if let source = CGImageSourceCreateWithData(data as CFData, nil) {
            let count = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var totalDuration: TimeInterval = 0
            
            for i in 0..<count {
                if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: image))
                    
                    // Get frame duration
                    if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                       let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                       let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                        totalDuration += delayTime
                    }
                }
            }
            
            DispatchQueue.main.async {
                // Set the animation
                imageView.animationImages = images
                imageView.animationDuration = totalDuration
                imageView.animationRepeatCount = 0 // Infinite loop
                imageView.startAnimating()
            }
        } else {
            DispatchQueue.main.async {
                imageView.image = UIImage(systemName: "photo")
            }
        }
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Updates can be handled here if needed
    }
}

#Preview {
    WelcomeScreen()
}

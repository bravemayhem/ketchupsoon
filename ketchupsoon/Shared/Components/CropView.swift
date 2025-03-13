import SwiftUI
import PhotosUI

struct CropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .padding()
                
                Spacer()
                
                Button("Done") {
                    let croppedImage = cropImage()
                    onCrop(croppedImage)
                    dismiss()
                }
                .padding()
                .bold()
            }
            
            Spacer()
            
            GeometryReader { geometry in
                ZStack {
                    Color.black
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    
                                    // Limit minimum scale to avoid image being too small
                                    scale = max(scale * delta, 0.5)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: geometry.size.width / 2)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(
                            width: min(geometry.size.width, geometry.size.height) - 40,
                            height: min(geometry.size.width, geometry.size.height) - 40
                        )
                )
            }
            
            Spacer()
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func cropImage() -> UIImage {
        // Create a UIGraphicsImageRenderer to crop the image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        
        // Perform the cropping in the renderer
        let croppedImage = renderer.image { context in
            // Calculate the adjusted position based on scale and offset
            let drawRect = CGRect(
                x: -offset.width / scale,
                y: -offset.height / scale,
                width: 300 / scale,
                height: 300 / scale
            )
            
            // Draw the image with the adjusted position and scale
            image.draw(in: drawRect)
        }
        
        return croppedImage
    }
}

#Preview {
    CropView(image: UIImage(systemName: "person.crop.circle.fill") ?? UIImage(), onCrop: { _ in })
}

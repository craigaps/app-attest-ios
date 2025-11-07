import SwiftUI

/// A reusable animated view that displays a system image (checkmark.circle)
/// with a scale and opacity entrance animation, followed by a spring bounce.
/// The image is shown only when `isVisible` is true, along with optional descriptive text.
struct AnimateImage: View {
    /// Controls visibility of the animated image and text.
    let isVisible: Bool
    
    /// SF Symbol name (e.g., "checkmark.circle.fill")
    let systemImage: String
    
    /// The color used to render the system image.
    let imageColor: Color
    
    /// Duration of the initial scale/opacity animation in seconds.
    let animationDuration: Double
    
    /// The width and height (in points) of the image.
    let imageSize: CGFloat
    
    /// Optional text displayed below the image.
    let text: String
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    var body: some View {
        if isVisible {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize, height: imageSize)
                    .foregroundColor(imageColor)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        // Animate to large and visible
                        withAnimation(.easeOut(duration: animationDuration)) {
                            scale = 1.2
                            opacity = 1.0
                        }
                        
                        // Settle back to medium scale
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                scale = 1.0
                            }
                        }
                    }
                
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .animation(.easeInOut(duration: 0.8), value: isVisible)
            .padding()
        }
    }
}

#Preview {
    AnimateImage(isVisible: true, systemImage: "dog", imageColor: .blue, animationDuration: 2.0, imageSize: 64.0, text: "Hello World!")
}

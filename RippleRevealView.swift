import SwiftUI

// MARK: - Transition Extension
extension AnyTransition {
    static func rippleReveal(from point: CGPoint, maskPath: [CGPoint]) -> AnyTransition {
        .asymmetric(
            insertion: .init(RippleRevealTransition(tapLocation: point, dragPath: maskPath)),
            removal: .opacity
        )
    }
}

// MARK: - Ripple Reveal Transition
struct RippleRevealTransition: Transition {
    var tapLocation: CGPoint
    var dragPath: [CGPoint]
    
    func body(content: Content, phase: TransitionPhase) -> some View {
        // For insertion: phase.value goes -1.0 → 0.0
        // Convert to: 0.0 → 1.0 for reveal progress
        let progress = 1.0 + phase.value
        
        return content
            .visualEffect { content, proxy in
                content.distortionEffect(
                    ShaderLibrary.rippleDistortion(
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(Float(progress)),
                        .float2(Float(tapLocation.x), Float(tapLocation.y))
                    ),
                    maxSampleOffset: CGSize(width: 10, height: 10)
                )
            }
            .mask {
                // Use the drag path to create the reveal mask
                Canvas { context, size in
                    var path = Path()
                    if let first = dragPath.first {
                        path.move(to: first)
                        for point in dragPath.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    
                    context.stroke(
                        path,
                        with: .color(.white),
                        style: StrokeStyle(lineWidth: 120, lineCap: .round, lineJoin: .round)
                    )
                }
                .blur(radius: 40)
                .overlay {
                    // Add expanding circle for the ripple origin
                    CircularRevealShape(center: tapLocation, progress: progress)
                        .fill(.white)
                }
            }
    }
}

// MARK: - Circular Reveal Shape
struct CircularRevealShape: Shape {
    var center: CGPoint
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let maxRadius = sqrt(pow(rect.width, 2) + pow(rect.height, 2))
        let currentRadius = progress * maxRadius * 0.5 // Smaller initial radius
        
        var path = Path()
        path.addEllipse(in: CGRect(
            x: center.x - currentRadius,
            y: center.y - currentRadius,
            width: currentRadius * 2,
            height: currentRadius * 2
        ))
        return path
    }
}

// MARK: - Main View with Drag-to-Reveal
struct RippleRevealView: View {
    @State private var dragPath: [CGPoint] = []
    @State private var isDragging = false
    @State private var currentImageIndex = 0
    @State private var tapLocation: CGPoint = .zero
    @State private var transitionKey = UUID()
    
    let images = ["image1", "image2"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Current image (background)
                Image(images[currentImageIndex])
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                // Next image (revealed by drag)
                if !dragPath.isEmpty {
                    Image(images[(currentImageIndex + 1) % images.count])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                        .transition(.rippleReveal(from: tapLocation, maskPath: dragPath))
                        .id(transitionKey)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            tapLocation = value.startLocation
                            dragPath = [value.location]
                            
                            // Start animation
                            withAnimation(.easeOut(duration: 1.5)) {
                                transitionKey = UUID()
                            }
                        } else {
                            dragPath.append(value.location)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        
                        // Check if enough of the screen was painted
                        // For simplicity, check if drag path is long enough
                        if dragPath.count > 50 {
                            // Complete the transition
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                currentImageIndex = (currentImageIndex + 1) % images.count
                                dragPath.removeAll()
                                transitionKey = UUID()
                            }
                        } else {
                            // Reset if not enough dragging
                            withAnimation(.easeOut(duration: 0.5)) {
                                dragPath.removeAll()
                                transitionKey = UUID()
                            }
                        }
                    }
            )
        }
    }
}

#Preview {
    RippleRevealView()
}

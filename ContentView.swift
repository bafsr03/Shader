import SwiftUI

// MARK: - Ripple Data Model
struct Ripple: Identifiable {
    let id = UUID()
    let location: CGPoint
    let startTime: Date
    var isDecayed: Bool = false
}


struct ContentView: View {
    @State private var ripples: [Ripple] = []
    @State private var currentImageIndex = 0
    @State private var currentTime = Date()
    @State private var revealProgress: CGFloat = 0.0
    @State private var isFullyRevealed = false
    @State private var lastDragPoint: CGPoint?
    @State private var dragPointCounter = 0
    
    // Images to transition between
    let images = ["image1", "image2"]
    
    // Ripple parameters
    let rippleDuration: TimeInterval = 2.5 // Slower, smoother expansion
    let dragRippleSpacing = 8 // Add ripple every N points during drag
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { (timeline: TimelineViewDefaultContext) in
                ZStack {
                    // Current Image (base layer)
                    Image(images[currentImageIndex])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                    
                    // Next Image (revealed by ripples)
                    if !isFullyRevealed {
                        Image(images[(currentImageIndex + 1) % images.count])
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .ignoresSafeArea()
                            .multiRippleEffect(
                                ripples: ripples,
                                currentTime: currentTime,
                                size: geometry.size
                            )
                            .mask {
                                // Create circular masks for each ripple
                                Canvas { context, size in
                                    for ripple in ripples {
                                        let elapsed = currentTime.timeIntervalSince(ripple.startTime)
                                        let progress = min(elapsed / rippleDuration, 1.0)
                                        
                                        // Calculate expanding radius (smaller for localized effect)
                                        let maxRadius = sqrt(size.width * size.width + size.height * size.height)
                                        let currentRadius = CGFloat(progress) * maxRadius * 0.25
                                        
                                        // Draw expanding circle
                                        let rect = CGRect(
                                            x: ripple.location.x - currentRadius,
                                            y: ripple.location.y - currentRadius,
                                            width: currentRadius * 2,
                                            height: currentRadius * 2
                                        )
                                        
                                        context.fill(
                                            Path(ellipseIn: rect),
                                            with: .color(.white.opacity(1.0 - progress * 0.3))
                                        )
                                    }
                                }
                            }
                            .waveTransition(time: currentTime.timeIntervalSince1970, speed: 2.0)
                    }
                }
            }
            .onChange(of: currentTime) { oldValue, newValue in
                // Clean up decayed ripples
                ripples.removeAll { ripple in
                    let elapsed = newValue.timeIntervalSince(ripple.startTime)
                    return elapsed > rippleDuration
                }
            }
            .task {
                // Update current time continuously
                while true {
                    currentTime = Date()
                    try? await Task.sleep(nanoseconds: 16_666_667) // ~60fps
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // On drag, add ripples along the path (brush effect)
                        if let last = lastDragPoint {
                            let distance = hypot(
                                value.location.x - last.x,
                                value.location.y - last.y
                            )
                            
                            // Add ripple every few pixels for brush effect
                            if distance > 15 {
                                addRipple(at: value.location)
                                lastDragPoint = value.location
                            }
                        } else {
                            // First touch - add initial ripple
                            addRipple(at: value.location)
                            lastDragPoint = value.location
                        }
                    }
                    .onEnded { _ in
                        lastDragPoint = nil
                        checkIfFullyRevealed(size: geometry.size)
                    }
            )
            .onTapGesture { location in
                // Single tap = single ripple
                if isFullyRevealed {
                    // Reset for next image
                    transitionToNextImage()
                } else {
                    addRipple(at: location)
                    
                    // Check after a delay if fully revealed
                    DispatchQueue.main.asyncAfter(deadline: .now() + rippleDuration) {
                        checkIfFullyRevealed(size: geometry.size)
                    }
                }
            }
        }
    }
    
    private func addRipple(at location: CGPoint) {
        let newRipple = Ripple(location: location, startTime: currentTime)
        ripples.append(newRipple)
    }
    
    private func checkIfFullyRevealed(size: CGSize) {
        // Simple heuristic: if enough ripples have been created, consider it revealed
        // More sophisticated: check coverage area
        let totalArea = size.width * size.height
        let maxRadius = sqrt(size.width * size.width + size.height * size.height) * 1.2
        
        var coveredArea: CGFloat = 0
        for _ in ripples {
            let radius = maxRadius // Assume fully expanded
            coveredArea += .pi * radius * radius
        }
        
        // Account for overlap (rough estimate)
        let coverage = min(coveredArea / (totalArea * 2), 1.0)
        
        if coverage > 0.8 {
            isFullyRevealed = true
        }
    }
    
    private func transitionToNextImage() {
        withAnimation(.easeOut(duration: 0.3)) {
            currentImageIndex = (currentImageIndex + 1) % images.count
            ripples.removeAll()
            isFullyRevealed = false
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Multi-Ripple Shader Effect
struct MultiRippleEffect: ViewModifier {
    var ripples: [Ripple]
    var currentTime: Date
    var size: CGSize
    
    // Ripple parameters
    let rippleDuration: TimeInterval = 1.5 // How long until fully decayed
    let rippleSpeed: Float = 2.0 // Expansion speed
    
    func body(content: Content) -> some View {
        // Use the first ripple for the distortion effect (or no effect if empty)
        let activeRipple = ripples.first
        let elapsed = activeRipple.map { currentTime.timeIntervalSince($0.startTime) } ?? 0
        let progress = min(Float(elapsed / rippleDuration), 1.0)
        let location = activeRipple?.location ?? .zero
        
        return content
            .distortionEffect(
                ShaderLibrary.rippleDistortion(
                    .float2(Float(size.width), Float(size.height)),
                    .float(progress),
                    .float2(Float(location.x), Float(location.y))
                ),
                maxSampleOffset: CGSize(width: 10, height: 10),
                isEnabled: activeRipple != nil
            )
    }
}

extension View {
    func multiRippleEffect(ripples: [Ripple], currentTime: Date, size: CGSize) -> some View {
        self.modifier(MultiRippleEffect(ripples: ripples, currentTime: currentTime, size: size))
    }
}

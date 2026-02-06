import SwiftUI

// MARK: - Ripple Data Model
struct Ripple: Identifiable {
    let id = UUID()
    let location: CGPoint
    let startTime: Date
    var isDecayed: Bool = false
}

// MARK: - Permanent Reveal Circle
struct RevealCircle: Identifiable {
    let id = UUID()
    let location: CGPoint
    let radius: CGFloat
}

struct ContentView: View {
    @State private var ripples: [Ripple] = []
    @State private var revealedCircles: [RevealCircle] = [] // Permanent revealed areas
    @State private var currentImageIndex = 0
    @State private var currentTime = Date()
    @State private var lastDragPoint: CGPoint?
    @State private var isTransitioning = false
    @State private var transitionOpacity: Double = 1.0 // For smooth fade transitions
    
    // Images to transition between
    let images = ["image1", "image2"]
    
    // Ripple parameters
    let rippleDuration: TimeInterval = 2.5 // Slower, smoother expansion
    let dragRippleSpacing = 15.0 // Add ripple every N pixels during drag
    
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
                    
                    // Next Image (revealed by ripples) - only show if there are revealed areas
                    if !revealedCircles.isEmpty || !ripples.isEmpty {
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
                                // Create permanent masks for revealed areas with soft edges
                                Canvas { context, size in
                                    // Draw all permanent revealed circles
                                    for circle in revealedCircles {
                                        let rect = CGRect(
                                            x: circle.location.x - circle.radius,
                                            y: circle.location.y - circle.radius,
                                            width: circle.radius * 2,
                                            height: circle.radius * 2
                                        )
                                        
                                        context.fill(
                                            Path(ellipseIn: rect),
                                            with: .color(.white)
                                        )
                                    }
                                    
                                    // Draw active expanding ripples
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
                                        
                                        // Fade in while expanding
                                        let opacity = 0.8 + (0.2 * progress)
                                        context.fill(
                                            Path(ellipseIn: rect),
                                            with: .color(.white.opacity(opacity))
                                        )
                                    }
                                }
                                .blur(radius: 15) // Soften all edges for smooth blending
                            }
                            .waveTransition(time: currentTime.timeIntervalSince1970, speed: 2.0)
                            .opacity(transitionOpacity) // Smooth fade during transition
                    }
                }
            }
            .onChange(of: currentTime) { oldValue, newValue in
                // Convert active ripples to permanent circles when they finish
                let finishedRipples = ripples.filter { ripple in
                    let elapsed = newValue.timeIntervalSince(ripple.startTime)
                    return elapsed >= rippleDuration
                }
                
                // Add finished ripples as permanent reveal circles
                for ripple in finishedRipples {
                    let maxRadius = sqrt(geometry.size.width * geometry.size.width + geometry.size.height * geometry.size.height)
                    let finalRadius = maxRadius * 0.25
                    
                    let newCircle = RevealCircle(
                        location: ripple.location,
                        radius: finalRadius
                    )
                    revealedCircles.append(newCircle)
                }
                
                // Remove finished ripples from active list
                ripples.removeAll { ripple in
                    let elapsed = newValue.timeIntervalSince(ripple.startTime)
                    return elapsed >= rippleDuration
                }
                
                // Check if fully revealed
                if !isTransitioning {
                    checkIfFullyRevealed(size: geometry.size)
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
                        if isTransitioning { return }
                        
                        // On drag, add ripples along the path (brush effect)
                        if let last = lastDragPoint {
                            let distance = hypot(
                                value.location.x - last.x,
                                value.location.y - last.y
                            )
                            
                            // Add ripple every few pixels for brush effect
                            if distance > dragRippleSpacing {
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
                    }
            )
            .onTapGesture { location in
                if isTransitioning { return }
                
                // Single tap = single ripple
                addRipple(at: location)
            }
        }
    }
    
    private func addRipple(at location: CGPoint) {
        let newRipple = Ripple(location: location, startTime: currentTime)
        ripples.append(newRipple)
    }
    
    private func checkIfFullyRevealed(size: CGSize) {
        // Calculate total revealed area
        let totalArea = size.width * size.height
        
        var coveredArea: CGFloat = 0
        for circle in revealedCircles {
            coveredArea += .pi * circle.radius * circle.radius
        }
        
        // Account for overlap (rough estimate with 50% discount for overlap)
        let estimatedCoverage = min(coveredArea / (totalArea * 1.5), 1.0)
        
        // Require 90% coverage to ensure nearly complete reveal
        if estimatedCoverage > 0.99 {
            transitionToNextImage()
        }
    }
    
    private func transitionToNextImage() {
        isTransitioning = true
        
        // When coverage is complete, the revealed layer already shows the full next image
        // Just instantly switch the base layer and clear reveals for seamless transition
        currentImageIndex = (currentImageIndex + 1) % images.count
        ripples.removeAll()
        revealedCircles.removeAll()
        
        // Ensure opacity is back to 1.0 for next reveal cycle
        transitionOpacity = 1.0
        
        // Brief delay before allowing new interactions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTransitioning = false
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
    let rippleDuration: TimeInterval = 2.5 // Match ContentView duration
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

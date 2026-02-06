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
    let audioManager: AudioManager
    let onBackToSongSelection: () -> Void
    
    @State private var ripples: [Ripple] = []
    @State private var revealedCircles: [RevealCircle] = [] // Permanent revealed areas
    @State private var currentImageIndex = 0
    @State private var currentTime = Date()
    @State private var lastDragPoint: CGPoint?
    @State private var isTransitioning = false
    @State private var transitionOpacity: Double = 1.0 // For smooth fade transitions
    
    // 16 Images for dedication slides
    let images = (1...16).map { "slide\($0)" }
    
    // Ripple parameters
    let rippleDuration: TimeInterval = 2.5 // Slower, smoother expansion
    let dragRippleSpacing = 15.0 // Add ripple every N pixels during drag
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { (timeline: TimelineViewDefaultContext) in
                ZStack {
                    // Current Image (base layer)
                    let currentImageName = images[currentImageIndex]
                    if let uiImage = loadSmartImage(named: currentImageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .ignoresSafeArea()
                    } else {
                        // Fallback if image is missing
                        ZStack {
                            Color.black.ignoresSafeArea()
                            VStack(spacing: 10) {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                                Text("Missing Image")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("'\(currentImageName)'")
                                    .font(.title3.monospaced())
                                    .foregroundColor(.gray)
                                Text("Try naming it exactly 'slide\(currentImageIndex + 1)'")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Next Image (revealed by ripples) - only show if there are revealed areas
                    if !revealedCircles.isEmpty || !ripples.isEmpty {
                        Group {
                            let nextIndex = (currentImageIndex + 1)
                            // Only show next image if we are not at the end
                             if nextIndex < images.count {
                                let nextImageName = images[nextIndex]
                                if let nextUiImage = loadSmartImage(named: nextImageName) {
                                    Image(uiImage: nextUiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                        .ignoresSafeArea()
                                } else {
                                    Color.black
                                }
                            }
                        }
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
                    
                    // Navigation Button (always visible for Back or Music)
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer() // Push to right
                            
                            Button(action: goBackOneSlide) {
                                HStack(spacing: 8) {
                                    Image(systemName: currentImageIndex == 0 ? "music.note" : "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                    Text(currentImageIndex == 0 ? "Music" : "Back")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                                }
                            }
                            .padding(.trailing, 30) // Right spacing
                            .padding(.bottom, 30)   // Raised slightly as requested
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
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
        .ignoresSafeArea()
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
        
        // Require 99% coverage to ensure nearly complete reveal
        if estimatedCoverage > 0.99 {
            transitionToNextImage()
        }
    }
    
    private func transitionToNextImage() {
        // Don't transition if we're on the last slide
        if currentImageIndex >= images.count - 1 {
            // On last slide - just clear the reveal for now
            ripples.removeAll()
            revealedCircles.removeAll()
            transitionOpacity = 1.0
            return
        }
        
        isTransitioning = true
        
        // When coverage is complete, the revealed layer already shows the full next image
        // Just instantly switch the base layer and clear reveals for seamless transition
        currentImageIndex += 1
        ripples.removeAll()
        revealedCircles.removeAll()
        
        // Ensure opacity is back to 1.0 for next reveal cycle
        transitionOpacity = 1.0
        
        // Brief delay before allowing new interactions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTransitioning = false
        }
    }
    
    private func goBackOneSlide() {
        if currentImageIndex == 0 {
            // First slide -> Go back to Song Selection
            onBackToSongSelection()
        } else {
            // Later slides -> Go back one slide
            withAnimation(.easeInOut(duration: 0.3)) {
                currentImageIndex -= 1
                ripples.removeAll()
                revealedCircles.removeAll()
                transitionOpacity = 1.0
            }
        }
    }
}

#Preview {
    ContentView(audioManager: AudioManager(), onBackToSongSelection: {})
}

// MARK: - Helper Functions
private func loadSmartImage(named name: String) -> UIImage? {
    // 1. Try exact match
    if let image = UIImage(named: name) { return image }
    
    // 2. Try capitalized "SlideX"
    let capitalized = name.prefix(1).capitalized + name.dropFirst()
    if let image = UIImage(named: capitalized) { return image }
    
    // 3. Try with space "slide X"
    if name.hasPrefix("slide") {
        let number = name.dropFirst(5)
        let spaceName = "slide \(number)"
        if let image = UIImage(named: spaceName) { return image }
        
        // 4. Try capitalized with space "Slide X"
        let capSpaceName = "Slide \(number)"
        if let image = UIImage(named: capSpaceName) { return image }
    }
    
    return nil
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

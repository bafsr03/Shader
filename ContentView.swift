import SwiftUI

struct ContentView: View {
    @State private var touchPosition: CGPoint = .zero
    @State private var waveRadius: CGFloat = 0
    @State private var isDragging = false
    @State private var currentImageIndex = 0
    @State private var blendProgress: CGFloat = 0
    @State private var dragStartPosition: CGPoint = .zero
    @State private var dragStartTime: Date = Date()
    
    // Images to transition between
    let images = ["image1", "image2"]
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let elapsedTime = isDragging ? timeline.date.timeIntervalSince(dragStartTime) : 0
                
                ZStack {
                    // Background color
                    Color.black.ignoresSafeArea()
                    
                    // Next image (underneath - will be revealed)
                    if isDragging || waveRadius > 0 {
                        Image(images[(currentImageIndex + 1) % images.count])
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    
                    // Current image (on top - will be masked/faded by shader)
                    Image(images[currentImageIndex])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .waveTransition(
                            touchPosition: isDragging ? touchPosition : CGPoint(x: -1000, y: -1000),
                            waveRadius: waveRadius,
                            time: elapsedTime,
                            amplitude: 12,
                            frequency: 15,
                            decay: 5,
                            speed: 1000
                        )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartPosition = value.location
                            touchPosition = value.location
                            waveRadius = 0
                            dragStartTime = Date()
                        }
                        
                        // Update touch position
                        touchPosition = value.location
                        
                        // Calculate wave radius based on drag distance
                        let dragDistance = hypot(
                            value.location.x - dragStartPosition.x,
                            value.location.y - dragStartPosition.y
                        )
                        
                        withAnimation(.linear(duration: 0.1)) {
                            waveRadius = dragDistance
                        }
                        
                        // Calculate blend progress based on screen coverage
                        let maxDistance = hypot(geometry.size.width, geometry.size.height)
                        blendProgress = min(dragDistance / maxDistance, 1.0)
                    }
                    .onEnded { value in
                        let dragDistance = hypot(
                            value.location.x - dragStartPosition.x,
                            value.location.y - dragStartPosition.y
                        )
                        let maxDistance = hypot(geometry.size.width, geometry.size.height)
                        let progress = dragDistance / maxDistance
                        
                        // If dragged more than 30% across screen, complete transition
                        if progress > 0.3 {
                            completeTransition()
                        } else {
                            cancelTransition()
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }
    
    private func completeTransition() {
        withAnimation(.easeOut(duration: 0.5)) {
            // Expand wave to cover entire screen
            waveRadius = 2000
            blendProgress = 1.0
        }
        
        // After animation, switch to next image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentImageIndex = (currentImageIndex + 1) % images.count
            isDragging = false
            waveRadius = 0
            blendProgress = 0
        }
    }
    
    private func cancelTransition() {
        withAnimation(.easeOut(duration: 0.3)) {
            waveRadius = 0
            blendProgress = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isDragging = false
        }
    }
}

#Preview {
    ContentView()
}

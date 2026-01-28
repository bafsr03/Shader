import SwiftUI

struct ContentView: View {
    @State private var dragPath: [CGPoint] = []
    @State private var isDragging = false
    @State private var currentImageIndex = 0
    @State private var nextImageIndex = 1
    @State private var startTime = Date()
    @State private var isTransitioning = false
    
    // Images to transition between
    let images = ["image1", "image2"]
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSince(startTime)
                
                ZStack {
                    // Background (Next Image) - visible where mask reveals it
                    Image(images[nextImageIndex])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                    
                    // Foreground (Current Image) - masked out by the brush
                    Image(images[currentImageIndex])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                        .mask {
                            // Inverted Mask: We want to show the current image everywhere EXCEPT where we brushed.
                            // So we draw a black rectangle (opaque) and subtract the brush strokes (transparent).
                            // Wait, standard .mask() keeps alpha.
                            // So we want the mask to be WHITE (1.0) everywhere, and BLACK (0.0) where dragging.
                            // But usually it's easier to assert:
                            // We want to REVEAL the NEXT image.
                            // So let's flip the Z-order or flipping the mask logic.
                            
                            // Strategy:
                            // Top Layer: Next Image.
                            // Mask: Black everywhere, White where brushed.
                            // So Next Image appears only where brushed.
                            // Bottom Layer: Current Image.
                            
                            // Let's re-stack:
                            // Bottom: Current Image (Image 0).
                            // Top: Next Image (Image 1), with Mask.
                        }
                    
                    // Let's implement the "Top Reveal" strategy.
                    // Bottom: Current Image
                    Image(images[currentImageIndex])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                    
                    // Top: Next Image, revealed by brush
                    Image(images[nextImageIndex])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                        .mask {
                            Canvas { context, size in
                                // Draw the path
                                var path = Path()
                                if let first = dragPath.first {
                                    path.move(to: first)
                                    for point in dragPath.dropFirst() {
                                        path.addLine(to: point)
                                    }
                                }
                                
                                // Stroke parameters for the brush
                                // Increased width to give expanding room
                                context.stroke(
                                    path,
                                    with: .color(.white),
                                    style: StrokeStyle(lineWidth: 120, lineCap: .round, lineJoin: .round)
                                )
                            }
                            // Heavy blur creates the soft gradient the shader uses for "depth"
                            // The shader maps the blurry edges to the "expanding" water front
                            .blur(radius: 40)
                        }
                        // Apply the water shader to the MASKED layer (the revealed water)
                        // Speed is reduced to 2.0 for realism as requested
                        .waveTransition(time: time, speed: 2.0)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            // If we are starting a NEW drag after a transition, reset?
                            // For now, just append.
                        }
                        dragPath.append(value.location)
                    }
                    .onEnded { value in
                        isDragging = false
                        // Check if we painted enough to finish?
                        // For now, just leave it painted.
                        
                        // Optional: Reset if user lifts finger without finishing?
                        // Or maybe we want the persistent paint.
                        // User said "inner part the new image as it goes", implying persistent paint.
                    }
            )
        }
    }
}

#Preview {
    ContentView()
}

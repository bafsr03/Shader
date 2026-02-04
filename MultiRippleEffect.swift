import SwiftUI

// Note: Ripple struct is defined in ContentView.swift

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

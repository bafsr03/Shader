import SwiftUI

struct WaveShaderEffect: ViewModifier {
    var time: TimeInterval
    var speed: CGFloat
    
    func body(content: Content) -> some View {
        content
            .layerEffect(
                ShaderLibrary.waveTransition(
                    .float(time),
                    .float(speed)
                ),
                maxSampleOffset: CGSize(width: 50, height: 50)
            )
    }
}

extension View {
    func waveTransition(
        time: TimeInterval = 0,
        speed: CGFloat = 10
    ) -> some View {
        self.modifier(
            WaveShaderEffect(
                time: time,
                speed: speed
            )
        )
    }
}

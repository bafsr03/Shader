import SwiftUI

struct WaveShaderEffect: ViewModifier {
    var touchPosition: CGPoint
    var waveRadius: CGFloat
    var time: TimeInterval
    var amplitude: CGFloat
    var frequency: CGFloat
    var decay: CGFloat
    var speed: CGFloat
    
    func body(content: Content) -> some View {
        content
            .layerEffect(
                ShaderLibrary.waveTransition(
                    .float2(touchPosition),
                    .float(waveRadius),
                    .float(time),
                    .float(amplitude),
                    .float(frequency),
                    .float(decay),
                    .float(speed)
                ),
                maxSampleOffset: CGSize(width: amplitude, height: amplitude)
            )
    }
}

extension View {
    func waveTransition(
        touchPosition: CGPoint,
        waveRadius: CGFloat,
        time: TimeInterval = 0,
        amplitude: CGFloat = 15,
        frequency: CGFloat = 12,
        decay: CGFloat = 6,
        speed: CGFloat = 800
    ) -> some View {
        self.modifier(
            WaveShaderEffect(
                touchPosition: touchPosition,
                waveRadius: waveRadius,
                time: time,
                amplitude: amplitude,
                frequency: frequency,
                decay: decay,
                speed: speed
            )
        )
    }
}

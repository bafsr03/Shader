import SwiftUI

struct WaveShaderEffect: ViewModifier {
    var touchPosition: CGPoint
    var waveRadius: CGFloat
    var waveIntensity: CGFloat
    var blendProgress: CGFloat
    var waveFrequency: CGFloat
    
    func body(content: Content) -> some View {
        content
            .colorEffect(
                ShaderLibrary.waveTransition(
                    .float2(touchPosition),
                    .float(waveRadius),
                    .float(waveIntensity),
                    .float(blendProgress),
                    .float(waveFrequency)
                )
            )
    }
}

extension View {
    func waveTransition(
        touchPosition: CGPoint,
        waveRadius: CGFloat,
        waveIntensity: CGFloat = 0.05,
        blendProgress: CGFloat = 0.0,
        waveFrequency: CGFloat = 0.1
    ) -> some View {
        self.modifier(
            WaveShaderEffect(
                touchPosition: touchPosition,
                waveRadius: waveRadius,
                waveIntensity: waveIntensity,
                blendProgress: blendProgress,
                waveFrequency: waveFrequency
            )
        )
    }
}

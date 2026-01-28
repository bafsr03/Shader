#include <metal_stdlib>
using namespace metal;

// Shader function for wave-based image blending
[[ stitchable ]] half4 waveTransition(
    float2 position,
    half4 currentColor,
    float2 touchPos,
    float waveRadius,
    float waveIntensity,
    float blendProgress,
    float waveFrequency
) {
    // Calculate distance from touch point
    float2 toTouch = position - touchPos;
    float distance = length(toTouch);
    
    // Create wave effect at the boundary
    float wave = sin((distance - waveRadius) * waveFrequency) * waveIntensity;
    
    // Smooth transition boundary width
    float edgeWidth = 30.0;
    
    // Inside the wave radius = reveal new image (transparent/fade out current)
    // Outside the wave radius = keep current image (opaque)
    float alpha = smoothstep(waveRadius - edgeWidth, waveRadius + edgeWidth, distance);
    
    // Add wave distortion at the edge
    alpha += wave;
    alpha = saturate(alpha);
    
    // Apply brightness highlight at wave front
    float highlight = exp(-abs(distance - waveRadius) / 15.0) * 0.4;
    
    // Create final color with alpha for revealing
    half4 finalColor = currentColor;
    finalColor.a *= half(alpha);
    
    // Add highlight at the wave edge
    finalColor.rgb += half3(highlight * (1.0 - alpha));
    
    return finalColor;
}

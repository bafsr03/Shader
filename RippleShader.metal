#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Ripple distortion shader for distortionEffect (returns distorted position)
[[ stitchable ]] float2 rippleDistortion(
    float2 position,
    float2 size,
    float progress,
    float2 tapLocation
) {
    // Calculate distance from tap location
    float dist = distance(position, tapLocation);
    
    // Maximum radius for the effect
    float maxRadius = sqrt(size.x * size.x + size.y * size.y);
    
    // Normalize distance
    float normalizedDist = dist / maxRadius;
    
    // Create ripple wave
    float rippleFrequency = 20.0;
    float rippleAmplitude = 8.0;
    
    // Wave travels outward with progress
    float wave = sin((normalizedDist - progress) * rippleFrequency);
    
    // Fade out the effect at edges and based on progress
    float fadeFactor = smoothstep(0.0, 0.1, progress) * smoothstep(1.0, 0.8, progress);
    float distanceFade = smoothstep(progress * 1.4, progress * 1.2, normalizedDist);
    
    // Calculate distortion direction
    float2 direction = (position - tapLocation) / max(dist, 0.001);
    float distortion = wave * rippleAmplitude * fadeFactor * distanceFade;
    
    // Return the distorted position
    float2 distortedPos = position + direction * distortion;
    
    return distortedPos;
}

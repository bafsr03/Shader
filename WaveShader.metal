#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Enhanced wave transition with ripple effect
[[ stitchable ]] half4 waveTransition(
    float2 position,
    SwiftUI::Layer layer,
    float2 touchPos,
    float waveRadius,
    float time,
    float amplitude,
    float frequency,
    float decay,
    float speed
) {
    // Calculate distance from touch point
    float distance = length(position - touchPos);
    
    // How long it takes for ripple to reach this pixel
    float delay = distance / speed;
    
    // Adjust time for delay
    float localTime = time - delay;
    localTime = max(0.0, localTime);
    
    // Ripple effect: sine wave with exponential decay
    float rippleAmount = amplitude * sin(frequency * localTime) * exp(-decay * localTime);
    
    // Direction vector from touch point
    float2 direction = normalize(position - touchPos);
    
    // Calculate displaced position for sampling
    float2 samplePosition = position + rippleAmount * direction;
    
    // Smooth edge for the reveal circle
    float edgeWidth = 40.0;
    float alpha = smoothstep(waveRadius - edgeWidth, waveRadius + edgeWidth, distance);
    
    // Add ripple to the alpha mask
    alpha += rippleAmount * 0.02;
    alpha = saturate(alpha);
    
    // Sample the layer at displaced position
    half4 color = layer.sample(samplePosition);
    
    // Apply alpha mask (inside wave = transparent, outside = opaque)
    color.a *= half(alpha);
    
    // Add highlight at wave front (based on distance from wave edge)
    float edgeDistance = abs(distance - waveRadius);
    float highlight = exp(-edgeDistance / 20.0) * 0.5;
    
    // Brighten/darken based on ripple amount
    color.rgb += half3(rippleAmount / amplitude * 0.3) * color.a;
    color.rgb += half3(highlight) * (1.0 - alpha);
    
    return color;
}

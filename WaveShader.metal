#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Helper noise function for more organic water feel
float hash12(float2 p) {
    float3 p3  = fract(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f*f*(3.0-2.0*f);
    return mix( mix( hash12(i + float2(0.0,0.0)),
                     hash12(i + float2(1.0,0.0)), u.x),
                mix( hash12(i + float2(0.0,1.0)),
                     hash12(i + float2(1.0,1.0)), u.x), u.y);
}

// Enhanced wave transition with ripple effect based on mask edges
[[ stitchable ]] half4 waveTransition(
    float2 position,
    SwiftUI::Layer layer,
    float time,
    float speed
) {
    // 1. Sample current alpha to determine "water" area vs "land"
    // Since we blur the mask heavily in SwiftUI, alpha gives us a 0..1 gradient
    // 1.0 = deep water, 0.0 = bone dry, 0.5 = shoreline
    half4 originalColor = layer.sample(position);
    float alpha = originalColor.a;

    // Optimization: if no water nearby, return early
    if (alpha <= 0.001) {
        return originalColor;
    }
    
    // 2. Simulate Expansion
    // "Dilate" the water: we map a lower alpha (e.g. 0.2) to full visibility (1.0)
    // effectively pushing the boundary outwards.
    // Use 'smoothstep' to create a new, harder edge from the soft blur
    // 'expansion' can be time-based if we tracked stroke time, but for now we just make the river "wide"
    float expandedAlpha = smoothstep(0.1, 0.9, alpha);
    
    // 3. Gentle Outward Ripples
    // We want waves travelling from High Alpha (center) to Low Alpha (edge).
    // The "distance" metric is (1.0 - alpha).
    // Wave equation: sin(Distance * Freq - Time * Speed)
    // Slower speed for realism.
    
    float waveDist = 1.0 - alpha; // 0 at center, 1 at edge
    float rippleFreq = 15.0; // How many ripples
    float rippleSpeed = 1.5; // SLOW movement for viscous water
    
    // Add some noise to the wave phase so it's not perfect rings
    float noiseVal = noise(position * 0.01);
    
    float ripplePhase = waveDist * rippleFreq - time * rippleSpeed + noiseVal * 2.0;
    float rippleHeight = sin(ripplePhase);
    
    
    // 4. Calculate Distortion
    // Calculate normal based on alpha gradient (downhill flow)
    float offset = 2.0;
    float alphaL = layer.sample(position - float2(offset, 0)).a;
    float alphaR = layer.sample(position + float2(offset, 0)).a;
    float alphaT = layer.sample(position - float2(0, offset)).a;
    float alphaB = layer.sample(position + float2(0, offset)).a;
    
    float2 gradient = float2(alphaR - alphaL, alphaB - alphaT);
    float2 normal = (length(gradient) > 0.001) ? normalize(gradient) : float2(0, 0);
    
    // Distort mostly near the "shore" (lower original alpha)
    // Strength fades in deep water
    float distortionStrength = 15.0 * (1.0 - alpha) * expandedAlpha; 
    
    float2 distortedPosition = position + normal * rippleHeight * distortionStrength;
    
    half4 disColor = layer.sample(distortedPosition);
    
    // Final Alpha Composition
    // We return the Expanded Alpha for the clipping mask, so the water appears wider than the brush
    disColor.a = expandedAlpha;
    
    return disColor;
}

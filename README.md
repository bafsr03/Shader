# Wave Transition Shader

A touch-responsive wave shader for SwiftUI that creates smooth transitions between images using Metal.

## Features

-  Dynamic wave effect following finger movement
-  Water-like distortion and ripple effects
-  GPU-accelerated with Metal
-  Threshold based transitions

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Metal-capable device

## Usage

Open `WaveShader.xcodeproj` in Xcode and run on the simulator or device.

**Interaction:**
- Drag across the screen to create a wave
- Drag >30% of screen to complete transition
- Release early to cancel

## Project Structure

```
├── WaveShader.metal          # Metal shader with wave effects
├── WaveShaderEffect.swift    # SwiftUI wrapper
├── ContentView.swift         # Main view with gestures
├── ShaderApp.swift          # App entry
└── Assets.xcassets/         # Sample images
```

## Customization

Edit parameters in `ContentView.swift`:

```swift
.waveTransition(
    touchPosition: touchPosition,
    waveRadius: waveRadius,
    waveIntensity: 0.08,    // Wave distortion amount
    blendProgress: blendProgress,
    waveFrequency: 0.12     # Ripple tightness
)
```

## How It Works

1. **Metal Shader**: Calculates wave propagation from touch point
2. **SwiftUI Bridge**: Exposes shader parameters to SwiftUI
3. **Gesture Handler**: Updates wave position and radius in real-time
4. **Transition Logic**: Completes or cancels based on drag distance

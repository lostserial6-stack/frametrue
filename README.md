# FrameTrue

**Time-weighted video orientation for mobile capture.**

FrameTrue is a small reference implementation for a simple UX rule:

> A video's presentation orientation should reflect how the device was held for most of the recording — not just a transient state near the start.

## The problem

A user can start recording while the phone is portrait, turn it landscape almost immediately, and then record nearly the entire clip landscape. A capture pipeline that chooses one presentation orientation too early can produce a file whose playback orientation does not reflect the dominant recording orientation.

FrameTrue observes device orientation for the complete recording session, accumulates **time** spent in portrait and landscape, and chooses one final presentation orientation when recording ends.

### Example

```text
0–3 s    portrait
3–60 s   landscape
-------------------
FrameTrue result: LANDSCAPE (95% confidence)
```

Nothing is trimmed. Nothing is cropped. Individual frames are not rotated. The first three seconds remain in the file.

## What FrameTrue is

- A tiny orientation-decision engine.
- Platform-neutral C++17 core.
- Reference adapters for Swift/iOS and Kotlin/Android.
- Intended for integration into an existing camera/capture pipeline.

## What FrameTrue is not

- A gallery app.
- A camera app.
- Scene recognition or AI.
- Horizon stabilization.
- Automatic trimming.
- Per-frame dynamic rotation.

## Algorithm

FrameTrue accumulates elapsed duration, not callback counts:

```text
portrait  = portrait + portraitUpsideDown
landscape = landscapeLeft + landscapeRight
```

Ambiguous states such as face-up / face-down are classified as `unknown` and do not vote.

The orientation with the greater accumulated classified duration wins. See [`spec/ALGORITHM.md`](spec/ALGORITHM.md).

## Why metadata instead of rotating frames?

Both major mobile platforms provide a way to store playback orientation as presentation metadata. Because FrameTrue only knows the winner after recording stops, the reference implementation records to a temporary file and then **remuxes** the encoded tracks into a final file with the chosen orientation metadata. No frame-by-frame rotation or intentional video re-encoding is required.

## Repository layout

```text
core/       C++17 decision engine
tests/      deterministic core tests
ios/        Swift reference tracker + AVFoundation integration notes
android/    Kotlin reference tracker + MediaMuxer integration notes
spec/       algorithm specification
```

## Build the core

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

## Integration model

```text
recording starts
      ↓
platform orientation source
      ↓
FrameTrue tracker accumulates durations
      ↓
recording stops
      ↓
FrameTrue chooses dominant orientation
      ↓
platform adapter remuxes to final file
with chosen presentation metadata
```

### iOS

Modern AVFoundation exposes `AVCaptureDevice.RotationCoordinator` for physical camera orientation. Since the final FrameTrue decision is made after recording, the iOS reference uses an `AVMutableCompositionTrack.preferredTransform` and `AVAssetExportPresetPassthrough` to finalize presentation metadata after capture.

### Android

`MediaMuxer.setOrientationHint()` stores a composition matrix for playback and must be set before `MediaMuxer.start()`. The Android reference therefore remuxes the already-encoded temporary recording into a final MP4 after FrameTrue chooses the winner.

## Status

**v0.1 — reference implementation.** The C++ core is testable and platform-independent. The iOS and Android folders show integration patterns, not complete camera applications.

Before production use, validate camera-sensor-relative degree mappings on the target devices and capture stack.

## Licensing and commercial use

FrameTrue is source-available under the Business Source License 1.1.

You may inspect, evaluate, test, study, and contribute to the project under the terms in [`LICENSE`](LICENSE). Production or commercial integration before the Change Date requires a separate written commercial license from the Licensor.

Examples of use that require a commercial agreement include:

- integration into a proprietary camera or gallery application;
- integration into mobile-device firmware or an operating-system media stack;
- distribution inside a paid, ad-supported, subscription, or otherwise commercial product;
- preinstallation on commercial hardware.

Commercial terms are negotiated case by case. See [`COMMERCIAL-LICENSE.md`](COMMERCIAL-LICENSE.md). For an initial inquiry, open a GitHub issue titled `Commercial licensing inquiry` and do not include confidential information.

## Name

**FrameTrue** is the working project name. No trademark rights are granted by the software license.

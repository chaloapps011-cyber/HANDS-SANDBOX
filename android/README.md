# Android MediaPipe bridge build notes

This module is a native Android plugin source package; it is deliberately not represented as a working desktop tracker. It uses CameraX front-camera image analysis and MediaPipe Tasks Hand Landmarker LIVE_STREAM mode. The Kotlin adapter exports a `HandsTracking` singleton to Godot with `start_tracking()`, `stop_tracking()`, `has_camera_permission()`, `request_camera_permission()`, `is_camera_running()` and `get_latest_frame()`.

## Build prerequisites

- Godot 4.3+ Android export templates and Android SDK/JDK for the matching Godot export template.
- Android Gradle Plugin 8.7.3, Kotlin 2.0.21, Android compile SDK 35, CameraX 1.4.2, and MediaPipe Tasks Vision 0.10.21 (resolved from Google Maven/Maven Central).
- The matching Godot Android plugin API AAR copied to `plugins/hands_tracking/libs/godot-lib.aar`.
- The official `hand_landmarker.task` model bundled as a plugin asset. Run `bash android/download_hand_landmarker_model.sh` from the repository root before building.

## Build and install

1. Run the model download script; review the model's source/license terms before redistribution.
2. Copy the `godot-lib` Android plugin API AAR from the exact Godot export template version into `android/plugins/hands_tracking/libs/godot-lib.aar`.
3. Build the Android library with Gradle using the Android project files here. Integrate the resulting AAR and its remote dependencies into Godot's Android custom build (`.godot/android/build`) and enable the plugin in the Android export preset. The plugin API and generated custom-build layout must match the installed Godot version.
4. Ensure the merged Android manifest requests `android.permission.CAMERA`, export, install, grant camera permission, then run on a physical Android device with a front camera.

## Data contract

`get_latest_frame()` returns a dictionary with `camera_active`, `timestamp_ms`, and `hands`. Each hand has `side` (`Left`/`Right` when MediaPipe provides it), `confidence`, and `landmarks`, an ordered array of 21 normalized `{x,y,z}` points in MediaPipe's image coordinate system. `scripts/input/hand_tracking_bridge.gd` emits `hands_updated(hands)` and shows a 3D green indicator only while a fresh frame includes a detected hand. Stale data is cleared after 750 ms. No gesture/button emulation or rendered hand models are included.

## Important validation limits

This repository change does not include a built AAR, Godot export preset, Android SDK, physical device, or model binary. The module has not been compiled or run here, so camera permission, Godot plugin API compatibility, model inference, thermals/FPS, and device compatibility remain unverified. Until the matching AAR/model/custom Android build is installed and tested on-device, the Godot project will report that native tracking is unavailable; it does not claim tracking is operational. Generic VR Box is a passive viewer and does not provide camera-based hand tracking; the phone's own front camera is the intended sensor.

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class GlobalCameraManager {
  static CameraController? _controller;
  static bool _isDisposing = false;
  static bool _isInitialized = false;

  /// 🔹 Get the current controller
  static CameraController? get controller => _controller;

  /// 🔹 Whether the camera is ready
  static bool get isInitialized =>
      _isInitialized && _controller?.value.isInitialized == true;

  /// 🔹 Initialize the camera safely
  static Future<CameraController?> initialize(CameraDescription description) async {
    if (_isDisposing) {
      debugPrint("⚠️ Waiting for camera to finish disposing...");
      await Future.delayed(const Duration(milliseconds: 200));
    }

    await dispose(); // Always ensure clean state

    try {
      final controller = CameraController(
        description,
        ResolutionPreset.max, // ✅ use max for best quality
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      _controller = controller;
      _isInitialized = true;

      debugPrint("✅ Camera initialized: ${description.lensDirection}");
      return _controller;
    } catch (e) {
      debugPrint("❌ Error initializing camera: $e");
      _isInitialized = false;
      return null;
    }
  }

  /// 🔹 Dispose safely (with locking)
  static Future<void> dispose() async {
    if (_controller == null || _isDisposing) return;

    _isDisposing = true;
    try {
      if (_controller!.value.isRecordingVideo) {
        await _controller!.stopVideoRecording();
      }
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }

      await _controller!.dispose();
      debugPrint("🧹 Camera disposed successfully");
    } catch (e) {
      debugPrint("⚠️ Camera dispose error: $e");
    } finally {
      _controller = null;
      _isInitialized = false;
      _isDisposing = false;
    }
  }
}

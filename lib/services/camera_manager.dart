import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class GlobalCameraManager {
  static CameraController? _controller;

  /// 🔹 Get the current controller if initialized
  static CameraController? get controller => _controller;

  /// 🔹 Initialize a camera safely (disposing previous if needed)
  static Future<CameraController?> initialize(CameraDescription description) async {
    await dispose(); // ensures only one active camera

    try {
      final controller = CameraController(
        description,
        ResolutionPreset.max,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      _controller = controller;
      debugPrint("🎥 Camera initialized: ${description.lensDirection}");
      return _controller;
    } catch (e) {
      debugPrint("❌ Error initializing camera: $e");
      return null;
    }
  }

  /// 🔹 Dispose safely — no matter what screen or state you’re in
  static Future<void> dispose() async {
    try {
      if (_controller != null) {
        // Stop image stream safely before disposing
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }

        // Give a tiny delay to ensure CameraX detaches observers
        await Future.delayed(const Duration(milliseconds: 100));

        // await _controller!.dispose();
        debugPrint("🧹 Camera disposed successfully");
      }
    } catch (e) {
      debugPrint("⚠️ Camera dispose error: $e");
    } finally {
      _controller = null;
    }
  }


  /// 🔹 Check if camera is initialized
  static bool get isInitialized => _controller?.value.isInitialized ?? false;
}

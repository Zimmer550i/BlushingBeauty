import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/bottom_menu..dart';
import 'package:ree_social_media_app/views/screen/Camera/AllSubScreen/video_edit_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isVideoMode = false;
  int _recordDuration = 0;
  Timer? _timer;
  bool _isCameraChanging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.cameras.isNotEmpty) {
      _initCamera(widget.cameras.first);
    }
  }

  /// 🔄 Lifecycle handling
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _disposeController();
        break;
      case AppLifecycleState.resumed:
        if (widget.cameras.isNotEmpty) {
          _initCamera(widget.cameras.first);
        }
        break;
      default:
        break;
    }
  }

  /// 📸 Initialize camera safely
  Future<void> _initCamera(CameraDescription description) async {
    if (_isCameraChanging) return;
    _isCameraChanging = true;

    try {
      await _disposeController();

      final controller = CameraController(
        description,
        ResolutionPreset.medium, // ✅ reduces buffer pressure
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420, // ✅ stable on Android
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
    } finally {
      _isCameraChanging = false;
    }
  }

  /// 🧹 Dispose controller safely
  Future<void> _disposeController() async {
    try {
      final oldController = _controller;
      _controller = null;
      if (oldController != null && oldController.value.isInitialized) {
        await oldController.dispose();
      }
    } catch (e) {
      debugPrint("Controller dispose error: $e");
    }

    // 🧠 Do NOT call setState() if the widget is already disposed
    // if (mounted) {
    //   setState(() {});
    // }
  }



  /// 🔄 Switch front/rear camera
  Future<void> _switchCamera() async {
    if (_controller == null || _isCameraChanging) return;

    final currentLens = _controller!.description.lensDirection;
    final newCamera = widget.cameras.firstWhere(
          (cam) => cam.lensDirection != currentLens,
      orElse: () => widget.cameras.first,
    );

    await _initCamera(newCamera);
  }

  /// 🎥 Capture or record
  Future<void> _onCapturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isVideoMode) {
      _isRecording ? await _stopVideoRecording() : await _startVideoRecording();
    } else {
      await _takePhoto();
    }
  }

  /// 📷 Take Photo
  Future<void> _takePhoto() async {
    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;

      final path = file.path;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditScreen(filePath: path, isVideo: false),
        ),
      );

      // 🧠 Dispose camera after navigation, safely
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _disposeController();
      });

    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }


  /// ▶️ Start Recording
  Future<void> _startVideoRecording() async {
    if (_controller == null || _controller!.value.isRecordingVideo) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });
      _startTimer();
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  /// ⏹ Stop Recording
  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    try {
      final file = await _controller!.stopVideoRecording();
      _stopTimer();
      setState(() => _isRecording = false);

      final path = file.path;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditScreen(filePath: path, isVideo: true),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _disposeController();
      });

    } catch (e) {
      debugPrint('Error stopping video recording: $e');
    }
  }


  /// ⏱ Timer Control
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _recordDuration = 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _disposeController();
    super.dispose();
  }

  /// 🧱 UI Build
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// Camera Preview
          if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Positioned.fill(
              child: ColoredBox(color: Colors.black),
            ),


          /// Camera / Video toggle
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                _buildModeButton('assets/icons/camera.svg', !_isVideoMode, () {
                  setState(() => _isVideoMode = false);
                }),
                const SizedBox(width: 12),
                _buildModeButton('assets/icons/video_cam.svg', _isVideoMode, () {
                  setState(() => _isVideoMode = true);
                }),
              ],
            ),
          ),

          /// Timer display
          if (_isVideoMode)
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isRecording ? "${_recordDuration}s" : "00s",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

          /// Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGalleryButton(),
                _buildCaptureButton(),
                _buildSwitchButton(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomMenu(1),
    );
  }

  /// 🎚 Mode button
  Widget _buildModeButton(String asset, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primaryColor : Colors.white30,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset(asset),
        ),
      ),
    );
  }

  /// 🖼 Gallery Button
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
          image: const DecorationImage(
            image: AssetImage("assets/images/dummy.jpg"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 📸 Capture / Record button
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _onCapturePressed,
      child: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isRecording ? Colors.red : Colors.white30,
            width: 4,
          ),
        ),
      ),
    );
  }

  /// 🔁 Switch camera button
  Widget _buildSwitchButton() {
    return InkWell(
      onTap: _switchCamera,
      child: Container(
        height: 48,
        width: 48,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset('assets/icons/camera_swithc.svg'),
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/bottom_menu.dart';
import 'package:ree_social_media_app/views/screen/Camera/AllSubScreen/video_edit_screen.dart';

import '../../../services/camera_manager.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isChatBox;
  final String? chatId;
  const CameraScreen({
    super.key,
    required this.cameras,
    required this.isChatBox, this.chatId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, RouteAware {
  final ChatController chatController = Get.put(ChatController());
  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;
  bool _isVideoMode = false;
  int _recordDuration = 0;
  Timer? _timer;
  bool _isCameraChanging = false;

  CameraController? get _controller => GlobalCameraManager.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.cameras.isNotEmpty) {
      _initCamera(widget.cameras.first);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    GlobalCameraManager.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // When navigating to another screen, release camera resources
    GlobalCameraManager.dispose();
  }

  @override
  void didPopNext() async {
    // When coming back to this screen, reinitialize the camera
    if (widget.cameras.isNotEmpty) {
      await _initCamera(widget.cameras.first);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Handle camera on app pause/resume (e.g., minimize / reopen app)
    if (_controller == null || !_controller!.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        await GlobalCameraManager.dispose();
        break;
      case AppLifecycleState.resumed:
        if (widget.cameras.isNotEmpty) {
          await _initCamera(widget.cameras.first);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    if (_isCameraChanging) return;
    _isCameraChanging = true;

    await GlobalCameraManager.dispose();

    final controller = await GlobalCameraManager.initialize(description);

    if (mounted && controller != null && controller.value.isInitialized) {
      setState(() {});
    }

    _isCameraChanging = false;
  }

  Future<void> _switchCamera() async {
    if (_controller == null || _isCameraChanging) return;

    final currentLens = _controller!.description.lensDirection;
    final newCamera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection != currentLens,
      orElse: () => widget.cameras.first,
    );
    await _initCamera(newCamera);
  }

  Future<void> _onCapturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isVideoMode) {
      _isRecording ? await _stopVideoRecording() : await _startVideoRecording();
    } else {
      await _takePhoto();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditScreen(
            filePath: file.path,
            isVideo: false,
            isChatBox: widget.isChatBox,
            chatId: widget.chatId,
          ),
        ),
      );

      // ✅ Reinitialize after coming back
      if (widget.cameras.isNotEmpty) {
        await _initCamera(_controller?.description ?? widget.cameras.first);
      }
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
    }
  }

  Future<void> openGallery() async {
    try {
      // Temporarily dispose camera to release resource for picker
      await GlobalCameraManager.dispose();

      // Open image picker
      final XFile? xfile = await _picker.pickImage(source: ImageSource.gallery);

      if (!mounted) return;

      if (xfile != null) {
        // ✅ If an image is selected
        final file = File(xfile.path);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoEditScreen(
              filePath: file.path,
              isVideo: false,
              isChatBox: widget.isChatBox,
              chatId: widget.chatId,
            ),
          ),
        );
      }

      // ✅ Always reinitialize camera after picker closes — even if cancelled
      if (widget.cameras.isNotEmpty) {
        await _initCamera(widget.cameras.first);
        setState(() {}); // refresh UI to restore buttons
      }
    } catch (e) {
      debugPrint("⚠️ Error opening gallery: $e");

      // Safety net: try reinit anyway
      if (widget.cameras.isNotEmpty) {
        await _initCamera(widget.cameras.first);
      }
    }
  }

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

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;
    try {
      final file = await _controller!.stopVideoRecording();
      _stopTimer();
      setState(() => _isRecording = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditScreen(
            filePath: file.path,
            isVideo: true,
            isChatBox: widget.isChatBox,
            chatId: widget.chatId,
          ),
        ),
      );

      // ✅ Reinitialize after returning
      if (widget.cameras.isNotEmpty) {
        await _initCamera(_controller?.description ?? widget.cameras.first);
      }
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
    }
  }

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
  Widget build(BuildContext context) {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_controller!.value.isPreviewPaused) {
      if (!GlobalCameraManager.isInitialized) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Camera Preview
          if (_controller != null && _controller!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            const Positioned.fill(child: ColoredBox(color: Colors.black)),

          if (widget.isChatBox)
            Positioned(
              top: 70,
              left: 20,
              child: InkWell(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: AppColors.primaryColor),
                ),
              ),
            ),

          /// Camera / Video toggle
          Positioned(
            top: 70,
            right: 20,
            child: Row(
              children: [
                _buildModeButton('assets/icons/camera.svg', !_isVideoMode, () {
                  setState(() => _isVideoMode = false);
                }),
                const SizedBox(width: 12),
                _buildModeButton(
                  'assets/icons/video_cam.svg',
                  _isVideoMode,
                  () {
                    setState(() => _isVideoMode = true);
                  },
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
      bottomNavigationBar: widget.isChatBox ? SizedBox() : BottomMenu(1),
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
          color: active ? AppColors.primaryColor : Colors.white38,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset(
            asset,
            color: active ? Colors.white : AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  /// 🖼 Gallery Button
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: () => openGallery(),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // border: Border.all(color: AppColors.primaryColor, width: 2),
          color: AppColors.primaryColor,
        ),
        child: Icon(Icons.photo, color: Colors.white, size: 24),
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

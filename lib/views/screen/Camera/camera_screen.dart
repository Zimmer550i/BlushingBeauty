import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/flutter_svg.dart';


import 'package:ree_social_media_app/views/base/bottom_menu..dart';
import 'package:ree_social_media_app/views/screen/Camera/AllSubScreen/video_edit_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isVideoMode = false; //
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera(widget.cameras[0]);
  }

  Future<void> _initCamera(CameraDescription description) async {
    _controller?.dispose();
    _controller = CameraController(description, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    final lensDirection = _controller!.description.lensDirection;
    CameraDescription newCamera = widget.cameras.firstWhere(
          (camera) => camera.lensDirection != lensDirection,
      orElse: () => widget.cameras[0],
    );
    _initCamera(newCamera);
  }

  Future<void> _onCapturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isVideoMode) {
      if (_isRecording) {
        await _stopVideoRecording();
      } else {
        await _startVideoRecording();
      }
    } else {
      await _takePhoto();
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      XFile file = await _controller!.takePicture();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditScreen(filePath: file.path, isVideo: false),
        ),
      );
    } catch (e) {
      print('Error capturing photo: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller!.value.isRecordingVideo) return;
    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      _recordDuration = 0;
      _startTimer();
      setState(() {});
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_controller!.value.isRecordingVideo) return;
    try {
      XFile file = await _controller!.stopVideoRecording();
      _isRecording = false;
      _stopTimer();
      setState(() {});

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditScreen(filePath: file.path, isVideo: true),
        ),
      );
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _recordDuration = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),


          /// Top buttons (Camera / Video)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                /// Camera icon
                GestureDetector(
                  onTap: () {
                    setState(() => _isVideoMode = false);
                  },
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: !_isVideoMode
                          ? Colors.greenAccent
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/camera.svg'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                /// Video icon
                GestureDetector(
                  onTap: () {
                    setState(() => _isVideoMode = true);

                    /// Show Snackbar when video mode is activated
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Video recording mode activated'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isVideoMode ? Colors.redAccent : Colors.white.withValues(alpha: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/video_cam.svg'),
                    ),
                  ),
                ),
              ],
            ),
          ),


          /// Timer (for video)
          if (_isVideoMode)
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isRecording
                        ? "${_recordDuration.toString().padLeft(2, '0')} sec"
                        : "00 sec",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

          /// Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Dummy Gallery
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFFD8EBD7), width: 2),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/dummy.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Capture / Record button
                GestureDetector(
                  onTap: _onCapturePressed,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isRecording ? Colors.red : Color(0xFFBCDDB9),
                        width: 4,
                      ),
                    ),
                  ),
                ),

                // Switch camera
                InkWell(
                  onTap: _switchCamera,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF676565),
                    ),
                    child: const Icon(Icons.cameraswitch, size: 32, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomMenu(1),
    );
  }
}

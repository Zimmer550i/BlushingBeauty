import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/services/camera_manager.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:video_player/video_player.dart';
import '../../../Camera/AllSubScreen/send_message_with_friend_screen.dart';
import 'fram_selection_screen.dart';

class SendOrTrimVideoScreen extends StatefulWidget {
  final String videoUrl;
  final String userProfile;
  final String userName;

  const SendOrTrimVideoScreen({
    super.key,
    required this.videoUrl,
    required this.userProfile,
    required this.userName,
  });

  @override
  State<SendOrTrimVideoScreen> createState() => _SendOrTrimVideoScreenState();
}

class _SendOrTrimVideoScreenState extends State<SendOrTrimVideoScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  Duration _videoDuration = Duration.zero;
  Duration _videoPosition = Duration.zero;
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  bool _isRecording = false;
  String? _frontCameramainVideo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    GlobalCameraManager.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  // ===============================
  // 🔹 INITIAL SETUP FLOW
  // ===============================
  Future<void> _initializeFlow() async {
    await _initializeCameraSafely();
    await _initializeVideo();

    if (_videoController == null || !_videoController!.value.isInitialized) {
      debugPrint("⚠️ Video not initialized.");
      return;
    }

    await _startCameraRecording();
    await _videoController!.play();

    // When background video finishes, stop recording automatically
    _videoController!.addListener(() async {
      if (!_videoController!.value.isPlaying &&
          _videoController!.value.position >=
              _videoController!.value.duration &&
          _isRecording) {
        await _stopCameraRecordingOnly();
      }
    });
  }

  // ===============================
  // 🔹 CAMERA & VIDEO SETUP
  // ===============================
  Future<void> _initializeCameraSafely() async {
    try {
      await GlobalCameraManager.dispose();
      await Future.delayed(const Duration(milliseconds: 150));

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      await GlobalCameraManager.initialize(frontCamera);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("❌ Camera initialization failed: $e");
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = widget.videoUrl.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          : VideoPlayerController.file(File(widget.videoUrl));

      await _videoController!.initialize();
      _videoDuration = _videoController!.value.duration;
      _videoController!.setLooping(false);

      _videoController!.addListener(() {
        if (!mounted) return;
        _videoPosition = _videoController!.value.position;
        _isPlaying.value = _videoController!.value.isPlaying;
        setState(() {});
      });
    } catch (e) {
      debugPrint("❌ Video initialization failed: $e");
    }
  }

  Future<void> _startCameraRecording() async {
    if (_isRecording) return;
    try {
      final controller = GlobalCameraManager.controller;
      if (controller == null || !controller.value.isInitialized) return;

      await controller.startVideoRecording();
      setState(() => _isRecording = true);
      debugPrint("🎥 Front camera recording started");
    } catch (e) {
      debugPrint("❌ Error starting camera recording: $e");
    }
  }

  Future<void> _stopCameraRecordingOnly() async {
    try {
      final controller = GlobalCameraManager.controller;
      if (controller != null && controller.value.isRecordingVideo) {
        final XFile recordedFile = await controller.stopVideoRecording();
        _frontCameramainVideo = recordedFile.path;
        setState(() => _isRecording = false);
        debugPrint("✅ Reaction video recorded: $_frontCameramainVideo");
      }
    } catch (e) {
      debugPrint("❌ Error stopping camera recording: $e");
    }
  }

  // ===============================
  // 🔹 NAVIGATION HANDLER
  // ===============================
  Future<void> _stopRecordingAndNavigate(
  Function(String mainVideo, String frontVideo) onNavigate,
) async {
  try {
    // Pause background video playback
    await _videoController?.pause();

    final controller = GlobalCameraManager.controller;

    // Stop front camera recording if active
    if (_isRecording &&
        controller != null &&
        controller.value.isRecordingVideo) {
      final XFile recordedFile = await controller.stopVideoRecording();
      _frontCameramainVideo = recordedFile.path;
      if (mounted) setState(() => _isRecording = false);
      debugPrint("✅ Reaction video recorded: $_frontCameramainVideo");
    }

    final mainVideo = widget.videoUrl;
    final frontVideo = _frontCameramainVideo ?? '';

    // ✅ Safely navigate *after* build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigate(mainVideo, frontVideo);
    });
  } catch (e) {
    debugPrint("⚠️ Stop recording error: $e");

    final mainVideo = widget.videoUrl;
    final frontVideo = _frontCameramainVideo ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigate(mainVideo, frontVideo);
    });
  }
}



  // ===============================
  // 🔹 LIFECYCLE HANDLING
  // ===============================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final controller = GlobalCameraManager.controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive) {
      await controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      await _initializeCameraSafely();
    }
  }

  // ===============================
  // 🔹 UI HELPERS
  // ===============================
  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // ===============================
  // 🔹 MAIN UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final camController = GlobalCameraManager.controller;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: Get.back,
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundImage: NetworkImage(widget.userProfile),
              radius: 22,
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (camController?.value.isInitialized == true)
                      Positioned.fill(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: camController!.value.previewSize!.height,
                            height: camController.value.previewSize!.width,
                            child: CameraPreview(camController),
                          ),
                        ),
                      ),
                    if (_videoController?.value.isInitialized == true)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildMiniVideoPreview(),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildPlaybackControls(),
                    ),
                  ],
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🔹 MINI VIDEO PREVIEW
  // ===============================
  Widget _buildMiniVideoPreview() => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 130,
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    ),
  );

  // ===============================
  // 🔹 BOTTOM ACTIONS
  // ===============================
  Widget _buildBottomActions() => Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
      child: Column(
        children: [
          // 🎬 Frame Selection Button
          InkWell(
            onTap: () async {
              await _stopRecordingAndNavigate((mainVideo, frontVideo) {
                Get.to(() => FrameSelectionScreen(
                      videoUrl: mainVideo,
                      userProfile: widget.userProfile,
                      userName: widget.userName,
                      frontVideoUrl: frontVideo,
                    ));
              });
            },
            child: _buildTrimButton(),
          ),

          const SizedBox(height: 20),

          // 🚀 Send Now Button
          CustomButton(
            onTap: () async {
              await _stopRecordingAndNavigate((mainVideo, frontVideo) {
                Get.to(() => SendMessageWithFriendScreen(
                      isVideo: true,
                      filePath: frontVideo,
                    ));
              });
            },
            text: "Send Now",
          ),
        ],
      ),
    );



  Widget _buildTrimButton() => Container(
    width: double.infinity,
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    ),
    child: const Center(
      child: Text(
        "Trim or Select Frame",
        style: TextStyle(
          color: Color(0xFF413E3E),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  // ===============================
  // 🔹 PLAYBACK CONTROLS
  // ===============================
  Widget _buildPlaybackControls() {
    final total = _videoDuration.inMilliseconds.toDouble().clamp(
      1,
      double.infinity,
    );
    final current = _videoPosition.inMilliseconds.toDouble().clamp(0, total);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.24)),
      child: Row(
        children: [
          Text(
            _formatDuration(_videoPosition),
            style: const TextStyle(color: Colors.black),
          ),
          Expanded(
            child: Slider(
              value: double.parse(current.toStringAsFixed(0)),
              min: 0,
              max: double.parse(total.toStringAsFixed(0)),
              activeColor: AppColors.primaryColor,
              inactiveColor: Colors.grey,
              onChanged: (v) =>
                  _videoController?.seekTo(Duration(milliseconds: v.toInt())),
            ),
          ),
          Text(
            _formatDuration(_videoDuration),
            style: const TextStyle(color: Colors.black),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, __) => CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: AppColors.primaryColor,
                ),
                onPressed: () async {
                  if (playing) {
                    await _videoController?.pause();
                  } else {
                    await _videoController?.play();
                  }
                  _isPlaying.value = _videoController?.value.isPlaying ?? false;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

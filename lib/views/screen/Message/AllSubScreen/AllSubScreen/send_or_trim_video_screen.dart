import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/services/camera_manager.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:video_player/video_player.dart';

import '../../../Camera/AllSubScreen/send_message_with_friend_screen.dart';
import '../../../Camera/AllSubScreen/video_trim_screen.dart';

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
  VideoPlayerController? _video;
  Duration _videoDuration = Duration.zero;
  Duration _position = Duration.zero;
  late final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFlow();
  }

  /// ================================
  /// 🔹 Full Flow Initialization
  /// ================================
  Future<void> _initFlow() async {
    await _requestPermissions();
    await _initCameraSafely();
    await _initVideo();
    await _startVideo();
  }

  /// ================================
  /// 🔹 Request Permissions
  /// ================================
  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera & Microphone permission required')),
        );
        Get.back();
      }
    }
  }

  /// ================================
  /// 🔹 Initialize Camera Safely
  /// ================================
  Future<void> _initCameraSafely() async {
    try {
      await GlobalCameraManager.dispose(); // dispose old instances safely
      await Future.delayed(const Duration(milliseconds: 150));

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = await GlobalCameraManager.initialize(frontCamera);
      if (controller == null) {
        debugPrint("⚠️ Failed to initialize camera");
        return;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("❌ Camera init failed: $e");
    }
  }

  /// ================================
  /// 🔹 Initialize Video Player
  /// ================================
  Future<void> _initVideo() async {
    _video = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));

    await _video!.initialize();
    _videoDuration = _video!.value.duration;
    _video!.setLooping(false);

    _video!.addListener(() {
      if (!mounted) return;
      _position = _video!.value.position;
      _isPlaying.value = _video!.value.isPlaying;
      setState(() {});
    });
  }

  Future<void> _startVideo() async {
    if (_video != null && _video!.value.isInitialized) {
      await _video!.play();
    }
  }

  /// ================================
  /// 🔹 Handle Lifecycle Changes
  /// ================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final controller = GlobalCameraManager.controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive) {
      await controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      await _initCameraSafely();
    }
  }

  /// ================================
  /// 🔹 Cleanup
  /// ================================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.dispose();
    GlobalCameraManager.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  /// ================================
  /// 🔹 Helpers
  /// ================================
  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _safeStopBeforeNavigate(Function onNavigate) async {
    try {
      // 1️⃣ Stop video playback
      if (_video?.value.isPlaying == true) await _video?.pause();

      // 2️⃣ Dispose camera safely
      if (GlobalCameraManager.isInitialized) {
        await GlobalCameraManager.dispose();
        debugPrint("🎯 Camera fully disposed before navigating");
      }

      // 3️⃣ Wait for next frame to ensure native release
      await Future.delayed(const Duration(milliseconds: 300));

      // 4️⃣ Schedule navigation on next frame (safe for UI)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onNavigate();
      });
    } catch (e) {
      debugPrint("⚠️ Error before navigation: $e");
      if (mounted) onNavigate(); // fallback
    }
  }


  /// ================================
  /// 🔹 UI
  /// ================================
  @override
  Widget build(BuildContext context) {
    final camController = GlobalCameraManager.controller;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(onTap: Get.back, child: const Icon(Icons.arrow_back, color: Color(0xFF0D1C12))),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundImage: NetworkImage(widget.userProfile),
              radius: 22,
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: const TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Front camera (background)
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

                /// PiP video overlay
                if (_video != null && _video!.value.isInitialized)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 129,
                      height: 159,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.24),
                        border: Border.all(color: const Color(0xFF383838), width: 4),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _video!.value.size.width,
                          height: _video!.value.size.height,
                          child: VideoPlayer(_video!),
                        ),
                      ),
                    ),
                  ),

                /// Controls
                Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomControls()),
              ],
            ),
          ),

          /// Bottom actions
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    await _safeStopBeforeNavigate(() {
                      Get.to(() => VideoTrimAndSendScreen(videoUrl: widget.videoUrl));
                    });
                  },
                  child: _buildTrimButton(),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  onTap: () async {
                    await _safeStopBeforeNavigate(() {
                      Get.to(() => SendMessageWithFriendScreen(
                        filePath: widget.videoUrl,
                        isVideo: true,
                      ));
                    });
                  },
                  text: "Send Now",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimButton() => Container(
    width: double.infinity,
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFC4C3C3), width: 0.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF002329).withValues(alpha: 0.07),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    ),
    child: const Center(
      child: Text(
        "Trim",
        style: TextStyle(
          color: Color(0xFF413E3E),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _buildBottomControls() {
    final total = _videoDuration.inMilliseconds.toDouble().clamp(1, double.infinity);
    final value = _position.inMilliseconds.toDouble().clamp(0, total);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.24)),
      child: Row(
        children: [
          Text(_fmt(_position), style: const TextStyle(color: Color(0xFF413E3E))),
          Expanded(
            child: Slider(
              value: double.parse(value.toString()),
              min: 0,
              max: double.parse(total.toString()),
              activeColor: const Color(0xFF413E3E),
              inactiveColor: const Color(0xFF413E3E),
              thumbColor: const Color(0xFFD9D9D9),
              onChanged: (v) => _video?.seekTo(Duration(milliseconds: v.toInt())),
            ),
          ),
          Text(_fmt(_videoDuration), style: const TextStyle(color: Color(0xFF413E3E))),
          const SizedBox(width: 12),
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, __) => CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: AppColors.primaryColor),
                onPressed: () async {
                  if (playing) {
                    await _video?.pause();
                  } else {
                    await _video?.play();
                  }
                  _isPlaying.value = _video?.value.isPlaying ?? false;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

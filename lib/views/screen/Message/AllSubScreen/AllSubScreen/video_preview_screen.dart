import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/send_or_trim_video_screen.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.videoUrl,
    this.countdownSeconds = 3,
    required this.userProfile,
    required this.userName,this.chatId,
  });

  final String videoUrl;
  final String userProfile;
  final String userName;
  final String? chatId;
  final int countdownSeconds;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  CameraController? _frontCam;
  VideoPlayerController? _video;
  Timer? _countdownTimer;

  int _secondsRemaining = 3;
  bool _isRecording = false;
  XFile? _recordedFile;

  Duration _videoDuration = Duration.zero;
  Duration _position = Duration.zero;

  late final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  late final VoidCallback _videoListener;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.countdownSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFlow());
  }

  Future<void> _initFlow() async {
    await _requestPermissions();
    await _initFrontCamera();
    await _initVideo();
    _startCountdown();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera & Microphone permission required'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initFrontCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _frontCam = CameraController(front, ResolutionPreset.medium, enableAudio: true);
    await _frontCam!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initVideo() async {
    _video = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));

    await _video!.initialize();
    _videoDuration = _video!.value.duration;
    _video!.setLooping(false);

    _videoListener = () {
      if (!mounted) return;
      setState(() {
        _position = _video!.value.position;
        _isPlaying.value = _video!.value.isPlaying;
      });
    };

    _video!.addListener(_videoListener);
    if (mounted) setState(() {});
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 1) {
        t.cancel();
        _onCountdownComplete();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _onCountdownComplete() async {
    setState(() => _secondsRemaining = 0);
    await _startBackgroundVideo();
    await _startFrontRecording();
  }

  Future<void> _startBackgroundVideo() async {
    if (_video != null && _video!.value.isInitialized) {
      await _video!.play();
    }
  }

  Future<void> _startFrontRecording() async {
  if (_frontCam == null || !_frontCam!.value.isInitialized) return;

  // Prevent multiple recordings
  if (_frontCam!.value.isRecordingVideo) return;

  try {
    setState(() => _isRecording = true);
    await _frontCam!.startVideoRecording();
    debugPrint("🎬 Front camera recording started");
  } catch (e) {
    debugPrint("⚠️ Failed to start recording: $e");
    setState(() => _isRecording = false);
  }
}


  Future<void> _stopRecordingIfNeeded() async {
  if (_frontCam?.value.isRecordingVideo == true) {
    try {
      final file = await _frontCam?.stopVideoRecording();
      _recordedFile = file;
      debugPrint("🎥 Recording saved at: ${file?.path}");
    } catch (e) {
      debugPrint("⚠️ Stop recording failed: $e");
    } finally {
      setState(() => _isRecording = false);
    }
  }
}


  @override
  void dispose() {
    _countdownTimer?.cancel();
    _video?.removeListener(_videoListener);
    _video?.dispose();
    _stopRecordingIfNeeded();
    _frontCam?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final videoReady = _video?.value.isInitialized == true;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back, color: Color(0xFF0D1C12)),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(widget.userProfile),
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: const TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: videoReady
          ? Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _video!.value.size.width,
                      height: _video!.value.size.height,
                      child: VideoPlayer(_video!),
                    ),
                  ),
                ),

                /// Countdown Overlay
                if (_secondsRemaining > 0) _buildCountdownOverlay(),

                /// PiP front camera
                if (_frontCam?.value.isInitialized == true)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 130,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: CameraPreview(_frontCam!),
                    ),
                  ),

                /// Bottom controls
                if (_secondsRemaining == 0) _buildBottomControls(),
              ],
            )
          : Center(
              child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
            ),
    );
  }

  Widget _buildCountdownOverlay() => Positioned.fill(
        child: Stack(
          alignment: Alignment.center,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF383838),
                  child: Text(
                    '$_secondsRemaining',
                    style: const TextStyle(
                      fontSize: 64,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Starting in $_secondsRemaining...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF383838),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildBottomControls() {
    final total = _videoDuration.inMilliseconds.toDouble().clamp(1, double.infinity);
    final value = _position.inMilliseconds.toDouble().clamp(0, total);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        color: Colors.black.withOpacity(0.3),
        child: Row(
          children: [
            Text(_fmt(_position), style: const TextStyle(color: Colors.white)),
            Expanded(
              child: Slider(
                value: double.parse(value.toStringAsFixed(0)),
                min: 0,
                max: double.parse(total.toStringAsFixed(0)),
                activeColor: Colors.white,
                onChanged: (v) => _video?.seekTo(Duration(milliseconds: v.toInt())),
              ),
            ),
            Text(_fmt(_videoDuration), style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 12),
            ValueListenableBuilder<bool>(
              valueListenable: _isPlaying,
              builder: (_, playing, __) => IconButton(
                icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
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
            const SizedBox(width: 18),
            InkWell(
              onTap: () async {
                await _stopRecordingIfNeeded();
                if (!mounted) return;
                Get.to(() => SendOrTrimVideoScreen(
                      videoUrl: widget.videoUrl,
                      userProfile: widget.userProfile,
                      userName: widget.userName,
                      chatId: widget.chatId.toString(),
                    ));
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.navigate_next, color: AppColors.primaryColor, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

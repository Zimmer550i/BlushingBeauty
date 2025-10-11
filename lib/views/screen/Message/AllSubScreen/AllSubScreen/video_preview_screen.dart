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
    required this.userName,
  });

  final String videoUrl;
  final String userProfile;
  final String userName;
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
    _initFlow();
  }

  Future<void> _initFlow() async {
    await _requestPermissions();
    await _initFrontCamera();
    await _initVideo();
    _startCountdown();
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
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
    _frontCam = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: true,
    );
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
    if (_frontCam != null && _frontCam!.value.isInitialized) {
      if (_frontCam!.value.isRecordingVideo) return;
      setState(() => _isRecording = true);
      await _frontCam!.startVideoRecording();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _video?.removeListener(_videoListener);
    _video?.dispose();

    () async {
      try {
        if (_frontCam?.value.isRecordingVideo == true) {
          await _frontCam?.stopVideoRecording();
        }
      } catch (_) {}
      _frontCam?.dispose();
    }();

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
              onTap: Get.back,
              child: const Icon(Icons.arrow_back, color: Color(0xFF0D1C12)),
            ),
            const SizedBox(width: 12),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(widget.userProfile),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: videoReady
          ? Column(
              children: [
                Expanded(
                  child: Stack(
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
                          top: 1,
                          right: 1,
                          child: Container(
                            width: 129,
                            height: 159,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.24),
                              border: Border.all(
                                color: const Color(0xFF383838),
                                width: 4,
                              ),
                            ),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: CameraPreview(_frontCam!),
                          ),
                        ),

                      /// Bottom controls
                      if (_secondsRemaining == 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildBottomControls(),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Center(child: SpinKitWave(color: AppColors.primaryColor, size: 30.0)),
    );
  }

  Widget _buildCountdownOverlay() {
    return Positioned.fill(
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
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF383838),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 4,
                  ),
                ),
                alignment: Alignment.center,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Media will show after $_secondsRemaining seconds',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF383838),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final total = _videoDuration.inMilliseconds.toDouble().clamp(
      1,
      double.infinity,
    );
    final value = _position.inMilliseconds.toDouble().clamp(0, total);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.24)),
      child: Row(
        children: [
          Text(
            _fmt(_position),
            style: const TextStyle(color: Color(0xFF413E3E), fontSize: 14),
          ),
          Expanded(
            child: Slider(
              value: double.parse(value.toString()),
              min: 0,
              max: double.parse(total.toString()),
              activeColor: const Color(0xFF413E3E),
              inactiveColor: const Color(0xFF413E3E),
              thumbColor: const Color(0xFFD9D9D9),
              onChanged: (v) =>
                  _video?.seekTo(Duration(milliseconds: v.toInt())),
            ),
          ),
          Text(
            _fmt(_videoDuration),
            style: const TextStyle(color: Color(0xFF413E3E), fontSize: 14),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, __) {
              return CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () async {
                    if (playing) {
                      await _video?.pause();
                    } else {
                      await _video?.play();
                    }
                    _isPlaying.value = _video?.value.isPlaying ?? false;
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 18),
          InkWell(
            onTap: () {
              Get.to(
                () => SendOrTrimVideoScreen(
                  videoUrl: widget.videoUrl,
                  userProfile: widget.userProfile,
                  userName: widget.userName,
                ),
              );
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                Icons.navigate_next,
                size: 30,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

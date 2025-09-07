import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.videoUrl,
    this.countdownSeconds = 3,
 // optional avatar image provider
  });

  final String videoUrl;
  final int countdownSeconds;


  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  CameraController? _frontCam;
  VideoPlayerController? _video;

  int _secondsRemaining = 3;
  Timer? _countdownTimer;

  bool _isRecording = false;
  XFile? _recordedFile;

  Duration _videoDuration = Duration.zero;
  Duration _position = Duration.zero;
  late final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.countdownSeconds;
    _initFlow();
  }

  Future<void> _initFlow() async {
    /// 1) Permissions
    await _requestPermissions();

    /// 2) Init front camera
    await _initFrontCamera();

    /// 3) Init background video
    await _initVideo();

    /// 4) Start countdown
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
      }

      if (mounted) Navigator.pop(context);
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
    if (widget.videoUrl.startsWith('http')) {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    } else {
      _video = VideoPlayerController.file(File(widget.videoUrl));
    }
    await _video!.initialize();
    _videoDuration = _video!.value.duration;
    _video!.setLooping(false);


    _video!.addListener(() {
      final v = _video!;
      if (!mounted) return;
      setState(() {
        _position = v.value.position;
      });
      _isPlaying.value = v.value.isPlaying;
    });
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

  /// video save function
  // Future<void> _stopFrontRecording() async {
  //   if (_frontCam != null && _frontCam!.value.isRecordingVideo) {
  //     final XFile file = await _frontCam!.stopVideoRecording();
  //     _recordedFile = file;
  //     setState(() => _isRecording = false);
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Saved: ${file.path}')),
  //       );
  //     }
  //   }
  // }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _video?.removeListener(() {});
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
              onTap: () {
                Get.back();
              },
              child: Icon(Icons.arrow_back, color: Color(0xFF0D1C12)),
            ),
            SizedBox(width: 12),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage("assets/images/dummy.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Mr.John",
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
                /// ====== Video Area ======
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

                      /// Blur + Countdown overlay (when counting)
                      if (_secondsRemaining > 0)
                        Positioned.fill(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Blur layer
                              BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  color: Color(
                                    0xFFABD4A7,
                                  ).withValues(alpha: 0.20),
                                ),
                              ),
                              // Big round counter
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF9CC198),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
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
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Media will show after $_secondsRemaining seconds',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF5E755C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      /// Top-right front camera preview (PiP)
                      if (_frontCam?.value.isInitialized == true)
                        Positioned(
                          top: 1,
                          right: 1,
                          child: Container(
                            width: 129,
                            height: 159,
                            decoration: BoxDecoration(
                              color: Color(0xFFFFFFFF).withValues(alpha: 0.24),
                              border: Border.all(
                                color: Color(0xFFABD4A7),
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CameraPreview(_frontCam!),
                          ),
                        ),

                      /// Recording badge (small red dot)
                      // if (_isRecording)
                      //   Positioned(
                      //     top: 20,
                      //     left: 20,
                      //     child: Row(
                      //       children: const [
                      //         Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                      //         SizedBox(width: 6),
                      //         Text('REC', style: TextStyle(color: Colors.white)),
                      //       ],
                      //     ),
                      //   ),
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
          : const Center(child: CircularProgressIndicator()),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Progress / Seek
          Row(
            children: [
              Text(
                "${_fmt(_position)} sec",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: total.toDouble(),
                  activeColor: Color(0xFF413E3E), // slider active color
                  inactiveColor: Color(0xFF413E3E),
                  thumbColor: Color(0xFFD9D9D9), // slider inactive color
                  onChanged: (v) {
                    final pos = Duration(milliseconds: v.toInt());
                    _video?.seekTo(pos);
                  },
                ),
              ),
              Text(
                "${_fmt(_videoDuration)} sec",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 12),
              ValueListenableBuilder<bool>(
                valueListenable: _isPlaying,
                builder: (_, playing, __) {
                  return CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        color: Color(0xFF9CC198),
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
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.navigate_next, color: Color(0xFF9CC198),
                  size: 30,),
                  onPressed: () async {
                    if (mounted) Navigator.pop(context, _recordedFile?.path);
                  },
                ),
              ),
            ],
          ),


        ],
      ),
    );
  }
}

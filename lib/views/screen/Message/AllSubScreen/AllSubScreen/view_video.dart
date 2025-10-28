// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:video_player/video_player.dart';

class ViewVideo extends StatefulWidget {
  const ViewVideo({
    super.key,
    required this.videoUrl,
  });

  final String videoUrl;

  @override
  State<ViewVideo> createState() => _ViewVideoState();
}

class _ViewVideoState extends State<ViewVideo> {
  VideoPlayerController? _video;

  Duration _videoDuration = Duration.zero;
  Duration _position = Duration.zero;
  late final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  late final VoidCallback _videoListener;

  bool get isVideo {
    final ext = widget.videoUrl.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.contains('video');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFlow());
  }

  Future<void> _initFlow() async {
    await _requestPermissions();

    if (isVideo) {
      await _initVideo();
    }
    if (mounted) {
      _startCountdown();
    }
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

  void _startCountdown() async {
    await _video!.play();
  }


  @override
  void dispose() {
    _video?.removeListener(_videoListener);
    _video?.dispose();
    _disposeControllers();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _disposeControllers() {
    try {
      _video?.removeListener(_videoListener);
      _video?.dispose();
      _video = null;
    } catch (e) {
      debugPrint("⚠️ Dispose error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoReady = isVideo ? _video?.value.isInitialized == true : true;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // ← Back Arrow
            InkWell(
              onTap: () async {
                _disposeControllers();
                Get.back();
              },
              child: const Icon(Icons.arrow_back),
            ),
           ],
        ),
        actions: [
          // ✖️ X Button (Exit)
          IconButton(
            icon: const Icon(Icons.close, size: 26),
            onPressed: () async {
              _disposeControllers();
              Get.back();
            },
          ),
        ],
      ),
      body: videoReady
          ? Stack(
              alignment: Alignment.center,
              children: [
                // 🎬 Background (video or image)
                Positioned.fill(
                  child: isVideo
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _video!.value.size.width,
                            height: _video!.value.size.height,
                            child: VideoPlayer(_video!),
                          ),
                        )
                      : Image.network(
                          widget.videoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(Icons.broken_image),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SpinKitWave(
                                color: AppColors.primaryColor,
                                size: 30,
                              ),
                            );
                          },
                        ),
                ),              
                _buildBottomControls(),
              ],
            )
          : Center(child: SpinKitWave(color: AppColors.primaryColor, size: 30.0)),
    );
  }

  Widget _buildBottomControls() {
    final isVid = isVideo;
    final total = _videoDuration.inMilliseconds.toDouble().clamp(
      1,
      double.infinity,
    );
    final value = _position.inMilliseconds.toDouble().clamp(0, total);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        color: Colors.black.withValues(alpha: 0.3),
        child: Row(
          children: [
            if (isVid)
              Text(
                _fmt(_position),
                style: const TextStyle(color: Colors.white),
              ),
            if (isVid)
              Expanded(
                child: Slider(
                  value: double.parse(value.toStringAsFixed(0)),
                  min: 0,
                  max: double.parse(total.toStringAsFixed(0)),
                  activeColor: Colors.white,
                  onChanged: (v) =>
                      _video?.seekTo(Duration(milliseconds: v.toInt())),
                ),
              ),
            if (isVid) ...[
              Text(
                _fmt(_videoDuration),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<bool>(
                valueListenable: _isPlaying,
                builder: (_, playing, _) => IconButton(
                  icon: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
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
              ),
              const SizedBox(width: 18),
              ],
          ],
        ),
      ),
    );
  }
}

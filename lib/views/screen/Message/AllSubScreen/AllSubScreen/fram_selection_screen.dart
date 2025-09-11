import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FramSelectionScreen extends StatefulWidget {
  final String videoUrl;

  const FramSelectionScreen({super.key, required this.videoUrl});

  @override
  State<FramSelectionScreen> createState() => _FramSelectionScreenState();
}

class _FramSelectionScreenState extends State<FramSelectionScreen> {
  CameraController? _frontCam;
  VideoPlayerController? _video;
  bool _isInitialized = false;

  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  double _trimStart = 0;
  double _trimEnd = 1;

  final List<String> _thumbnailPaths = [];
  final double _thumbnailWidth = 60.0;
  final double _thumbnailHeight = 80.0;
  final double _trimSelectionWidth = 80.0;
  double _trimLeftPosition = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    await _requestPermissions();
    await _initFrontCamera();
    await _initVideo();
    await _generateThumbnails();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
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
    _video!.setLooping(false);
    _video!.addListener(() {
      if (!mounted) return;
      setState(() {
        // Update state to rebuild UI for progress updates
      });
      _isPlaying.value = _video!.value.isPlaying;
    });
    if (mounted) setState(() {});
  }

  Future<void> _generateThumbnails() async {
    _thumbnailPaths.clear();
    final videoFile = File(widget.videoUrl);
    final totalDuration = _video!.value.duration.inMilliseconds;
    const int thumbnailCount = 10;
    final int interval = (totalDuration / thumbnailCount).floor();

    for (int i = 0; i < thumbnailCount; i++) {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        quality: 50,
        timeMs: i * interval,
      );
      if (thumbnailPath != null) {
        _thumbnailPaths.add(thumbnailPath);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video?.removeListener(() {});
    _video?.dispose();
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
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                Get.back();
              },
              child: const Icon(Icons.arrow_back, color: Color(0xFF0D1C12)),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage("assets/images/dummy.jpg"),
            ),
            const SizedBox(width: 12),
            const Text(
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
      body: Column(
        children: [



          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// ==== Full-screen Front Camera ====
                if (_frontCam?.value.isInitialized == true)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        // previewSize null-check করে নিন
                        width: _frontCam!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                        height: _frontCam!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                        child: CameraPreview(_frontCam!),
                      ),
                    ),
                  ),

                /// ==== Sender video as PiP ====
                if (_video != null && _video!.value.isInitialized)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 105,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.24),
                        border: Border.all(
                          color: const Color(0xFFABD4A7),
                          width: 2,
                        ),

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

                /// ==== Bottom progress bar ====
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildVideoProgressBar(),
                ),
              ],
            ),
          ),


          Container(
            width: double.infinity,
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                _buildTrimAndFrameSelector(),
                const SizedBox(height: 20),
                _buildThumbnailSlider(),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFC4C3C3),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF002329).withValues(alpha: 0.07),
                            spreadRadius: -1.25,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: Center(
                        child: Text("Discard",
                        style: TextStyle(
                          color: Color(0xFF676565),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      onTap: () {

                      },
                      text: "Send Now",

                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoProgressBar() {
    if (_video == null || !_video!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final totalDuration = _video!.value.duration.inSeconds;
    final currentPosition = _video!.value.position.inSeconds;
    final progress = currentPosition / totalDuration;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical:10),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF).withValues(alpha: 0.24)
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "${_fmt(_video!.value.position)} sec",
                style: const TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: progress,
                  min: 0,
                  max: 1,
                  activeColor: const Color(0xFF413E3E),
                  inactiveColor: const Color(0xFFC4C3C3),
                  thumbColor: const Color(0xFFD9D9D9),
                  onChanged: (value) {
                    final newPosition = Duration(
                        milliseconds: (_video!.value.duration.inMilliseconds * value).toInt());
                    _video!.seekTo(newPosition);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${_fmt(_video!.value.duration)} sec",
                style: const TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<bool>(
                valueListenable: _isPlaying,
                builder: (_, playing, _) {
                  return InkWell(
                    onTap: () async {
                      if (playing) {
                        await _video?.pause();
                      } else {
                        await _video?.play();
                      }
                      _isPlaying.value = _video?.value.isPlaying ?? false;
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: const Color(0xFF9CC198),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrimAndFrameSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "Use trim",
          style: TextStyle(
            color: _trimEnd - _trimStart < 1.0 ? const Color(0xFF799777) : const Color(0xFF807E7E),
            fontSize: 10,
            fontWeight: FontWeight.w400,
            decoration: _trimEnd - _trimStart < 1.0 ? TextDecoration.underline : null,
            decorationColor: AppColors.primaryColor
          ),
        ),
        const SizedBox(width: 18),
        Text(
          "Use frame",
          style: TextStyle(
            color: _trimEnd - _trimStart < 1.0 ? const Color(0xFF799777) : const Color(0xFF807E7E),
            fontSize: 10,
            fontWeight: FontWeight.w400,
            decoration: _trimEnd - _trimStart < 1.0 ? TextDecoration.underline : null,
              decorationColor: AppColors.primaryColor
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailSlider() {
    final double fullWidth = _thumbnailPaths.length * (_thumbnailWidth + 4);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFABD4A7).withValues(alpha: 0.1),
        border: Border.all(
          color: const Color(0xFFABD4A7),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              final newOffset = _scrollController.offset - _thumbnailWidth;
              _scrollController.animateTo(
                newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFABD4A7)),
          ),
          Expanded(
            child: SizedBox(
              height: _thumbnailHeight,
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _thumbnailPaths.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: _thumbnailWidth,
                        height: _thumbnailHeight,
                        margin: const EdgeInsets.only(right: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(_thumbnailPaths[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: _trimLeftPosition,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _trimLeftPosition += details.delta.dx;
                          _trimLeftPosition = _trimLeftPosition.clamp(0.0, fullWidth - _trimSelectionWidth);
                          _trimStart = _trimLeftPosition / fullWidth;
                          _trimEnd = (_trimLeftPosition + _trimSelectionWidth) / fullWidth;
                        });
                        _video!.seekTo(Duration(
                            milliseconds: (_video!.value.duration.inMilliseconds * _trimStart).toInt()));
                      },
                      child: Container(
                        width: _trimSelectionWidth,
                        height: _thumbnailHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFABD4A7).withValues(alpha: 0.50),
                          border: Border.all(
                            color: const Color(0xFFABD4A7),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              final newOffset = _scrollController.offset + _thumbnailWidth;
              _scrollController.animateTo(
                newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFFABD4A7)),
          ),
        ],
      ),
    );
  }
}
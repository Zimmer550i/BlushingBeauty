import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/controllers/camera_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Camera/AllSubScreen/send_message_with_friend_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoTrimAndSendScreen extends StatefulWidget {
  final String videoUrl;

  const VideoTrimAndSendScreen({super.key, required this.videoUrl});

  @override
  State<VideoTrimAndSendScreen> createState() => _VideoTrimAndSendScreenState();
}

class _VideoTrimAndSendScreenState extends State<VideoTrimAndSendScreen> {
  final CreateStoryController _storyController = Get.put(
    CreateStoryController(),
  );

  late VideoPlayerController _videoController;
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  final List<String> _thumbnailPaths = [];

  bool _isInitialized = false;
  double _leftHandle = 0.0;
  double _rightHandle = 100.0;
  double _trimStart = 0.0;
  double _trimEnd = 1.0;

  final double _thumbnailWidth = 60.0;
  final double thumbnailHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    await _requestPermissions();

    _videoController = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));

    await _videoController.initialize();
    await _generateThumbnails();

    _videoController.addListener(() {
      if (mounted) {
        _isPlaying.value = _videoController.value.isPlaying;
      }
    });

    setState(() => _isInitialized = true);
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    if (statuses.values.any((status) => status != PermissionStatus.granted)) {
      Get.snackbar(
        "Permission Denied",
        "Camera & Storage permissions are required.",
      );
      Get.back();
    }
  }

  Future<void> _generateThumbnails() async {
    _thumbnailPaths.clear();
    final totalDuration = _videoController.value.duration.inMilliseconds;
    const int count = 10;
    final interval = (totalDuration / count).floor();

    for (int i = 0; i < count; i++) {
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        quality: 70,
        timeMs: i * interval,
      );
      if (path != null) _thumbnailPaths.add(path);
    }
  }

  /// ⏱️ Format Duration (mm:ss)
  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// ✂️ Trim the video using FFmpeg
  Future<File?> _trimVideo(File inputFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final outputPath =
          '${dir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final totalMs = _videoController.value.duration.inMilliseconds;
      final startMs = (totalMs * _trimStart).toInt();
      final endMs = (totalMs * _trimEnd).toInt();
      final durationMs = endMs - startMs;

      final cmd =
          '-y -ss ${startMs / 1000} -t ${durationMs / 1000} -i "${inputFile.path}" -c:v libx264 -c:a aac -preset ultrafast "$outputPath"';
      debugPrint("🎬 FFmpeg command: $cmd");

      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();

      if (ReturnCode.isSuccess(rc)) {
        debugPrint("✅ Trim success: $outputPath");
        return File(outputPath);
      } else {
        debugPrint("❌ Trim failed: $rc");
        return null;
      }
    } catch (e) {
      debugPrint("⚠️ Error trimming: $e");
      return null;
    }
  }

  /// 🎞️ Video preview player
  Widget _buildVideoPreview() {
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: VideoPlayer(_videoController),
      ),
    );
  }

  /// 🎮 Video controls
  Widget _buildVideoControls() {
    final duration = _videoController.value.duration;
    final position = _videoController.value.position;
    final progress = (position.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            _formatDuration(position),
            style: const TextStyle(color: Colors.black54),
          ),
          Expanded(
            child: Slider(
              value: progress,
              onChanged: (v) {
                _videoController.seekTo(
                  Duration(milliseconds: (duration.inMilliseconds * v).toInt()),
                );
              },
              activeColor: AppColors.primaryColor,
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, __) => InkWell(
              onTap: () async {
                if (playing) {
                  await _videoController.pause();
                } else {
                  await _videoController.play();
                }
                _isPlaying.value = _videoController.value.isPlaying;
              },
              child: CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                child: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✂️ Trim Slider
  Widget _buildTrimSlider() {
    final double totalWidth = _thumbnailPaths.length * (_thumbnailWidth + 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔘 Toggle row
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                child: const Text(
                  "Use trim",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                "Use frame",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        // 🎞️ Filmstrip + Trim handles
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 85,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Filmstrip thumbnails
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _thumbnailPaths.length,
                    itemBuilder: (_, i) => Container(
                      width: _thumbnailWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: Image.file(
                        File(_thumbnailPaths[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              // Blue highlighted trim area
              Positioned(
                left: _leftHandle,
                width: _rightHandle - _leftHandle,
                top: 8,
                bottom: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Left handle (blue circle)
              Positioned(
                left: _leftHandle - 10,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _leftHandle += details.delta.dx;
                      _leftHandle = _leftHandle.clamp(0.0, _rightHandle - 40);
                      _trimStart = (_leftHandle / totalWidth).clamp(0.0, 1.0);
                    });
                  },
                  child: _buildCircularHandle(),
                ),
              ),

              // Right handle (blue circle)
              Positioned(
                left: _rightHandle - 10,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _rightHandle += details.delta.dx;
                      _rightHandle = _rightHandle.clamp(
                        _leftHandle + 40,
                        totalWidth,
                      );
                      _trimEnd = (_rightHandle / totalWidth).clamp(0.0, 1.0);
                    });
                  },
                  child: _buildCircularHandle(),
                ),
              ),

              // Subtle gradient fades on edges
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 30,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 30,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔵 Circular handle builder (exactly like your screenshot)
  Widget _buildCircularHandle() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.drag_handle_rounded,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  /// 🧭 Action Buttons (Send / Create Story)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          InkWell(
            onTap: _handleTrimAndSend,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "Send Message",
                  style: TextStyle(color: Colors.black54, fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          CustomButton(
            onTap: () => _storyController.addStory(videoPath: widget.videoUrl),
            text: "Create Story",
          ),
        ],
      ),
    );
  }

  /// 📤 Trim & Send
  Future<void> _handleTrimAndSend() async {
    final originalFile = File(widget.videoUrl);
    Get.snackbar(
      "Processing",
      "Trimming video... please wait.",
      snackPosition: SnackPosition.BOTTOM,
    );

    final trimmedFile = await _trimVideo(originalFile);

    if (trimmedFile != null) {
      Get.to(
        () => SendMessageWithFriendScreen(
          filePath: trimmedFile.path,
          isVideo: true,
        ),
      );
    } else {
      Get.snackbar("Error", "Failed to trim video.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Trim & Send Video",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildVideoPreview()),
          _buildTrimSlider(),
          _buildVideoControls(),
          _buildActionButtons(),
        ],
      ),
    );
  }
}

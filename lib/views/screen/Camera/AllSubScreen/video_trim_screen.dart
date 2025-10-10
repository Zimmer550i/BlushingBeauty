import 'dart:io';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  VideoPlayerController? _video;
  bool _isInitialized = false;
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  final List<String> _thumbnailPaths = [];
  final ScrollController _scrollController = ScrollController();

  double _leftHandle = 0.0;
  double _rightHandle = 100.0;
  double _trimStart = 0.0;
  double _trimEnd = 1.0;

  final double _thumbnailWidth = 60.0;
  final double _thumbnailHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    await _requestPermissions();
    _video = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));

    await _video!.initialize();
    _video!.addListener(() {
      if (mounted) setState(() {});
      _isPlaying.value = _video!.value.isPlaying;
    });
    await _generateThumbnails();
    setState(() => _isInitialized = true);
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone, Permission.storage].request();
    if (statuses.values.any((status) => status != PermissionStatus.granted)) {
      Get.snackbar("Permission Denied", "Camera & Storage permissions are required.");
      Get.back();
    }
  }

  Future<void> _generateThumbnails() async {
    _thumbnailPaths.clear();
    final totalDuration = _video!.value.duration.inMilliseconds;
    const int count = 10;
    final interval = (totalDuration / count).floor();

    for (int i = 0; i < count; i++) {
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        quality: 60,
        timeMs: i * interval,
      );
      if (path != null) _thumbnailPaths.add(path);
    }
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<File?> _trimVideo(File inputFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final totalMs = _video!.value.duration.inMilliseconds;
      final startMs = (totalMs * _trimStart).toInt();
      final endMs = (totalMs * _trimEnd).toInt();
      final durationMs = endMs - startMs;

      final cmd =
          '-y -ss ${startMs / 1000} -t ${durationMs / 1000} -i "${inputFile.path}" -c:v libx264 -c:a aac -preset ultrafast "$outputPath"';
      debugPrint("🎬 FFmpeg: $cmd");

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

  @override
  void dispose() {
    _video?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trim & Send Video", style: TextStyle(color: Colors.black)),
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

  Widget _buildVideoPreview() => Container(
    color: Colors.black,
    child: AspectRatio(
      aspectRatio: _video!.value.aspectRatio,
      child: VideoPlayer(_video!),
    ),
  );

  Widget _buildVideoControls() {
    final duration = _video!.value.duration;
    final position = _video!.value.position;
    final progress = position.inMilliseconds / duration.inMilliseconds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(_fmt(position), style: const TextStyle(color: Colors.black54)),
          Expanded(
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              min: 0,
              max: 1,
              onChanged: (v) {
                _video!.seekTo(Duration(milliseconds: (duration.inMilliseconds * v).toInt()));
              },
              activeColor: AppColors.primaryColor,
            ),
          ),
          Text(_fmt(duration), style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 10),
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, __) => InkWell(
              onTap: () async {
                if (playing) {
                  await _video?.pause();
                } else {
                  await _video?.play();
                }
                _isPlaying.value = _video?.value.isPlaying ?? false;
              },
              child: CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                child: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimSlider() {
    final double totalWidth = _thumbnailPaths.length * (_thumbnailWidth + 2);
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 12,horizontal: 22),
      child: Stack(
        children: [
          // Thumbnail filmstrip
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _thumbnailPaths.length,
            itemBuilder: (_, i) => Container(
              width: _thumbnailWidth,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(File(_thumbnailPaths[i]), fit: BoxFit.cover),
              ),
            ),
          ),
          // Selected region highlight
          Positioned(
            left: _leftHandle,
            width: _rightHandle - _leftHandle,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Left handle
          Positioned(
            left: _leftHandle,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftHandle += details.delta.dx;
                  _leftHandle = _leftHandle.clamp(0.0, _rightHandle - 30);
                  _trimStart = (_leftHandle / totalWidth).clamp(0.0, 1.0);
                });
              },
              child: _buildHandle(),
            ),
          ),
          // Right handle
          Positioned(
            left: _rightHandle,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _rightHandle += details.delta.dx;
                  _rightHandle = _rightHandle.clamp(_leftHandle + 30, totalWidth);
                  _trimEnd = (_rightHandle / totalWidth).clamp(0.0, 1.0);
                });
              },
              child: _buildHandle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() => Container(
    width: 8,
    height: _thumbnailHeight,
    decoration: BoxDecoration(
      color: Colors.blueAccent,
      borderRadius: BorderRadius.circular(4),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
    ),
  );

  Widget _buildActionButtons() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        CustomButton(
          onTap: _handleTrimAndSend,
          text: "Trim & Send to Friends",
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => Get.back(),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text("Discard", style: TextStyle(color: Colors.black54, fontSize: 18)),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _handleTrimAndSend() async {
    final originalFile = File(widget.videoUrl);
    Get.snackbar("Processing", "Trimming video... please wait.", snackPosition: SnackPosition.BOTTOM);
    final trimmed = await _trimVideo(originalFile);
    if (trimmed != null) {

      Get.to(() => SendMessageWithFriendScreen(
        filePath: trimmed.path,
        isVideo: true,
      ));
    } else {
      Get.snackbar("Error", "Failed to trim video.");
    }
  }
}

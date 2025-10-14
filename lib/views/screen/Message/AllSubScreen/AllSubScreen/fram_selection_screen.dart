import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/controllers/camera_controller.dart';
import '../../../../../services/camera_manager.dart';
import '../../../Camera/AllSubScreen/send_message_with_friend_screen.dart';

class FrameSelectionScreen extends StatefulWidget {
  final String videoUrl;
  final String frontVideoUrl;
  final String userProfile;
  final String userName;

  const FrameSelectionScreen({
    super.key,
    required this.videoUrl,
    required this.userProfile,
    required this.userName,
    required this.frontVideoUrl,
  });

  @override
  State<FrameSelectionScreen> createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  final CreateStoryController createStoryController = Get.put(CreateStoryController());
  VideoPlayerController? _mainVideoController;
  VideoPlayerController? _frontVideoController;
  bool _isInitialized = false;

  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final List<String> _thumbnailPaths = [];

  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  double _leftHandle = 0.0;
  double _rightHandle = 80.0;

  final double _thumbnailWidth = 60.0;
  final double thumbnailHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    await _requestPermissions();
    await _initVideos();
    await _generateThumbnails();
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera & Microphone permission required')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initVideos() async {
    try {
      // 🎬 Main video (popup)
      final mainPath = widget.videoUrl.trim();
      _mainVideoController = mainPath.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(mainPath))
          : VideoPlayerController.file(File(mainPath));
      await _mainVideoController!.initialize();

      // 🤳 Front video (main fullscreen + trimming target)
      final frontPath = widget.frontVideoUrl.trim();
      _frontVideoController = frontPath.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(frontPath))
          : VideoPlayerController.file(File(frontPath));
      await _frontVideoController!.initialize();

      _mainVideoController!.setLooping(true);
      _frontVideoController!.setLooping(true);

      _isPlaying.value = false;

      debugPrint("✅ Both videos initialized successfully.");
    } catch (e) {
      debugPrint("🚨 Video initialization failed: $e");
    }
  }

  Future<void> _generateThumbnails() async {
    if (_frontVideoController == null) return;
    _thumbnailPaths.clear();

    final totalDuration = _frontVideoController!.value.duration.inMilliseconds;
    const int thumbnailCount = 10;
    final int interval = (totalDuration / thumbnailCount).floor();

    for (int i = 0; i < thumbnailCount; i++) {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.frontVideoUrl,
        quality: 50,
        timeMs: i * interval,
      );
      if (thumbnailPath != null) _thumbnailPaths.add(thumbnailPath);
    }

    if (mounted) setState(() {});
  }

  Future<File?> _trimFrontVideo(File inputFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final outputPath =
          '${dir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final totalDuration = _frontVideoController!.value.duration.inMilliseconds;
      final startMs = (totalDuration * _trimStart).toInt();
      final endMs = (totalDuration * _trimEnd).toInt();
      final durationMs = endMs - startMs;

      final startSec = startMs / 1000.0;
      final durationSec = durationMs / 1000.0;

      final command =
          '-y -ss $startSec -t $durationSec -i "${inputFile.path}" -c:v libx264 -c:a aac -preset ultrafast -movflags +faststart "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint("✅ Trimmed video: $outputPath");
        return File(outputPath);
      } else {
        debugPrint("❌ FFmpeg trim failed");
        return null;
      }
    } catch (e) {
      debugPrint("⚠️ Trim failed: $e");
      return null;
    }
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _mainVideoController?.dispose();
    _frontVideoController?.dispose();
    GlobalCameraManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildAppBarTitle(),
      ),
      body: Column(
        children: [
          Expanded(child: _buildDualVideoPreview()),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() => Row(
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
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  // ✅ Show front video fullscreen & main video in popup
  Widget _buildDualVideoPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Front camera (trim target)
        if (_frontVideoController != null &&
            _frontVideoController!.value.isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _frontVideoController!.value.size.width,
                height: _frontVideoController!.value.size.height,
                child: VideoPlayer(_frontVideoController!),
              ),
            ),
          ),

        // Main (popup)
        if (_mainVideoController != null &&
            _mainVideoController!.value.isInitialized)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 140,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _mainVideoController!.value.size.width,
                  height: _mainVideoController!.value.size.height,
                  child: VideoPlayer(_mainVideoController!),
                ),
              ),
            ),
          ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildVideoProgressBar(),
        ),
      ],
    );
  }

Widget _buildVideoProgressBar() {
  final controller = _frontVideoController!;
  return ValueListenableBuilder(
    valueListenable: controller,
    builder: (context, VideoPlayerValue value, _) {
      final totalDuration = value.duration;
      final current = value.position;
      final totalMs = totalDuration.inMilliseconds.toDouble();
      final currentMs = current.inMilliseconds.toDouble();
      double progress = totalMs > 0 ? currentMs / totalMs : 0.0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
        ),
        child: Row(
          children: [
            Text(
              "${(current.inSeconds).toString()} sec",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 0),
                  activeTrackColor: Colors.black,
                  inactiveTrackColor: Colors.black.withOpacity(0.4),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  min: 0,
                  max: 1,
                  onChanged: (v) async {
                    if (controller.value.duration == Duration.zero) return;
                    final newPos = Duration(
                      milliseconds:
                          (totalDuration.inMilliseconds * v).toInt(),
                    );
                    await _frontVideoController?.seekTo(newPos);
                    await _mainVideoController?.seekTo(newPos);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "${(totalDuration.inSeconds).toString()} sec",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _isPlaying,
              builder: (_, playing, __) => InkWell(
                onTap: () async {
                  if (playing) {
                    await _frontVideoController?.pause();
                    await _mainVideoController?.pause();
                  } else {
                    await _frontVideoController?.play();
                    await _mainVideoController?.play();
                    _syncVideos();
                  }
                  _isPlaying.value = !playing;
                },
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}


/// ✅ Add this sync function to prevent front camera auto-stop
void _syncVideos() {
  if (_frontVideoController == null || _mainVideoController == null) return;

  // If either video pauses unintentionally, restart both
  _frontVideoController!.addListener(() async {
    final front = _frontVideoController!;
    if (!front.value.isPlaying &&
        !front.value.isBuffering &&
        _isPlaying.value &&
        front.value.position < front.value.duration) {
      await front.play();
    }
  });

  _mainVideoController!.addListener(() async {
    final main = _mainVideoController!;
    if (!main.value.isPlaying &&
        !main.value.isBuffering &&
        _isPlaying.value &&
        main.value.position < main.value.duration) {
      await main.play();
    }
  });

  // Always loop both smoothly
  _frontVideoController!.setLooping(true);
  _mainVideoController!.setLooping(true);
}


  Widget _buildBottomControls() => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTrimSlider(),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => Get.offAllNamed(AppRoutes.messageScreen),
              child: _buildDiscardButton(),
            ),
            const SizedBox(height: 10),
            CustomButton(onTap: _handleTrimAndSend, text: "Trim & Send"),
          ],
        ),
      );

  Widget _buildDiscardButton() => Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC4C3C3), width: 0.5),
        ),
        child: const Center(
          child: Text(
            "Discard",
            style: TextStyle(
              color: Color(0xFF676565),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _buildTrimSlider() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
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
          Positioned(
            left: _leftHandle,
            width: _rightHandle - _leftHandle,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            left: _leftHandle,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftHandle += details.delta.dx;
                  _leftHandle = _leftHandle.clamp(0.0, _rightHandle - 30);
                  final total =
                      _thumbnailPaths.length * (_thumbnailWidth + 2);
                  _trimStart = (_leftHandle / total).clamp(0.0, 1.0);
                });
              },
              child: _buildHandle(),
            ),
          ),
          Positioned(
            left: _rightHandle,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _rightHandle += details.delta.dx;
                  final total =
                      _thumbnailPaths.length * (_thumbnailWidth + 2);
                  _rightHandle = _rightHandle.clamp(_leftHandle + 30, total);
                  _trimEnd = (_rightHandle / total).clamp(0.0, 1.0);
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
        width: 6,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );

  Future<void> _handleTrimAndSend() async {
    if (_frontVideoController == null) return;

    final original = File(widget.frontVideoUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trimming your front camera video...')),
    );

    final trimmed = await _trimFrontVideo(original);
    if (trimmed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trim failed')),
      );
      return;
    }

    await Get.to(
      () => SendMessageWithFriendScreen(
        filePath: trimmed.path,
        isVideo: true,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }
}

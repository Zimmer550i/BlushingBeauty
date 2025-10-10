import 'dart:io';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../controllers/camera_controller.dart';
import '../../../Camera/AllSubScreen/send_message_with_friend_screen.dart';


class FrameSelectionScreen extends StatefulWidget {
  final String videoUrl;
  final String userProfile;
  final String userName;

  const FrameSelectionScreen({
    super.key,
    required this.videoUrl,
    required this.userProfile,
    required this.userName,
  });

  @override
  State<FrameSelectionScreen> createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  final CreateStoryController createStoryController = Get.put(CreateStoryController());
  CameraController? _frontCam;
  VideoPlayerController? _video;
  bool _isInitialized = false;

  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  final ScrollController _scrollController = ScrollController();

  final List<String> _thumbnailPaths = [];
  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  double _leftHandle = 0.0;
  double _rightHandle = 80.0;

  final double _thumbnailWidth = 60.0;
  final double _thumbnailHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  // ---------- INITIAL SETUP ----------
  Future<void> _initFlow() async {
    await _requestPermissions();
    await _initFrontCamera();
    await _initVideo();
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
    _frontCam = CameraController(front, ResolutionPreset.high, enableAudio: true);
    await _frontCam!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initVideo() async {
    _video = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));

    await _video!.initialize();
    _video!.setLooping(false);
    _video!.addListener(() {
      if (!mounted) return;
      setState(() {});
      _isPlaying.value = _video!.value.isPlaying;
    });
  }

  Future<void> _generateThumbnails() async {
    _thumbnailPaths.clear();
    final totalDuration = _video!.value.duration.inMilliseconds;
    const int thumbnailCount = 10;
    final int interval = (totalDuration / thumbnailCount).floor();

    for (int i = 0; i < thumbnailCount; i++) {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        quality: 50,
        timeMs: i * interval,
      );
      if (thumbnailPath != null) _thumbnailPaths.add(thumbnailPath);
    }
    if (mounted) setState(() {});
  }

  // ---------- VIDEO TRIMMING ----------
  Future<File?> _trimVideo(File inputFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final totalDuration = _video!.value.duration.inMilliseconds;
      final startMs = (totalDuration * _trimStart).toInt();
      final endMs = (totalDuration * _trimEnd).toInt();
      final durationMs = endMs - startMs;

      final startSec = startMs / 1000.0;
      final durationSec = durationMs / 1000.0;

      final safeInput = '"${inputFile.path}"';
      final safeOutput = '"$outputPath"';

      final command =
          '-y -ss $startSec -t $durationSec -i $safeInput -c:v libx264 -c:a aac -preset ultrafast $safeOutput';

      debugPrint("🎬 Running FFmpeg command: $command");

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs = await session.getAllLogsAsString();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint("✅ FFmpeg success: $outputPath");
        return File(outputPath);
      } else {
        debugPrint("❌ FFmpeg failed: $returnCode\nLogs:\n$logs");
        return null;
      }
    } catch (e) {
      debugPrint("⚠️ Trim failed: $e");
      return null;
    }
  }

  // ---------- HELPERS ----------
  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _video?.dispose();
    _frontCam?.dispose();
    super.dispose();
  }

  // ---------- UI ----------
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
          Expanded(child: _buildCameraAndVideoPreview()),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() => Row(
    children: [
      InkWell(onTap: () => Get.back(), child: const Icon(Icons.arrow_back, color: Color(0xFF0D1C12))),
      const SizedBox(width: 12),
      CircleAvatar(radius: 22, backgroundImage: NetworkImage(widget.userProfile)),
      const SizedBox(width: 12),
      Text(
        widget.userName,
        style: const TextStyle(color: Color(0xFF413E3E), fontSize: 24, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _buildCameraAndVideoPreview() => Stack(
    alignment: Alignment.center,
    children: [
      if (_frontCam?.value.isInitialized == true)
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _frontCam!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
              height: _frontCam!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
              child: CameraPreview(_frontCam!),
            ),
          ),
        ),
      if (_video != null && _video!.value.isInitialized)
        Positioned(
          top: 0,
          right: 0,
          child: _buildVideoPip(),
        ),
      Positioned(left: 0, right: 0, bottom: 0, child: _buildVideoProgressBar()),
    ],
  );

  Widget _buildVideoPip() => Container(
    width: 105,
    height: 130,
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
  );

  Widget _buildVideoProgressBar() {
    final totalDuration = _video!.value.duration.inSeconds;
    final currentPosition = _video!.value.position.inSeconds;
    final progress = currentPosition / totalDuration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white.withValues(alpha: 0.24),
      child: Row(
        children: [
          Text("${_fmt(_video!.value.position)} sec", style: const TextStyle(color: Color(0xFF413E3E))),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: progress,
              min: 0,
              max: 1,
              activeColor: const Color(0xFF413E3E),
              onChanged: (value) {
                final newPos = Duration(milliseconds: (_video!.value.duration.inMilliseconds * value).toInt());
                _video!.seekTo(newPos);
              },
            ),
          ),
          const SizedBox(width: 8),
          Text("${_fmt(_video!.value.duration)} sec", style: const TextStyle(color: Color(0xFF413E3E))),
          const SizedBox(width: 12),
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
                backgroundColor: Colors.white,
                child: Icon(playing ? Icons.pause : Icons.play_arrow, color: AppColors.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        _buildTrimsSlider(),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => Get.offAllNamed(AppRoutes.messageScreen),
          child: _buildDiscardButton(),
        ),
        const SizedBox(height: 10),
        CustomButton(
          onTap: _handleSendNow,
          text: "Send Now",
        ),
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
        style: TextStyle(color: Color(0xFF676565), fontSize: 20, fontWeight: FontWeight.w600),
      ),
    ),
  );

  // ---------- TRIM SLIDER ----------
  Widget _buildTrimsSlider() {
    final double totalWidth = _thumbnailPaths.length * (_thumbnailWidth + 2);

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Thumbnails Filmstrip
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _thumbnailPaths.length,
            itemBuilder: (context, index) {
              return Container(
                width: _thumbnailWidth,
                margin: const EdgeInsets.symmetric(horizontal: 1),
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

          // Dark overlay on unselected regions
          Positioned.fill(
            child: Stack(
              children: [
                // Left dark overlay
                Positioned(
                  left: 0,
                  right: totalWidth - _leftHandle,
                  top: 0,
                  bottom: 0,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),

                // Right dark overlay
                Positioned(
                  left: _rightHandle,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ],
            ),
          ),

          // Blue border highlight for selected region
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

          // Left handle
          Positioned(
            left: _leftHandle,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftHandle += details.delta.dx;
                  _leftHandle = (_leftHandle.clamp(0.0, _rightHandle - 30));

                  final totalWidth = _thumbnailPaths.length * (_thumbnailWidth + 2);
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
                  final totalWidth = _thumbnailPaths.length * (_thumbnailWidth + 2);
                  _rightHandle = (_rightHandle.clamp(_leftHandle + 30, totalWidth));

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

  /// White rounded draggable handle with subtle shadow
  Widget _buildHandle() {
    return Container(
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
  }


  // ---------- SEND LOGIC ----------
  Future<void> _handleSendNow() async {
    if (_video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video loaded!')),
      );
      return;
    }

    final originalFile = File(widget.videoUrl);

    // 🟢 Step 1: Notify user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trimming video... Please wait')),
    );

    // 🟢 Step 2: Trim the video
    final trimmedFile = await _trimVideo(originalFile);

    // 🟢 Step 3: If successful, send to next screen
    if (trimmedFile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trim successful!')),
      );

      // 🚀 Navigate & pass file to SendMessageWithFriendScreen
      await Get.to(
            () => SendMessageWithFriendScreen(
          filePath: trimmedFile.path,
          isVideo: true,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );

      // optional: close current trimming screen after navigation
      // Get.back();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video trim failed')),
      );
    }
  }

}

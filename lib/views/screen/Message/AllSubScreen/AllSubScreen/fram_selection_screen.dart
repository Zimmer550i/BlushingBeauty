import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/controllers/send_message_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/dot_trim_ui.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/controllers/camera_controller.dart';
import 'package:video_trimmer/video_trimmer.dart';
import '../../../Camera/AllSubScreen/send_message_with_friend_screen.dart';

class FrameSelectionScreen extends StatefulWidget {
  final String frontVideoUrl;
  final String userProfile;
  final String userName;
  final String? chatId;
  final bool? isInbox;
  final XFile? videoFile;

  const FrameSelectionScreen({
    super.key,
    required this.userProfile,
    required this.userName,
    required this.frontVideoUrl,
    this.isInbox = false,
    this.chatId,
    this.videoFile,
  });

  @override
  State<FrameSelectionScreen> createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  final CreateStoryController createStoryController = Get.put(
    CreateStoryController(),
  );
  VideoPlayerController? _mainVideoController;
  VideoPlayerController? _frontVideoController;
  final sendMessageController = Get.put(SendMessageController());
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final List<String> _thumbnailPaths = [];
  final Trimmer _trimmer = Trimmer();

  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  double _leftHandle = 0.0;
  double _rightHandle = 80.0;
  int _selectedTab = 0;
  double frameHandle = 40; // initial position of selector
  final double selectorWidth = 60; // width of selection window
  int _selectedFrameIndex = 0;
  bool _isInitialized = false;
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
          const SnackBar(
            content: Text('Camera & Microphone permission required'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initVideos() async {
    try {
      final frontPath = widget.frontVideoUrl.trim();
      _frontVideoController = frontPath.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(frontPath))
          : VideoPlayerController.file(File(frontPath));
      await _frontVideoController!.initialize();
      _frontVideoController!.addListener(_updatePlayState);

      _frontVideoController!.setLooping(true);
      _isPlaying.value = false;
      _syncVideos();

      debugPrint("✅ Both videos initialized successfully.");
    } catch (e) {
      debugPrint("🚨 Video initialization failed: $e");
    }
  }

  void _updatePlayState() {
    if (!mounted) return;
    final front = _frontVideoController;
    if (front != null) {
      final isPlayingNow = front.value.isPlaying;
      if (isPlayingNow != _isPlaying.value) {
        _isPlaying.value = isPlayingNow;
      }
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

  @override
  void dispose() {
    _mainVideoController?.removeListener(_updatePlayState);
    _frontVideoController?.removeListener(_updatePlayState);
    _mainVideoController?.dispose();
    _frontVideoController?.dispose();
    // GlobalCameraManager.dispose();
    super.dispose();
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
        ),
      );
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
        // if (_mainVideoController != null &&
        //     _mainVideoController!.value.isInitialized)
        //   Positioned(
        //     top: 20,
        //     right: 20,
        //     child: Container(
        //       width: 140,
        //       height: 180,
        //       decoration: BoxDecoration(
        //         color: Colors.black.withValues(alpha: 0.3),
        //         borderRadius: BorderRadius.circular(10),
        //         border: Border.all(color: Colors.white, width: 2),
        //       ),
        //       clipBehavior: Clip.hardEdge,
        //       child: FittedBox(
        //         fit: BoxFit.cover,
        //         child: SizedBox(
        //           width: _mainVideoController!.value.size.width,
        //           height: _mainVideoController!.value.size.height,
        //           child: VideoPlayer(_mainVideoController!),
        //         ),
        //       ),
        //     ),
        //   ),
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
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4)),
          child: Row(
            children: [
              Text(
                "${(current.inSeconds).toString()} sec",
                style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 0,
                    ),
                    activeTrackColor: Colors.black38,
                    inactiveTrackColor: Colors.black38,
                    thumbColor: Colors.white.withValues(alpha: 0.8),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    min: 0,
                    max: 1,
                    onChanged: (v) async {
                      if (controller.value.duration == Duration.zero) return;
                      final newPos = Duration(
                        milliseconds: (totalDuration.inMilliseconds * v)
                            .toInt(),
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
                  color: Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<bool>(
                valueListenable: _isPlaying,
                builder: (_, playing, _) => InkWell(
                  onTap: _togglePlayPause,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    child: Icon(
                      _isPlaying.value ? Icons.pause : Icons.play_arrow,
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

  void _togglePlayPause() async {
    if (_frontVideoController == null) return;

    final front = _frontVideoController!;

    if (!front.value.isInitialized) return;

    if (front.value.isPlaying) {
      await front.pause();
      _isPlaying.value = false;
    } else {
      await front.play();
      _isPlaying.value = true;
    }
  }

  void _syncVideos() {
    if (_frontVideoController == null || _mainVideoController == null) return;
    final front = _frontVideoController!;
    final main = _mainVideoController!;

    front.addListener(() async {
      if (!front.value.isPlaying) return;

      final diff = (front.value.position - main.value.position).inMilliseconds
          .abs();
      if (diff > 120) {
        await main.seekTo(front.value.position);
      }

      // Stop both when finished
      if (front.value.position >= front.value.duration) {
        await front.pause();
        await main.pause();
        _isPlaying.value = false;
      }
    });
  }

  Widget _buildBottomControls() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        _buildTabs(),
        const SizedBox(height: 6),

        // 🔹 Show different content based on selected tab
        if (_selectedTab == 0) _buildTrimSlider() else _buildFrameSelector(),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () => Get.offAllNamed(AppRoutes.messageScreen),
              child: _buildDiscardButton(),
            ),
            const SizedBox(width: 10),
            CustomButton(
              width: MediaQuery.of(context).size.width / 2.5,
              onTap: _selectedTab == 0
                  ? _handleTrimAndSend
                  : _handleFrameAndSend,
              text: "Send now",
            ),
          ],
        ),
      ],
    ),
  );

  // 🔹 Tabs ("Use trim" / "Use frame")
  Widget _buildTabs() {
    return Row(
      children: [
        _buildTabButton("Trim video", 0),
        const SizedBox(width: 18),
        _buildTabButton("Select image", 1),
      ],
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.lightBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.lightBlue : Colors.grey[600],
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFrameSelector() {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🟦 Outer rail background
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _thumbnailPaths.length,
                  itemBuilder: (_, i) {
                    final isSelected = i == _selectedFrameIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFrameIndex = i;
                          frameHandle = i * (_thumbnailWidth + 2);
                        });
                      },
                      child: Stack(
                        children: [
                          // 🖼 Thumbnail image
                          Container(
                            width: _thumbnailWidth,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                File(_thumbnailPaths[i]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // 💠 Blur overlay when selected
                          if (isSelected)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: Container(
                                    color: Colors.black.withValues(alpha:  0.015),
                                    child: Center(
                                      child: Icon(
                                        Icons.circle,
                                        color: AppColors.primaryColor,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ◀ Left scroll arrow
          Positioned(
            left: -5,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  (_scrollController.offset - 100).clamp(0, double.infinity),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // ▶ Right scroll arrow
          Positioned(
            right: -5,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  (_scrollController.offset + 100).clamp(0, double.infinity),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscardButton() => Container(
    width: MediaQuery.of(context).size.width / 2.5,
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

Future<void> _handleTrimAndSend() async {
  if (widget.videoFile == null) return;

  try {
    final trimmer = Trimmer();

    // 1️⃣ Load the video
    await trimmer.loadVideo(videoFile: File(widget.videoFile!.path));

    // 2️⃣ Show trimming message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trimming your video...')),
    );

    // 3️⃣ Trim the video using Completer to get output path
    final Completer<File?> completer = Completer();

    await trimmer.saveTrimmedVideo(
      startValue: _trimStart,
      endValue: _trimEnd,
      videoFileName: "trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4",
      onSave: (String? path) {
        if (path == null || path.isEmpty) {
          completer.complete(null);
        } else {
          debugPrint("✅ Video trimmed to: $path");
          completer.complete(File(path));
        }
      },
    );

    final trimmedFile = await completer.future;

    if (trimmedFile == null || !await trimmedFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trim failed. Please try again.')),
      );
      return;
    }

    debugPrint("🎬 Trimmed file ready: ${trimmedFile.path}");

    // 4️⃣ Send to chat or navigate
    if (widget.isInbox == true && widget.chatId != null) {
      await sendMessageController.sendMediaToSingleChat(
        chatId: widget.chatId!,
        filePath: trimmedFile.path,
        isVideo: true,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video sent successfully!')),
      );
      if (mounted) Get.back();
      return;
    }

    if (!mounted) return;
    await Get.to(
      () => SendMessageWithFriendScreen(
        filePath: trimmedFile.path,
        isVideo: true,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  } catch (e, st) {
    debugPrint("❌ Error trimming video: $e\n$st");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
  }
}


Future<File?> _trimFrontVideo(File inputFile) async {
  try {
    final trimmer = Trimmer();
    await trimmer.loadVideo(videoFile: inputFile);

    // Wait until video controller is initialized
    int retries = 0;
    while ((trimmer.videoPlayerController?.value.isInitialized ?? false) == false &&
        retries < 10) {
      await Future.delayed(const Duration(milliseconds: 300));
      retries++;
    }

    if (!(trimmer.videoPlayerController?.value.isInitialized ?? false)) {
      debugPrint("❌ Video controller not initialized");
      return null;
    }

    final totalDuration = trimmer.videoPlayerController!.value.duration.inMilliseconds.toDouble();
    final startSeconds = (_trimStart.clamp(0.0, 1.0)) * (totalDuration / 1000);
    final endSeconds = (_trimEnd.clamp(0.0, 1.0)) * (totalDuration / 1000);

    if (endSeconds <= startSeconds) {
      debugPrint("⚠️ Invalid trim range");
      return null;
    }

    final completer = Completer<File?>();

    // Use onSave callback to get trimmed file path
    await trimmer.saveTrimmedVideo(
      startValue: startSeconds,
      endValue: endSeconds,
      videoFileName: "trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4",
      onSave: (outputPath) {
        if (outputPath == null || outputPath.isEmpty) {
          completer.complete(null);
        } else {
          completer.complete(File(outputPath));
        }
      },
    );

    return await completer.future;
  } catch (e, st) {
    debugPrint("❌ Trim error: $e\n$st");
    return null;
  }
}


  void _handleFrameAndSend() async {
    final selectedFrame = _thumbnailPaths[_selectedFrameIndex];
    if (widget.isInbox == true) {
      await sendMessageController.sendMediaToSingleChat(
        chatId: widget.chatId.toString(),
        filePath: selectedFrame,
        isVideo: false,
      );
    } else {
      await Get.to(
        () => SendMessageWithFriendScreen(
          filePath: selectedFrame,
          isVideo: false,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
      return;
    }
  }

  // 🎞 Main Trim Slider
  Widget _buildTrimSlider() {
    final total = _thumbnailPaths.length * (_thumbnailWidth + 2);

    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🟦 Outer blue rounded rail
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
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
            ),
          ),

          // 🌈 Light blue selected area
          Positioned(
            left: _leftHandle,
            width: _rightHandle - _leftHandle,
            top: 30,
            bottom: 30,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ◀ Left arrow
          Positioned(
            left: -5,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  (_scrollController.offset - 100).clamp(0, double.infinity),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: Icon(Icons.chevron_left, color: Colors.white, size: 32),
            ),
          ),

          // ▶ Right arrow
          Positioned(
            right: -5,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  (_scrollController.offset + 100).clamp(0, double.infinity),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: Icon(Icons.chevron_right, color: Colors.white, size: 32),
            ),
          ),

          // 🔹 Left handle
          Positioned(
            left: _leftHandle,
            top: 8,
            bottom: 8,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftHandle += details.delta.dx;
                  _leftHandle = _leftHandle.clamp(0.0, _rightHandle - 30);
                  _trimStart = double.parse(
                    (_leftHandle / total).clamp(0.0, 1.0).toStringAsFixed(4),
                  );
                });
              },
              child: DotBarUi(),
            ),
          ),

          // 🔹 Right handle
          Positioned(
            left: _rightHandle - 8,
            top: 8,
            bottom: 8,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _rightHandle += details.delta.dx;
                  _rightHandle = _rightHandle.clamp(_leftHandle + 30, total);
                  _trimEnd = double.parse(
                    (_rightHandle / total).clamp(0.0, 1.0).toStringAsFixed(4),
                  );
                });
              },
              child: DotBarUi(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/controllers/send_message_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_loading.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/controllers/camera_controller.dart';
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
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        // 🔹 Show different content based on selected tab
        Row(
          children: [
            _buildFrameSelector(),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => Get.offAllNamed(AppRoutes.messageScreen),
              child: Icon(
                Icons.delete,
                size: 30,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Obx(
              () => InkWell(
                onTap: () {
                  _handleFrameAndSend();
                },
                child: sendMessageController.isLoading.value
                    ? CustomLoading()
                    : SvgPicture.asset(
                        'assets/icons/send.svg',
                        // ignore: deprecated_member_use
                        color: AppColors.primaryColor,
                        height: 26,
                      ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildFrameSelector() {
    return SizedBox(
      height: 120,
      width: MediaQuery.of(context).size.width / 1.5,
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
                                    color: Colors.black.withValues(
                                      alpha: 0.015,
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
}

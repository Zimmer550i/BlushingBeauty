import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/files.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/send_message_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:video_player/video_player.dart';
import 'fram_selection_screen.dart';

class SendOrTrimVideoScreen extends StatefulWidget {
  final String mainVideo;
  final String reactionVideo;
  final String userProfile;
  final String userName;
  final String chatId;
  final bool? isInbox;
  final bool? isVideo;

  const SendOrTrimVideoScreen({
    super.key,
    required this.mainVideo,
    required this.userProfile,
    required this.userName,
    required this.chatId,
    required this.reactionVideo,
    this.isInbox,
    this.isVideo,
  });

  @override
  State<SendOrTrimVideoScreen> createState() => _SendOrTrimVideoScreenState();
}

class _SendOrTrimVideoScreenState extends State<SendOrTrimVideoScreen> {
  VideoPlayerController? _mainVideoController;
  VideoPlayerController? _reactionVideoController;
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final sendMessageController = Get.put(SendMessageController());
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  @override
  void dispose() {
    _mainVideoController?.removeListener(_syncVideos);
    _reactionVideoController?.removeListener(_syncVideos);
    _mainVideoController?.dispose();
    _reactionVideoController?.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  Future<void> _initializeVideos() async {
    // Main video (background)
    _mainVideoController = widget.mainVideo.startsWith('http')
        ? VideoPlayerController.network(widget.mainVideo)
        : VideoPlayerController.file(File(widget.mainVideo));

    // Reaction video (mini preview)
    _reactionVideoController = widget.reactionVideo.startsWith('http')
        ? VideoPlayerController.network(widget.reactionVideo)
        : VideoPlayerController.file(File(widget.reactionVideo));

    await Future.wait([
      _mainVideoController!.initialize(),
      _reactionVideoController!.initialize(),
    ]);

    // Loop both videos
    _mainVideoController!.setLooping(true);
    _reactionVideoController!.setLooping(true);

    _videoDuration = _reactionVideoController!.value.duration;

    // Listen to reaction video to sync main video
    _reactionVideoController!.addListener(_syncVideos);

    // Start both videos paused
    _isPlaying.value = false;
    setState(() {});
  }

  void _syncVideos() async {
    if (_reactionVideoController == null || _mainVideoController == null) return;
    if (!_reactionVideoController!.value.isInitialized ||
        !_mainVideoController!.value.isInitialized) return;

    final front = _reactionVideoController!;
    final main = _mainVideoController!;

    // Sync main video position
    final diff = (front.value.position - main.value.position).inMilliseconds.abs();
    if (diff > 100) {
      await main.seekTo(front.value.position);
    }

    // Update UI
    if (mounted) {
      setState(() {
        _videoPosition = front.value.position;
        _isPlaying.value = front.value.isPlaying;
      });
    }
  }

  void _togglePlayPause() async {
    if (_reactionVideoController == null || _mainVideoController == null) return;
    final front = _reactionVideoController!;
    final main = _mainVideoController!;

    if (front.value.isPlaying) {
      await front.pause();
      await main.pause();
      _isPlaying.value = false;
    } else {
      await main.seekTo(front.value.position);
      await Future.delayed(const Duration(milliseconds: 60));
      await main.play();
      await front.play();
      _isPlaying.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(onTap: Get.back, child: const Icon(Icons.arrow_back, color: Colors.black)),
            const SizedBox(width: 12),
            CircleAvatar(backgroundImage: NetworkImage(widget.userProfile), radius: 22),
            const SizedBox(width: 12),
            Text(widget.userName,
                style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: _mainVideoController == null || _reactionVideoController == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Reaction video full screen
                      if (_reactionVideoController!.value.isInitialized)
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _reactionVideoController!.value.size.width,
                              height: _reactionVideoController!.value.size.height,
                              child: VideoPlayer(_reactionVideoController!),
                            ),
                          ),
                        ),

                      // Main video mini preview
                      if (_mainVideoController!.value.isInitialized && widget.isVideo == true)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 130,
                              height: 160,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 2)),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
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
                        ),

                      // Playback controls
                      Positioned(bottom: 0, left: 0, right: 0, child: _buildPlaybackControls()),
                    ],
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
    );
  }

  Widget _buildPlaybackControls() {
    final totalMs = _videoDuration.inMilliseconds.toDouble().clamp(1, double.infinity);
    return ValueListenableBuilder<bool>(
      valueListenable: _isPlaying,
      builder: (_, playing, __) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.24)),
          child: Row(
            children: [
              Text(_formatDuration(_videoPosition), style: const TextStyle(color: Colors.black)),
              Expanded(
                child: Slider(
                  value: _videoPosition.inMilliseconds.toDouble().clamp(0, totalMs).toDouble(),
                  min: 0,
                  max: totalMs.toDouble(),
                  activeColor: AppColors.primaryColor,
                  inactiveColor: Colors.grey,
                  onChanged: (v) async {
                    final pos = Duration(milliseconds: v.toInt());
                    await _reactionVideoController?.seekTo(pos);
                    await _mainVideoController?.seekTo(pos);
                    setState(() => _videoPosition = pos);
                  },
                ),
              ),
              Text(_formatDuration(_videoDuration), style: const TextStyle(color: Colors.black)),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: AppColors.primaryColor),
                  onPressed: _togglePlayPause,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() => Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
        child: Column(
          children: [
            InkWell(
              onTap: () => Get.to(() => FrameSelectionScreen(
                    videoUrl: widget.mainVideo,
                    frontVideoUrl: widget.reactionVideo,
                    userProfile: widget.userProfile,
                    userName: widget.userName,
                    chatId: widget.chatId,
                    isInbox: widget.isInbox,
                  )),
              child: _buildTrimButton(),
            ),
            const SizedBox(height: 20),
            Obx(()=> CustomButton(
              loading: sendMessageController.isLoading.value,
              onTap: () async {
                await sendMessageController.sendMediaToSingleChat(
                  chatId: widget.chatId,
                  filePath: widget.reactionVideo,
                  isVideo: true,
                );
              },
              text: "Send Now",
            ),),
          ],
        ),
      );

  Widget _buildTrimButton() => Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), offset: const Offset(0, 2), blurRadius: 4)],
        ),
        child: const Center(
          child: Text(
            "Trim or Select Frame",
            style: TextStyle(color: Color(0xFF413E3E), fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class BlurVideoCard extends StatefulWidget {
  final File videoFile;
  final Map<String, dynamic> msg;
  final String? receiverImage;
  final String receiverName;

  const BlurVideoCard({
    super.key,
    required this.videoFile,
    required this.msg,
    required this.receiverName,
    this.receiverImage,
  });

  @override
  State<BlurVideoCard> createState() => _BlurVideoCardState();
}

class _BlurVideoCardState extends State<BlurVideoCard> {
  bool _isTapped = false;
  bool _isLoading = true;
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: widget.videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 180,
        quality: 80,
      );
      if (!mounted) return;
      setState(() {
        _thumbnailPath = thumb;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Thumbnail generation error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Clean up the generated thumbnail file if it exists
    if (_thumbnailPath != null) {
      final file = File(_thumbnailPath!);
      if (file.existsSync()) {
        file.delete().then((_) {
          debugPrint("🧹 Deleted temp thumbnail file");
        });
      }
    }
    super.dispose();
  }

  void _onTapVideo() {
    if (_isTapped) return;
    setState(() => _isTapped = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPreviewScreen(
            videoUrl: widget.videoFile.path,
            countdownSeconds: 3,
            userProfile: widget.receiverImage ?? "",
            userName: widget.receiverName,
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _isTapped = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTapVideo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isLoading
                ? Container(
                    height: 180,
                    width: 240,
                    color: Colors.black12.withOpacity(0.1),
                    child: Center(
                      child: SpinKitWave(
                        color: AppColors.primaryColor,
                        size: 30.0,
                      ),
                    ),
                  )
                : _thumbnailPath != null
                    ? AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _isTapped ? 1.0 : 0.6,
                        child: ImageFiltered(
                          imageFilter: _isTapped
                              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                              : ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: Image.file(
                            File(_thumbnailPath!),
                            height: 180,
                            width: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        height: 180,
                        width: 240,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
          ),

          // ▶️ Play Button Overlay
          AnimatedOpacity(
            opacity: _isTapped ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';

class BlurImageCard extends StatefulWidget {
  final String imageUrl;
  final String receiverName;
  final String? receiverImage;
  final String chatId;
  final bool isMe; // 👈 new flag to control blur

  const BlurImageCard({
    super.key,
    required this.imageUrl,
    required this.receiverName,
    required this.chatId,
    this.receiverImage,
    required this.isMe,
  });

  @override
  State<BlurImageCard> createState() => _BlurImageCardState();
}

class _BlurImageCardState extends State<BlurImageCard> {
  bool _isLoaded = false;
  bool _isTapped = false;

  void _onTapImage() {
    if (!_isLoaded || _isTapped) return;
    setState(() => _isTapped = true);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPreviewScreen(
            videoUrl: widget.imageUrl, // 👈 using same preview screen
            countdownSeconds: 3,
            userProfile: widget.receiverImage ?? "",
            userName: widget.receiverName,
            chatId: widget.chatId,
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
      onTap: _onTapImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageFiltered(
              imageFilter: widget.isMe
                  ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                  : _isTapped || !_isLoaded
                  ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                  : ImageFilter.blur(
                      sigmaX: 20,
                      sigmaY: 20,
                      tileMode: TileMode.decal,
                    ),
              child: Image.network(
                widget.imageUrl,
                height: 180,
                width: 240,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) setState(() => _isLoaded = true);
                    });
                    return child;
                  } else {
                    return Container(
                      height: 180,
                      width: 240,
                      color: Colors.black12.withValues(alpha: .1),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                },
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  width: 240,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

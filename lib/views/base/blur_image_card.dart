import 'dart:ui';

import 'package:flutter/material.dart';

class BlurImageCard extends StatefulWidget {
  final String imageUrl;
  const BlurImageCard({super.key, required this.imageUrl});

  @override
  State<BlurImageCard> createState() => BlurImageCardState();
}

class BlurImageCardState extends State<BlurImageCard> {
  bool _isLoaded = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isLoaded) {
          setState(() => _isTapped = !_isTapped);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageFiltered(
              imageFilter: _isTapped || !_isLoaded
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
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                },
                errorBuilder: (_, __, ___) => Image.asset(
                  "assets/images/receiver.jpg",
                  height: 180,
                  width: 240,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 👁️ Optional overlay icon
          if (!_isTapped && _isLoaded)
            Container(
              height: 180,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.visibility,
                  color: Colors.transparent,
                  size: 30,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

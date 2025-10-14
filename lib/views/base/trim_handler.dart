import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TrimSlider extends StatefulWidget {
  final List<String> thumbnailPaths;
  final double thumbnailWidth;

  const TrimSlider({
    super.key,
    required this.thumbnailPaths,
    this.thumbnailWidth = 50,
  });

  @override
  State<TrimSlider> createState() => _TrimSliderState();
}

class _TrimSliderState extends State<TrimSlider>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;
  late Animation<double> leftAnim, rightAnim;

  double _leftHandle = 40;
  double _rightHandle = 220;
  double trimStart = 0.0;
  double trimEnd = 1.0;
  bool _isDraggingLeft = false;
  bool _isDraggingRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth =
        widget.thumbnailPaths.length * (widget.thumbnailWidth + 2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🎞️ Filmstrip
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.thumbnailPaths.length,
            itemBuilder: (_, i) => Container(
              width: widget.thumbnailWidth,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(widget.thumbnailPaths[i]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 🔷 Highlighted selected area
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            left: _leftHandle,
            width: _rightHandle - _leftHandle,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.18),
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),

          // ⬅️ Left Handle
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: _leftHandle - 8,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                HapticFeedback.lightImpact();
                setState(() => _isDraggingLeft = true);
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftHandle += details.delta.dx;
                  _leftHandle = _leftHandle.clamp(0.0, _rightHandle - 30);
                  trimStart = (_leftHandle / totalWidth).clamp(0.0, 1.0);
                });
              },
              onHorizontalDragEnd: (_) {
                _animateHandleSnap(isLeft: true);
              },
              child: _buildHandle(isActive: _isDraggingLeft),
            ),
          ),

          // ➡️ Right Handle
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: _rightHandle - 8,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                HapticFeedback.lightImpact();
                setState(() => _isDraggingRight = true);
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _rightHandle += details.delta.dx;
                  _rightHandle = _rightHandle.clamp(
                    _leftHandle + 30,
                    totalWidth,
                  );
                  trimEnd = (_rightHandle / totalWidth).clamp(0.0, 1.0);
                });
              },
              onHorizontalDragEnd: (_) {
                _animateHandleSnap(isLeft: false);
              },
              child: _buildHandle(isActive: _isDraggingRight),
            ),
          ),

          // 🌫️ Left gradient fade
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

          // 🌫️ Right gradient fade
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
    );
  }

  /// 🎚️ Handle widget with glow animation
  Widget _buildHandle({bool isActive = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 18,
      height: 60,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.blueAccent,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: const Center(
        child: Icon(Icons.drag_handle, color: Colors.white, size: 16),
      ),
    );
  }

  /// 🪄 Smooth snap after drag ends
  void _animateHandleSnap({required bool isLeft}) {
    setState(() {
      if (isLeft) _isDraggingLeft = false;
      if (!isLeft) _isDraggingRight = false;
    });

    _animController.forward(from: 0.0);
    HapticFeedback.selectionClick();
  }
}

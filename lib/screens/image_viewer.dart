import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerScreen extends StatefulWidget {
  final String imagePath;
  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _animCtrl;
  Animation<Matrix4>? _anim;
  TapDownDetails? _lastTapDown;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_anim != null) _controller.value = _anim!.value;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final current = _controller.value;
    final isZoomed = current.getMaxScaleOnAxis() > 1.01;
    Matrix4 target;
    if (isZoomed) {
      target = Matrix4.identity();
    } else {
      final pos = _lastTapDown?.localPosition ?? Offset.zero;
      const scale = 2.5;
      target = Matrix4.identity()
        ..translateByDouble(
            -pos.dx * (scale - 1), -pos.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, scale, 1);
    }
    _anim = Matrix4Tween(begin: current, end: target).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onDoubleTapDown: (d) => _lastTapDown = d,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1.0,
          maxScale: 5.0,
          child: Center(
            child: Hero(
              tag: widget.imagePath,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MusicBackground extends StatelessWidget {
  const MusicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // The background is static; isolating it in a RepaintBoundary keeps its
    // (expensive) blurs from repainting on every scroll frame of the list.
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -40,
            child: _glowCircle(
              size: 220,
              color: AppColors.neonPink.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 180,
            right: -30,
            child: _glowCircle(
              size: 240,
              color: AppColors.neonBlue.withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            bottom: 220,
            right: 20,
            child: _glowCircle(
              size: 260,
              color: AppColors.neonPink.withValues(alpha: 0.16),
            ),
          ),
          const _MusicPattern(),
        ],
      ),
    );
  }

  Widget _glowCircle({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox(),
        ),
      ),
    );
  }
}

class _MusicPattern extends StatelessWidget {
  const _MusicPattern();

  // Positions are fractional (0..1) of the available width/height, so the
  // decorative notes spread across the whole background on any screen size
  // instead of clustering in a fixed phone-sized rectangle. `size` is the base
  // glyph size at the reference width; it scales gently with the screen.
  static const _notes = <_NoteData>[
    _NoteData.icon(Icons.music_note_rounded, 40, 0.08, 0.056, 0.080),
    _NoteData.glyph('♫', 90, 0.10, 0.639, 0.125),
    _NoteData.glyph('♬', 70, 0.08, 0.306, 0.232),
    _NoteData.glyph('𝄞', 130, 0.09, 0.833, 0.179),
    _NoteData.glyph('♭', 70, 0.07, 0.111, 0.384),
    _NoteData.glyph('♯', 78, 0.08, 0.722, 0.366),
    _NoteData.glyph('♪', 60, 0.07, 0.417, 0.500),
    _NoteData.glyph('♮', 72, 0.07, 0.861, 0.536),
    _NoteData.glyph('𝄢', 120, 0.08, 0.083, 0.625),
    _NoteData.glyph('♫', 84, 0.07, 0.611, 0.714),
    _NoteData.glyph('𝄡', 96, 0.07, 0.333, 0.821),
    _NoteData.glyph('♬', 66, 0.06, 0.833, 0.902),
    _NoteData.icon(Icons.music_note_rounded, 60, 0.05, 0.167, 0.964),
  ];

  // Reference width the base sizes were tuned for.
  static const _refWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final scale = (w / _refWidth).clamp(0.8, 1.6);
          return Stack(
            children: _notes.map((n) {
              final size = n.size * scale;
              return Positioned(
                left: n.fx * w,
                top: n.fy * h,
                child: n.icon != null
                    ? Icon(
                        n.icon,
                        size: size,
                        color: Colors.white.withValues(alpha: n.opacity),
                      )
                    : Text(
                        n.glyph!,
                        style: TextStyle(
                          fontSize: size,
                          height: 1.0,
                          color: Colors.white.withValues(alpha: n.opacity),
                        ),
                      ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _NoteData {
  final IconData? icon;
  final String? glyph;
  final double size;
  final double opacity;

  /// Fractional position (0..1) of the available width/height.
  final double fx;
  final double fy;

  const _NoteData.icon(
    IconData this.icon,
    this.size,
    this.opacity,
    this.fx,
    this.fy,
  ) : glyph = null;
  const _NoteData.glyph(
    String this.glyph,
    this.size,
    this.opacity,
    this.fx,
    this.fy,
  ) : icon = null;
}

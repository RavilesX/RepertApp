import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MusicBackground extends StatelessWidget {
  const MusicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgTop,
                AppColors.bgMid,
                AppColors.bgBottom,
              ],
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
    );
  }

  Widget _glowCircle({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
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

  @override
  Widget build(BuildContext context) {
    final notes = <_NoteData>[
      _NoteData.icon(Icons.music_note_rounded, 40, 0.08, Offset(20, 90)),
      _NoteData.glyph('♫', 90, 0.10, Offset(230, 140)),
      _NoteData.glyph('♬', 70, 0.08, Offset(110, 260)),
      _NoteData.glyph('𝄞', 130, 0.09, Offset(300, 200)),
      _NoteData.glyph('♭', 70, 0.07, Offset(40, 430)),
      _NoteData.glyph('♯', 78, 0.08, Offset(260, 410)),
      _NoteData.glyph('♪', 60, 0.07, Offset(150, 560)),
      _NoteData.glyph('♮', 72, 0.07, Offset(310, 600)),
      _NoteData.glyph('𝄢', 120, 0.08, Offset(30, 700)),
      _NoteData.glyph('♫', 84, 0.07, Offset(220, 800)),
      _NoteData.glyph('𝄡', 96, 0.07, Offset(120, 920)),
      _NoteData.glyph('♬', 66, 0.06, Offset(300, 1010)),
      _NoteData.icon(Icons.music_note_rounded, 60, 0.05, Offset(60, 1080)),
    ];
    return IgnorePointer(
      child: Stack(
        children: notes.map((n) {
          return Positioned(
            left: n.offset.dx,
            top: n.offset.dy,
            child: n.icon != null
                ? Icon(
                    n.icon,
                    size: n.size,
                    color: Colors.white.withValues(alpha: n.opacity),
                  )
                : Text(
                    n.glyph!,
                    style: TextStyle(
                      fontSize: n.size,
                      height: 1.0,
                      color: Colors.white.withValues(alpha: n.opacity),
                    ),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class _NoteData {
  final IconData? icon;
  final String? glyph;
  final double size;
  final double opacity;
  final Offset offset;

  const _NoteData.icon(
      IconData this.icon, this.size, this.opacity, this.offset)
      : glyph = null;
  const _NoteData.glyph(
      String this.glyph, this.size, this.opacity, this.offset)
      : icon = null;
}

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
      _NoteData(Icons.music_note_rounded, 40, 0.08, const Offset(20, 90)),
      _NoteData(Icons.music_note_rounded, 82, 0.10, const Offset(230, 140)),
      _NoteData(Icons.music_note_rounded, 56, 0.06, const Offset(110, 260)),
      _NoteData(Icons.music_note_rounded, 110, 0.07, const Offset(310, 200)),
      _NoteData(Icons.music_note_rounded, 90, 0.05, const Offset(260, 520)),
      _NoteData(Icons.music_note_rounded, 70, 0.05, const Offset(80, 720)),
      _NoteData(Icons.music_note_rounded, 100, 0.06, const Offset(180, 950)),
      _NoteData(Icons.music_note_rounded, 60, 0.05, const Offset(320, 1080)),
    ];
    return IgnorePointer(
      child: Stack(
        children: notes.map((n) {
          return Positioned(
            left: n.offset.dx,
            top: n.offset.dy,
            child: Icon(
              n.icon,
              size: n.size,
              color: Colors.white.withValues(alpha: n.opacity),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NoteData {
  final IconData icon;
  final double size;
  final double opacity;
  final Offset offset;
  const _NoteData(this.icon, this.size, this.opacity, this.offset);
}

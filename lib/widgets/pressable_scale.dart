import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Wraps [child] with the shared press feedback used across the song views:
/// a quick scale-down on tap and a 1-second long-press that reports the global
/// position (for anchoring a context menu).
///
/// Extracted from the three list item widgets, which previously duplicated this
/// gesture + animation boilerplate verbatim.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPressAt;

  /// Scale the child shrinks to while pressed (e.g. 0.96).
  final double pressedScale;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    required this.onLongPressAt,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
    lowerBound: 0.0,
    upperBound: 1.0 - widget.pressedScale,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(seconds: 1),
              ),
              (instance) {
                instance.onLongPressStart = (details) =>
                    widget.onLongPressAt(details.globalPosition);
              },
            ),
      },
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) =>
              Transform.scale(scale: 1 - _ctrl.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

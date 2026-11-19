import 'package:flutter/material.dart';

/// Subtle, reduced-motion-aware entrance animation for cards, sections, and
/// newly inserted list items.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.offsetY = 10,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final double offsetY;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offsetY),
            child: child,
          ),
        );
      },
    );
  }
}

/// Tactile press-scale feedback for interactive cards and buttons.
class AnimatedPressScale extends StatefulWidget {
  const AnimatedPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<AnimatedPressScale> createState() => _AnimatedPressScaleState();
}

class _AnimatedPressScaleState extends State<AnimatedPressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onPointerUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onPointerCancel: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (!disableAnimations && _pressed) ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Smooth cross-fade + subtle vertical settle for tab and filter transitions.
class SmoothTabSwitcher extends StatelessWidget {
  const SmoothTabSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

/// The Acaderix brand emblem, rendered from the bundled asset.
///
/// Use this anywhere the application logo is shown so the brand stays
/// consistent across splash, welcome, and login screens.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.borderRadius = 20,
    this.withGlow = false,
    this.heroTag,
  });

  final double size;
  final double borderRadius;
  final bool withGlow;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/images/acadrix_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (heroTag != null) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    if (!withGlow) {
      return imageWidget;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          imageWidget,
          // Subtle glassy rim highlight
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

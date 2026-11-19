import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Acaderix brand emblem, rendered from the bundled asset.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.borderRadius = 16,
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: imageWidget,
    );
  }
}

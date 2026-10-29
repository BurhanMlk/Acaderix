import 'package:flutter/material.dart';

/// The Acadrix brand logo, rendered from the bundled asset.
///
/// Use this anywhere the application logo is shown so the brand stays
/// consistent across splash, welcome, and login screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.borderRadius = 20});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/images/acadrix_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Renders the academy's uploaded logo if available, or a clean branded placeholder with initials.
class AcademyAvatar extends StatelessWidget {
  const AcademyAvatar({
    super.key,
    required this.name,
    this.logoUrl,
    this.size = 40,
    this.borderRadius = 12,
  });

  final String name;
  final String? logoUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmedLogo = logoUrl?.trim() ?? '';

    if (trimmedLogo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          trimmedLogo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholder(scheme),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildPlaceholder(scheme);
  }

  Widget _buildPlaceholder(ColorScheme scheme) {
    final trimmedName = name.trim();
    final initial =
        trimmedName.isNotEmpty ? trimmedName.substring(0, 1).toUpperCase() : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: initial.isNotEmpty
            ? Text(
                initial,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.45,
                ),
              )
            : Icon(
                Icons.apartment_rounded,
                size: size * 0.5,
                color: scheme.primary,
              ),
      ),
    );
  }
}

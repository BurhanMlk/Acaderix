import 'dart:ui';

import 'package:flutter/material.dart';

/// Glassmorphism building blocks for the authentication experience.
///
/// Full-screen ambient glass background used across all role dashboards.
class DashboardBackground extends StatelessWidget {
  const DashboardBackground({
    super.key,
    required this.child,
    this.useSafeArea = false,
  });

  final Widget child;
  final bool useSafeArea;

  static const List<Color> gradient = [
    Color(0xFF0B1120), // deep navy
    Color(0xFF1E1B4B), // indigo
    Color(0xFF3B0764), // royal purple
  ];

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final statusBarHeight = topPadding > 0 ? topPadding + 14.0 : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(size: 320, color: Color(0xFF6366F1)),
          ),
          const Positioned(
            bottom: -140,
            left: -100,
            child: _GlowOrb(size: 360, color: Color(0xFFA855F7)),
          ),
          const Positioned(
            top: 200,
            left: -70,
            child: _GlowOrb(size: 240, color: Color(0xFF0EA5E9)),
          ),
          content,
          // Ambient status bar scrim protecting battery, time, and notch icons
          // from background orbs and scrolling list content without losing glass feel.
          if (statusBarHeight > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: statusBarHeight,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xB3050811), // 70% deep navy scrim directly under status bar
                        Color(0x4D050811), // 30% soft transition
                        Colors.transparent,
                      ],
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

/// A shared [AuthBackground] gradient plus frosted [GlassCard] and
/// [GlassTextField] widgets produce the transparent, professional look used
/// across the login and sign-up screens.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  static const List<Color> _gradient = [
    Color(0xFF0B1120), // deep navy
    Color(0xFF1E1B4B), // indigo
    Color(0xFF3B0764), // royal purple
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final statusBarHeight = topPadding > 0 ? topPadding + 14.0 : 0.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              right: -80,
              child: _GlowOrb(size: 300, color: Color(0xFF6366F1)),
            ),
            const Positioned(
              bottom: -140,
              left: -100,
              child: _GlowOrb(size: 340, color: Color(0xFFA855F7)),
            ),
            const Positioned(
              top: 160,
              left: -70,
              child: _GlowOrb(size: 200, color: Color(0xFF0EA5E9)),
            ),
            SafeArea(child: child),
            if (statusBarHeight > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: statusBarHeight,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xB3050811),
                          Color(0x4D050811),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// A frosted, translucent card.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 24,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A translucent text field tuned for dark glass backgrounds.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final int maxLines;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white.withValues(alpha: 0.24);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      autofillHints: autofillHints,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

/// White primary button style for dark glass screens.
ButtonStyle glassPrimaryButtonStyle() => FilledButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF1E1B4B),
  minimumSize: const Size.fromHeight(54),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
);

/// Ghost/outline button style for dark glass screens.
ButtonStyle glassGhostButtonStyle() => OutlinedButton.styleFrom(
  foregroundColor: Colors.white,
  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
  minimumSize: const Size.fromHeight(54),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
);

/// Shared heading for glass login screens.
class GlassLoginHeader extends StatelessWidget {
  const GlassLoginHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

/// Inline error banner for glass screens.
class GlassError extends StatelessWidget {
  const GlassError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFCA5A5).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFECACA)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFECACA)),
            ),
          ),
        ],
      ),
    );
  }
}

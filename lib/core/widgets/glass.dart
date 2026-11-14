import 'package:flutter/material.dart';

/// Clean light-theme building blocks for the Acaderix UI.
///
/// Full-screen white background used across all role dashboards.
class DashboardBackground extends StatelessWidget {
  const DashboardBackground({
    super.key,
    required this.child,
    this.useSafeArea = false,
  });

  final Widget child;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Container(color: const Color(0xFFFFFFFF), child: content);
  }
}

/// White background wrapper for login and sign-up screens.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFFFFF),
        child: SafeArea(child: child),
      ),
    );
  }
}

/// A clean white card with a subtle gray border.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

/// A light-themed text field.
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

  static const _textColor = Color(0xFF111827);
  static const _cursorColor = Color(0xFF4F46E5);
  static const _hintColor = Color(0xFF6B7280);
  static const _fillColor = Color(0xFFF9FAFB);
  static const _borderColor = Color(0xFFE5E7EB);
  static const _focusBorderColor = Color(0xFF4F46E5);
  static const _errorBorderColor = Color(0xFFDC2626);
  static const _iconColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      autofillHints: autofillHints,
      style: const TextStyle(color: _textColor),
      cursorColor: _cursorColor,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _hintColor),
        hintStyle: const TextStyle(color: _hintColor),
        prefixIcon: icon == null ? null : Icon(icon, color: _iconColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _focusBorderColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorBorderColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorBorderColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

/// Indigo primary button style for light screens.
ButtonStyle glassPrimaryButtonStyle() => FilledButton.styleFrom(
  backgroundColor: const Color(0xFF4F46E5),
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
);

/// Outline button style for light screens.
ButtonStyle glassGhostButtonStyle() => OutlinedButton.styleFrom(
  foregroundColor: const Color(0xFF374151),
  side: const BorderSide(color: Color(0xFFD1D5DB)),
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
);

/// Shared heading for login screens.
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
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0E7FF)),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }
}

/// Inline error banner for light screens.
class GlassError extends StatelessWidget {
  const GlassError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }
}

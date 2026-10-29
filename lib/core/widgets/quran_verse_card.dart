import 'package:flutter/material.dart';

import 'glass.dart';

/// Surah Al-Alaq (96:1-5) with its Arabic, English and Urdu renderings.
///
/// Shared by the splash and welcome screens so the verse stays consistent.
abstract final class QuranVerse {
  static const String arabic =
      'اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ (١) خَلَقَ الْإِنسَانَ مِنْ '
      'عَلَقٍ (٢) اقْرَأْ وَرَبُّكَ الْأَكْرَمُ (٣) الَّذِي عَلَّمَ '
      'بِالْقَلَمِ (٤) عَلَّمَ الْإِنسَانَ مَا لَمْ يَعْلَمْ (٥)';

  static const String english =
      'Read in the name of your Lord who created — created man from a clot. '
      'Read, and your Lord is the most Generous — Who taught by the pen — '
      'taught man that which he knew not.';

  static const String urdu =
      'پڑھے اپنے رب کے نام سے جس نے پیدا کیا؛ اس نے انسان کو خون کے لوتھڑے '
      'سے پیدا کیا۔ پڑھے اور آپ کا رب بڑا کریم ہے؛ جس نے قلم کے ذریعے (علم) '
      'سکھایا؛ اس نے انسان کو وہ سکھایا جو وہ نہیں جانتا تھا۔';
}

/// Presents [QuranVerse] in Arabic with English and Urdu translations.
///
/// Pass [glass] as true when the card sits on the dark auth background so it
/// renders with frosted, white-on-glass styling. Otherwise it follows the
/// active theme.
class QuranVerseCard extends StatelessWidget {
  const QuranVerseCard({super.key, this.glass = false});

  final bool glass;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color foreground;
    final Color accent;
    final Color dividerColor;
    if (glass) {
      foreground = Colors.white;
      accent = const Color(0xFFA5B4FC);
      dividerColor = Colors.white.withValues(alpha: 0.22);
    } else {
      foreground = scheme.onSurface;
      accent = scheme.primary;
      dividerColor = scheme.outlineVariant.withValues(alpha: 0.5);
    }

    final content = _VerseBody(
      foreground: foreground,
      accent: accent,
      dividerColor: dividerColor,
    );

    if (glass) {
      return GlassCard(padding: const EdgeInsets.all(20), child: content);
    }

    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }
}

class _VerseBody extends StatelessWidget {
  const _VerseBody({
    required this.foreground,
    required this.accent,
    required this.dividerColor,
  });

  final Color foreground;
  final Color accent;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VerseSection(
          label: 'Arabic',
          text: QuranVerse.arabic,
          textDirection: TextDirection.rtl,
          labelColor: accent,
          textStyle: textTheme.titleLarge?.copyWith(
            height: 1.8,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
        Divider(height: 28, color: dividerColor),
        _VerseSection(
          label: 'English Translation',
          text: QuranVerse.english,
          labelColor: accent,
          textStyle: textTheme.bodyMedium?.copyWith(
            height: 1.6,
            fontStyle: FontStyle.italic,
            color: foreground,
          ),
        ),
        Divider(height: 28, color: dividerColor),
        _VerseSection(
          label: 'Urdu Translation',
          text: QuranVerse.urdu,
          textDirection: TextDirection.rtl,
          labelColor: accent,
          textStyle: textTheme.bodyMedium?.copyWith(
            height: 1.8,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

class _VerseSection extends StatelessWidget {
  const _VerseSection({
    required this.label,
    required this.text,
    required this.labelColor,
    required this.textStyle,
    this.textDirection,
  });

  final String label;
  final String text;
  final Color labelColor;
  final TextStyle? textStyle;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textDirection: textDirection,
          textAlign: textDirection == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ],
    );
  }
}

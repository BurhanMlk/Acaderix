import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass.dart';

/// Surah Al-Alaq (96:1-5) with its Arabic, English and Urdu renderings.
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
class QuranVerseCard extends StatelessWidget {
  const QuranVerseCard({super.key, this.glass = false});

  final bool glass;

  @override
  Widget build(BuildContext context) {
    const content = _VerseBody();

    if (glass) {
      return const GlassCard(padding: EdgeInsets.all(20), child: content);
    }

    return const Card(
      child: Padding(padding: EdgeInsets.all(20), child: content),
    );
  }
}

class _VerseBody extends StatelessWidget {
  const _VerseBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VerseSection(
          label: 'Arabic',
          text: QuranVerse.arabic,
          textDirection: TextDirection.rtl,
          textStyle: TextStyle(
            fontSize: 20,
            height: 1.85,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Divider(height: 24, color: AppColors.borderLight),
        _VerseSection(
          label: 'English Translation',
          text: QuranVerse.english,
          textStyle: TextStyle(
            fontSize: 13.5,
            height: 1.6,
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
        Divider(height: 24, color: AppColors.borderLight),
        _VerseSection(
          label: 'Urdu Translation',
          text: QuranVerse.urdu,
          textDirection: TextDirection.rtl,
          textStyle: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: AppColors.textSecondary,
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
    required this.textStyle,
    this.textDirection,
  });

  final String label;
  final String text;
  final TextStyle textStyle;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textDirection: textDirection,
          textAlign: textDirection == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
          style: textStyle,
        ),
      ],
    );
  }
}

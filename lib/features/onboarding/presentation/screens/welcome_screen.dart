import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/quran_verse_card.dart';

/// Landing screen shown to signed-out users with a 3-step auto-advancing carousel:
/// 1. Welcome to Acaderix with brand logo and description.
/// 2. Quranic Verse (Surah Al-Alaq) with Arabic, English, and Urdu translations.
/// 3. Direct access to Log In and Register buttons without scrolling.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.autoAdvanceInterval = const Duration(seconds: 4),
    this.autoAdvanceEnabled = true,
  });

  /// Duration before auto-advancing to the next step.
  final Duration autoAdvanceInterval;

  /// Whether the screen should automatically transition forward between steps.
  final bool autoAdvanceEnabled;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const int _totalSteps = 3;

  int _currentPage = 0;
  late final PageController _pageController;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scheduleAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!widget.autoAdvanceEnabled) return;
    if (_currentPage >= _totalSteps - 1) return; // Stop timer on the final login/register step

    _autoAdvanceTimer = Timer(widget.autoAdvanceInterval, () {
      if (!mounted) return;
      if (_currentPage < _totalSteps - 1) {
        _goToPage(_currentPage + 1);
      }
    });
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalSteps) return;
    _autoAdvanceTimer?.cancel();
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _scheduleAutoAdvance();
  }

  void _skipToFinalStep() {
    _autoAdvanceTimer?.cancel();
    _goToPage(_totalSteps - 1);
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 600;
          final horizontalPadding = isLargeScreen ? 32.0 : 16.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    // Top Navigation Bar
                    _buildTopBar(context),

                    // 3-Step PageView Carousel
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        children: [
                          _WelcomeStepOne(
                            onNext: () => _goToPage(1),
                            onSkip: _skipToFinalStep,
                          ),
                          _WelcomeStepTwo(
                            onNext: () => _goToPage(2),
                            onBack: () => _goToPage(0),
                          ),
                          _WelcomeStepThree(
                            onBack: () => _goToPage(1),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Indicator and Navigation Controls
                    _buildBottomControls(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button on steps 2 & 3
          SizedBox(
            width: 48,
            height: 36,
            child: _currentPage > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    color: AppColors.textSecondary,
                    tooltip: 'Previous Step',
                    padding: EdgeInsets.zero,
                    onPressed: () => _goToPage(_currentPage - 1),
                  )
                : null,
          ),

          // Step Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Step ${_currentPage + 1} of $_totalSteps',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Skip button on steps 1 & 2
          SizedBox(
            width: 48,
            height: 36,
            child: _currentPage < _totalSteps - 1
                ? TextButton(
                    onPressed: _skipToFinalStep,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textTertiary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Indicators
          Row(
            children: List.generate(_totalSteps, (index) {
              final isSelected = index == _currentPage;
              return GestureDetector(
                onTap: () => _goToPage(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),

          // Forward Navigation Button on steps 1 & 2
          if (_currentPage < _totalSteps - 1)
            FilledButton.tonalIcon(
              onPressed: () => _goToPage(_currentPage + 1),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// STEP 1: Welcome to Acaderix with brand logo and concise description
class _WelcomeStepOne extends StatelessWidget {
  const _WelcomeStepOne({
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),

                  // Brand Emblem with Soft Glow
                  const Center(
                    child: AppLogo(
                      size: 96,
                      borderRadius: 24,
                      withGlow: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'ACADEMY PLATFORM',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Main Heading
                  const Text(
                    'Welcome to Acaderix',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Short Description
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'School and academy management for admissions, attendance, fees, exams, and daily operations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Highlight Badges
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _FeaturePill(icon: Icons.account_balance_outlined, label: 'Campuses'),
                      _FeaturePill(icon: Icons.receipt_long_outlined, label: 'Fee Invoices'),
                      _FeaturePill(icon: Icons.how_to_reg_outlined, label: 'Attendance'),
                      _FeaturePill(icon: Icons.chat_bubble_outline, label: 'Announcements'),
                    ],
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// STEP 2: Quranic Verse (Surah Al-Alaq) with Arabic, English, and Urdu translations
class _WelcomeStepTwo extends StatelessWidget {
  const _WelcomeStepTwo({
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // Section Title
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      const Text(
                        'Divine Guidance on Education',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Surah Al-Alaq • سورة العلق (96:1-5)',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quran Verse Card with full translations
                  const QuranVerseCard(glass: true),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// STEP 3: Dedicated Login or Register screen — fully visible with ZERO scrolling
class _WelcomeStepThree extends StatelessWidget {
  const _WelcomeStepThree({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),

                  // Compact Brand Emblem
                  const Center(
                    child: AppLogo(
                      size: 72,
                      borderRadius: 18,
                      withGlow: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Heading
                  const Text(
                    'Get Started with Acaderix',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Sign in to your account or register your academy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons Card — directly accessible without scrolling
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          style: glassPrimaryButtonStyle(),
                          onPressed: () => context.push(AppRoutes.login),
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text('Log In to Portal'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: glassGhostButtonStyle(),
                          onPressed: () => context.push(AppRoutes.register),
                          icon: const Icon(Icons.domain_add_outlined, size: 20),
                          label: const Text('Register New Academy'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role Hint & Security Notice
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: AppColors.textTertiary),
                        const Text(
                          'Admin • Staff • Student',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

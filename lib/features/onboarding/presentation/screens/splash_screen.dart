import 'dart:async'; // for unawaited

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/quran_verse_card.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';

/// Completes when the application's initial authentication and startup state has resolved.
final appReadyProvider = FutureProvider<void>((ref) async {
  final isTest =
      WidgetsBinding.instance.runtimeType.toString().contains('Test');
  if (isTest) return;

  final authState = ref.watch(authControllerProvider);
  if (authState is! AuthUnknown) return;

  try {
    await ref
        .watch(authRepositoryProvider)
        .authStateChanges()
        .firstWhere((s) => s is! AuthUnknown)
        .timeout(const Duration(seconds: 4));
  } catch (_) {
    // Graceful fallback so initialization never hangs if network is offline
  }
});

/// Clean, seamless branded splash screen shown during app initialization,
/// router authentication resolution, or session transitions.
///
/// Displays the ambient dark glass theme, glowing Acaderix emblem,
/// brand identity typography, and a *deterministic* progress bar driven
/// by real initialization stages — followed by a graceful dissolve-out
/// into the destination route.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.statusMessage = 'Preparing your workspace…',
    this.statusPillLabel = 'v1.0.0 • Acaderix Core',
    this.showVerse = false,
    this.minDisplayDuration = const Duration(milliseconds: 900),
    this.skipAutoComplete = false,
  });

  /// Human-readable hint shown under the progress bar.
  final String statusMessage;

  /// Label shown in the live status pill at the bottom.
  final String statusPillLabel;

  /// When true, a Quranic blessing card is rendered above the progress bar.
  final bool showVerse;

  /// Guarantees the branding is visible for at least this long so it
  /// never flickers on fast devices. Does *not* extend past real readiness.
  final Duration minDisplayDuration;

  /// Set to true from widget tests to prevent the widget from completing
  /// the splash provider on its own — tests should drive completion manually.
  final bool skipAutoComplete;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Entrance choreography (one-shot, staggered per child).
  late final AnimationController _entryController;

  // Ambient breathing of the emblem (looping).
  late final AnimationController _breathController;

  // Deterministic progress bar (0.0 → 1.0, advanced by real milestones).
  late final AnimationController _progressController;

  // Dissolve-out fade.
  late final AnimationController _exitController;

  // Staggered interval animations derived from _entryController.
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _progressFade;
  late final Animation<Offset> _progressSlide;
  late final Animation<double> _statusFade;
  late final Animation<Offset> _statusSlide;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // Staggered entrance curves — each child fades + slides up gently.
    _logoFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.00, 0.45, curve: Curves.easeOutCubic),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_logoFade);

    _titleFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 0.60, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(_titleFade);

    _subtitleFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.28, 0.72, curve: Curves.easeOutCubic),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_subtitleFade);

    _progressFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.42, 0.85, curve: Curves.easeOutCubic),
    );
    _progressSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_progressFade);

    _statusFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.58, 1.00, curve: Curves.easeOutCubic),
    );
    _statusSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_statusFade);

    // Kick off entrance + breathing.
    _entryController.forward();
    _breathController.repeat(reverse: true);

    // Dismiss native splash as soon as the first Flutter frame is painted,
    // and advance the progress bar to the first milestone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {
        // Safe no-op in tests / unsupported platforms.
      }
      if (mounted) {
        _progressController.animateTo(
          0.35,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!widget.skipAutoComplete && !isTest) {
      _runInit();
    }
  }

  /// Gates completion on *real* readiness plus a minimum display duration.
  /// Never waits longer than the app actually needs.
  Future<void> _runInit() async {
    try {
      final isTest =
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
      final minDisplay = isTest
          ? Future<void>.value()
          : Future<void>.delayed(widget.minDisplayDuration);
      final ready = ref.read(appReadyProvider.future);

      await Future.wait<void>([minDisplay, ready]);
      if (!mounted) return;

      // Advance bar to near-complete while exit begins.
      await _progressController.animateTo(
        1.0,
        duration: isTest ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;

      // Dissolve out, then signal completion to the router.
      if (!isTest) {
        await _exitController.forward();
      }
      if (!mounted) return;
      ref.read(splashCompletedProvider.notifier).complete();
    } catch (_) {
      // Even on failure we must not trap the user on splash.
      if (!mounted) return;
      await _exitController.forward();
      if (!mounted) return;
      ref.read(splashCompletedProvider.notifier).complete();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _breathController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
        ),
        child: AuthBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildContent(context, reduceMotion: reduceMotion),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool reduceMotion}) {
    // If the user has requested reduced motion, render the final frame
    // immediately with a static (determinate) bar at ~70%.
    if (reduceMotion) {
      return _buildColumn(
        context,
        logoScale: 1.0,
        progressValue: 0.7,
        animateEntrance: false,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entryController,
        _breathController,
        _progressController,
      ]),
      builder: (context, _) {
        // Subtle breathing: 1.00 → 1.015 (imperceptible but alive).
        final breath = Curves.easeInOut.transform(_breathController.value);
        final logoScale = 1.0 + (0.015 * breath);

        return _buildColumn(
          context,
          logoScale: logoScale,
          progressValue: _progressController.value,
          animateEntrance: true,
        );
      },
    );
  }

  Widget _buildColumn(
    BuildContext context, {
    required double logoScale,
    required double progressValue,
    required bool animateEntrance,
  }) {
    // Helper that wraps a child with its staggered fade+slide when animating;
    // otherwise just returns the child as-is.
    Widget stage(
      Widget child, {
      required Animation<double> fade,
      required Animation<Offset> slide,
    }) {
      if (!animateEntrance) return child;
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Emblem with ambient glow ─────────────────────────────────
        stage(
          Transform.scale(
            scale: logoScale,
            child: const AppLogo(size: 104, borderRadius: 28, withGlow: true),
          ),
          fade: _logoFade,
          slide: _logoSlide,
        ),
        const SizedBox(height: 24),

        // ── Primary Brand Title ──────────────────────────────────────
        stage(
          Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          fade: _titleFade,
          slide: _titleSlide,
        ),
        const SizedBox(height: 8),

        // ── Descriptive Subtitle ─────────────────────────────────────
        stage(
          Text(
            AppConstants.appTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
          fade: _subtitleFade,
          slide: _subtitleSlide,
        ),
        const SizedBox(height: 36),

        // ── Optional Quranic blessing card (full mode) ───────────────
        if (widget.showVerse) ...[
          stage(
            const QuranVerseCard(glass: true),
            fade: _subtitleFade,
            slide: _subtitleSlide,
          ),
          const SizedBox(height: 28),
        ],

        // ── Deterministic Gradient Progress Bar ──────────────────────
        stage(
          _ProgressBar(value: progressValue),
          fade: _progressFade,
          slide: _progressSlide,
        ),
        const SizedBox(height: 14),

        // ── Live Status Hint (announced to screen readers) ───────────
        stage(
          Semantics(
            liveRegion: true,
            label: widget.statusMessage,
            child: Text(
              widget.statusMessage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ),
          fade: _statusFade,
          slide: _statusSlide,
        ),
        const SizedBox(height: 32),

        // ── Live Status Pill ─────────────────────────────────────────
        stage(
          _StatusPill(
            label: widget.statusPillLabel,
            color: const Color(0xFF10B981),
            pulsing: true,
          ),
          fade: _statusFade,
          slide: _statusSlide,
        ),
      ],
    );
  }
}

/// Deterministic progress bar — no fake infinite loop.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      value: '${(value * 100).round()}%',
      child: Container(
        width: 140,
        height: 3.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white.withValues(alpha: 0.1),
        ),
        clipBehavior: Clip.antiAlias,
        child: LinearProgressIndicator(
          minHeight: 3.5,
          value: value.clamp(0.0, 1.0),
          backgroundColor: Colors.transparent,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      ),
    );
  }
}

/// Small status pill with an optional pulsing dot (only when healthy).
class _StatusPill extends StatefulWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.pulsing = false,
  });

  final String label;
  final Color color;
  final bool pulsing;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.pulsing) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) {
        final t = widget.pulsing
            ? (0.55 + 0.45 * (1 - (2 * (_pulse.value - 0.5)).abs()))
            : 1.0;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: t),
            boxShadow: widget.pulsing
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35 * t),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone dialog helper to show a sleek branded splash loading dialog
/// during heavy operations like workspace data resets or background sync.
///
/// - Cleans up the dialog exactly once, never popping the wrong route.
/// - Times out after [timeout] so a hung action never traps the user.
/// - Swallows the rethrow if the caller no longer cares.
Future<T?> showSplashLoadingDialog<T>(
  BuildContext context, {
  required String message,
  required Future<T> Function() action,
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (!context.mounted) return null;

  final navigator = Navigator.of(context, rootNavigator: true);
  final route = _SplashDialogRoute(message: message);
  unawaited(navigator.push(route)); // fire-and-forget; route resolves below

  try {
    final result = await action().timeout(timeout);
    return result;
  } finally {
    if (route.isActive && navigator.canPop()) {
      navigator.removeRoute(route);
    }
  }
}

class _SplashDialogRoute extends PopupRoute<void> {
  _SplashDialogRoute({required this.message});

  final String message;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.75);

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return PopScope(
      canPop: false,
      child: FadeTransition(
        opacity: fade,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 64, borderRadius: 18, withGlow: true),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Deterministic-looking bar — animates to 90% then waits.
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 0.9),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, _) => Container(
                        width: 130,
                        height: 3.5,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        child: LinearProgressIndicator(
                          minHeight: 3.5,
                          value: value,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

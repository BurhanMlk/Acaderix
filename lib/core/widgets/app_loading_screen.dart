import 'package:flutter/material.dart';

import 'app_logo.dart';
import 'glass.dart';

/// Production-ready ambient glass loading screen used across all role dashboards,
/// authentication transitions, and asynchronous operations.
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({
    super.key,
    this.title = 'Acaderix Workspace',
    this.message = 'Synchronizing your workspace and records...',
    this.useScaffold = true,
  });

  final String title;
  final String message;
  final bool useScaffold;

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Glowing Logo
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.18),
                          blurRadius: 48,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const AppLogo(size: 64),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Loading Indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF818CF8).withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.useScaffold) {
      return DashboardBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: content,
        ),
      );
    }

    return content;
  }
}

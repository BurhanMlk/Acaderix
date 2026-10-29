import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/glass.dart';

class _Feature {
  const _Feature(this.icon, this.title, this.message);
  final IconData icon;
  final String title;
  final String message;
}

const List<_Feature> _features = [
  _Feature(
    Icons.people_alt_outlined,
    'Student & Staff',
    'Admissions, roll numbers, staff roles and permissions.',
  ),
  _Feature(
    Icons.event_note_outlined,
    'Attendance & Fees',
    'Daily attendance, invoices, payments and receipts.',
  ),
  _Feature(
    Icons.insights_outlined,
    'Exams & Reports',
    'Results, report cards, payroll and financial insights.',
  ),
];

/// Short product introduction shown before the login screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text(
                            'Skip',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 360,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _features.length,
                        onPageChanged: (value) => setState(() => _page = value),
                        itemBuilder: (context, index) {
                          final feature = _features[index];
                          return LayoutBuilder(
                            builder: (context, pageConstraints) {
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(32),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: pageConstraints.maxHeight - 64,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 128,
                                        height: 128,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          feature.icon,
                                          size: 56,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      Text(
                                        feature.title,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        feature.message,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_features.length, (index) {
                        final selected = index == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: FilledButton(
                        style: glassPrimaryButtonStyle(),
                        onPressed: () {
                          if (_page < _features.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          } else {
                            context.go(AppRoutes.login);
                          }
                        },
                        child: Text(
                          _page < _features.length - 1
                              ? 'Next'
                              : 'Get Started',
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

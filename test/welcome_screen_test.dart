import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/core/widgets/app_logo.dart';
import 'package:academy_management/core/widgets/quran_verse_card.dart';
import 'package:academy_management/features/auth/presentation/screens/login_selection_screen.dart';
import 'package:academy_management/features/onboarding/presentation/screens/welcome_screen.dart';

void main() {
  Widget buildSubject({
    Duration autoAdvanceInterval = const Duration(seconds: 4),
    bool autoAdvanceEnabled = false,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: WelcomeScreen(
          autoAdvanceInterval: autoAdvanceInterval,
          autoAdvanceEnabled: autoAdvanceEnabled,
        ),
      ),
    );
  }

  testWidgets('WelcomeScreen renders Step 1 (Logo, Title, Description, and Step 1 of 3 badge)', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Verify Step 1 content
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Welcome to Acaderix'), findsOneWidget);
    expect(find.text('ACADEMY PLATFORM'), findsOneWidget);
    expect(
      find.text(
        'School and academy management for admissions, attendance, fees, exams, and daily operations.',
      ),
      findsOneWidget,
    );
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Navigating to Step 2 renders Quranic verse with translations', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Tap next button to go to Step 2
    final nextBtn = find.text('Next');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Verify Step 2 content
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Divine Guidance on Education'), findsOneWidget);
    expect(find.text('Surah Al-Alaq • سورة العلق (96:1-5)'), findsOneWidget);
    expect(find.byType(QuranVerseCard), findsOneWidget);
    expect(find.text('Arabic'), findsOneWidget);
    expect(find.text('English Translation'), findsOneWidget);
    expect(find.text('Urdu Translation'), findsOneWidget);
  });

  testWidgets('Navigating to Step 3 renders Log In and Register buttons directly visible', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Tap Skip to jump directly to Step 3
    final skipBtn = find.text('Skip');
    expect(skipBtn, findsOneWidget);
    await tester.tap(skipBtn);
    await tester.pumpAndSettle();

    // Verify Step 3 content
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Get Started with Acaderix'), findsOneWidget);
    expect(find.text('Log In to Portal'), findsOneWidget);
    expect(find.text('Register New Academy'), findsOneWidget);
    expect(find.text('Admin • Staff • Student'), findsOneWidget);

    // Skip button should no longer be present on the final step
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('Auto-advance timer transitions from Step 1 to Step 2 to Step 3 automatically', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        autoAdvanceInterval: const Duration(milliseconds: 300),
        autoAdvanceEnabled: true,
      ),
    );
    await tester.pump();

    // Initially at Step 1
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Welcome to Acaderix'), findsOneWidget);

    // Elapse timer for Step 1 (300ms)
    await tester.pump(const Duration(milliseconds: 300));
    // Pump animation frames until page transition completes to Step 2
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Divine Guidance on Education'), findsOneWidget);

    // Elapse timer for Step 2 (300ms)
    await tester.pump(const Duration(milliseconds: 300));
    // Pump animation frames until page transition completes to Step 3
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Get Started with Acaderix'), findsOneWidget);
    expect(find.text('Log In to Portal'), findsOneWidget);

    // Elapse more time at Step 3 -> remains on Step 3 (timer stopped)
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WelcomeScreen renders on small mobile screen (320x568) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Step 1 check
    expect(find.text('Welcome to Acaderix'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Step 2 check
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Step 3 check
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Log In to Portal'), findsOneWidget);
    expect(find.text('Register New Academy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WelcomeScreen renders on tablet screen (800x1200) with responsive constraint', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Acaderix'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoginSelectionScreen renders back arrow button to return to WelcomeScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify back arrow icon button exists with tooltip
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byTooltip('Back to Welcome'), findsOneWidget);
    expect(find.text('Choose how you want to sign in'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byTooltip('Back to Welcome'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoginSelectionScreen shows Admin, Staff, Student and hides Super Admin', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Super Admin'), findsNothing);
    expect(find.text('Academy Admin'), findsNothing);
  });
}

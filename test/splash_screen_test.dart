import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/core/widgets/app_logo.dart';
import 'package:academy_management/features/onboarding/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders Acaderix emblem, title, tagline, and loading bar cleanly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(
            statusMessage: 'Initializing Acaderix...',
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify brand assets and identity
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Acaderix'), findsOneWidget);
    expect(find.text('Academy Management System'), findsOneWidget);

    // Verify loading progress bar and version badge
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Initializing Acaderix...'), findsOneWidget);
    expect(find.text('v1.0.0 • Acaderix Core'), findsOneWidget);

    // Pump animation forward
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashScreen renders on narrow screen (320px) with zero overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Acaderix'), findsOneWidget);
  });
}

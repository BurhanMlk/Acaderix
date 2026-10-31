import 'package:academy_management/core/widgets/empty_state.dart';
import 'package:academy_management/core/widgets/error_state.dart';
import 'package:academy_management/core/widgets/stat_card.dart';
import 'package:academy_management/features/super_admin/application/super_admin_providers.dart';
import 'package:academy_management/features/super_admin/domain/academy.dart';
import 'package:academy_management/features/super_admin/presentation/screens/super_admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SuperAdminDashboard displays live stats and academy data cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleAcademies = [
      Academy(
        id: '1',
        code: 'ACD-1',
        name: 'Alpha Academy',
        city: 'Lahore',
        status: 'active',
        branchCount: 3,
        registrationDate: DateTime(2026, 1, 1),
      ),
      Academy(
        id: '2',
        code: 'ACD-2',
        name: 'Beta Academy',
        city: 'Islamabad',
        status: 'pending',
        branchCount: 1,
        registrationDate: DateTime(2026, 2, 1),
      ),
      Academy(
        id: '3',
        code: 'ACD-3',
        name: 'Gamma Academy',
        city: 'Karachi',
        status: 'suspended',
        branchCount: 2,
        registrationDate: DateTime(2026, 3, 1),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academiesStreamProvider
              .overrideWith((ref) => Stream.value(sampleAcademies)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SuperAdminDashboard(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify Platform Overview header
    expect(find.text('Platform Overview'), findsOneWidget);

    // Drag to bring bottom items into view
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // Verify StatCards
    expect(find.widgetWithText(StatCard, 'Total Academies'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.widgetWithText(StatCard, 'Active'), findsOneWidget);
    expect(find.widgetWithText(StatCard, 'Pending'), findsOneWidget);
    expect(find.widgetWithText(StatCard, 'Suspended'), findsOneWidget);

    // Verify academies rendered in list
    expect(find.text('Alpha Academy'), findsOneWidget);
    expect(find.text('Beta Academy'), findsOneWidget);
    expect(find.textContaining('ACD-1'), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard displays empty state when 0 academies',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academiesStreamProvider
              .overrideWith((ref) => Stream.value(<Academy>[])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SuperAdminDashboard(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No academies yet'), findsOneWidget);
    expect(find.text('Registered academies will appear here.'), findsOneWidget);
  });

  testWidgets('SuperAdminDashboard displays error state and retry on error',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academiesStreamProvider.overrideWith(
            (ref) => Stream<List<Academy>>.error(
              Exception('Firestore permission denied or network failure'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SuperAdminDashboard(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.textContaining('Firestore permission denied'), findsOneWidget);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/app/app.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/data/placeholder_auth_repository.dart';

void main() {
  testWidgets('app boots from splash to the welcome screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(PlaceholderAuthRepository()),
        ],
        child: const AcademyApp(),
      ),
    );

    // Splash frame renders first while auth state is unknown.
    expect(find.text('Academy Management System'), findsOneWidget);

    // Let the placeholder auth repository resolve to unauthenticated and the
    // router redirect from /splash to /welcome.
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Welcome to Acadrix'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}

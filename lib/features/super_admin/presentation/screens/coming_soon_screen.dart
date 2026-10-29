import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

/// Placeholder shown for Super Admin modules that are not built yet.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Coming soon',
      message:
          'This module is being built and will be available in an upcoming phase.',
      icon: Icons.construction,
    );
  }
}

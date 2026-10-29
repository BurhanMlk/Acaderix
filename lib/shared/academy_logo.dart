import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/firestore_paths.dart';
import '../core/network/firebase_services.dart';
import '../core/widgets/app_logo.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';

/// Resolves the signed-in user's academy logo URL, if one has been uploaded.
///
/// Returns null for Super Admins (no tenant) and for tenants without a logo,
/// so callers can fall back to the bundled brand logo.
final academyLogoUrlProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = switch (authState) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };
  final academyId = user?.academyId;
  if (user == null || academyId == null || academyId.isEmpty) return null;

  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.doc(FirestorePaths.academy(academyId)).get();
  final url = doc.data()?['logoUrl'] as String?;
  return (url == null || url.isEmpty) ? null : url;
});

/// Shows the uploaded academy logo when available, otherwise the brand logo.
class AcademyLogo extends ConsumerWidget {
  const AcademyLogo({super.key, this.size = 36, this.borderRadius = 10});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(academyLogoUrlProvider).asData?.value;
    if (logoUrl == null || logoUrl.isEmpty) {
      return AppLogo(size: size, borderRadius: borderRadius);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            AppLogo(size: size, borderRadius: borderRadius),
      ),
    );
  }
}

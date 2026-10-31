import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/firestore_paths.dart';
import '../core/network/firebase_services.dart';
import '../core/widgets/app_logo.dart';
import '../features/academy_admin/application/academy_access_provider.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import 'current_academy_provider.dart';

/// Resolves the signed-in user's academy logo URL, if one has been uploaded.
///
/// Returns null for Super Admins (no tenant) and for tenants without a logo,
/// so callers can fall back to the bundled brand logo or academy avatar.
final academyLogoUrlProvider = FutureProvider<String?>((ref) async {
  // 1. Direct from real-time academy access provider stream
  final accessLogo = ref.watch(academyAccessProvider).value?.logoUrl.trim();
  if (accessLogo != null && accessLogo.isNotEmpty) {
    return accessLogo;
  }

  // 2. Resolve academyId from context or user profile
  final authState = ref.watch(authControllerProvider);
  final user = switch (authState) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };
  final academyId = ref.watch(currentAcademyIdProvider) ??
      user?.academyId ??
      ref.watch(academyAccessProvider).value?.academyId;

  if (academyId == null || academyId.isEmpty) return null;

  try {
    final firestore = ref.watch(firestoreProvider);
    final doc = await firestore.doc(FirestorePaths.academy(academyId)).get();
    final data = doc.data();
    final url = (data?['logoUrl'] as String? ??
            data?['logo'] as String? ??
            data?['imageUrl'] as String? ??
            data?['photoUrl'] as String? ??
            '')
        .trim();
    if (url.isNotEmpty) return url;

    // Fallback: Check subscription doc
    final subDoc = await firestore
        .collection(FirestorePaths.subscriptions)
        .doc(academyId)
        .get();
    final subUrl = (subDoc.data()?['logoUrl'] as String? ?? '').trim();
    return subUrl.isNotEmpty ? subUrl : null;
  } catch (_) {
    return null;
  }
});

/// Shows the uploaded academy logo when available, otherwise an initial badge or brand logo.
class AcademyLogo extends ConsumerWidget {
  const AcademyLogo({
    super.key,
    this.size = 36,
    this.borderRadius = 10,
    this.logoUrl,
    this.academyName,
  });

  final double size;
  final double borderRadius;
  final String? logoUrl;
  final String? academyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine effective logo from explicit prop, access stream, or future provider
    final streamLogo = ref.watch(academyAccessProvider).value?.logoUrl;
    final futureLogo = ref.watch(academyLogoUrlProvider).value;
    final effectiveUrl = (logoUrl?.trim().isNotEmpty == true)
        ? logoUrl!.trim()
        : ((streamLogo != null && streamLogo.trim().isNotEmpty)
            ? streamLogo.trim()
            : (futureLogo?.trim() ?? ''));

    if (effectiveUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(context, ref),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildFallback(context, ref);
  }

  Widget _buildFallback(BuildContext context, WidgetRef ref) {
    final name = (academyName?.trim().isNotEmpty == true)
        ? academyName!.trim()
        : (ref.watch(academyAccessProvider).value?.academyName.trim() ?? '');

    if (name.isNotEmpty) {
      final initial = name.substring(0, 1).toUpperCase();
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.45,
          ),
        ),
      );
    }

    return AppLogo(size: size, borderRadius: borderRadius);
  }
}

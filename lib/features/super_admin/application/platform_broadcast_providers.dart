import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/firebase_services.dart';
import '../data/firestore_platform_broadcast_repository.dart';
import '../domain/platform_broadcast.dart';
import '../domain/platform_broadcast_repository.dart';

/// Provides the active [PlatformBroadcastRepository].
final platformBroadcastRepositoryProvider =
    Provider<PlatformBroadcastRepository>((ref) {
  return FirestorePlatformBroadcastRepository(ref.watch(firestoreProvider));
});

/// Live stream of all platform broadcasts.
final platformBroadcastsStreamProvider =
    StreamProvider<List<PlatformBroadcast>>((ref) {
  return ref.watch(platformBroadcastRepositoryProvider).watchBroadcasts();
});

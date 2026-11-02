import 'platform_broadcast.dart';

/// Abstraction over platform broadcasts storage.
abstract interface class PlatformBroadcastRepository {
  Stream<List<PlatformBroadcast>> watchBroadcasts();
  Future<List<PlatformBroadcast>> getBroadcasts();
  Future<void> createBroadcast(PlatformBroadcast broadcast);
  Future<void> toggleBroadcastActive(String id, bool isActive);
  Future<void> deleteBroadcast(String id);
}

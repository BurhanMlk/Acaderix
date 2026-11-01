import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_notification.dart';

/// Service managing device push notification registration, permissions,
/// background listeners, and in-app heads-up notification broadcasts.
class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService();

  PushNotificationService() {
    _init();
  }

  final _foregroundNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onForegroundNotification =>
      _foregroundNotificationController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    // Firebase Messaging only runs natively on Android, iOS, macOS, Web.
    // Wrap in try-catch to allow safe running on Windows desktop & test runners.
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        try {
          // ignore: deprecated_member_use
          _fcmToken = await messaging.getToken();
        } catch (_) {}

        // Listen for foreground FCM messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            _foregroundNotificationController.add({
              'id': message.messageId ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              'academyId': message.data['academyId'] ?? '',
              'recipientId': message.data['recipientId'] ?? 'broadcast',
              'recipientRole': message.data['recipientRole'] ?? 'all',
              'title': notification.title ?? 'New Notice',
              'body': notification.body ?? '',
              'type': message.data['type'] ?? 'broadcast',
              'relatedId': message.data['relatedId'] ?? '',
            });
          }
        });
      }
    } catch (e) {
      debugPrint('PushNotificationService (Platform fallback): $e');
    }
  }

  /// Manually dispatches a simulated/local heads-up notification in-app.
  void dispatchLocalNotification(AppNotification notification) {
    _foregroundNotificationController.add({
      'id': notification.id,
      'academyId': notification.academyId,
      'recipientId': notification.recipientId,
      'recipientRole': notification.recipientRole,
      'title': notification.title,
      'body': notification.body,
      'type': notification.type,
      'relatedId': notification.relatedId,
    });
  }

  void dispose() {
    _foregroundNotificationController.close();
  }
}

/// Global provider for [PushNotificationService].
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  ref.onDispose(service.dispose);
  return service;
});

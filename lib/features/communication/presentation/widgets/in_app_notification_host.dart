import 'dart:async';
import 'package:flutter/material.dart';

import '../../application/push_notification_service.dart';

/// Wraps the application root or scaffold to display elegant, non-intrusive
/// in-app push notification banners when real-time alerts or broadcasts arrive
/// while the user is actively using the app.
class InAppNotificationHost extends StatefulWidget {
  const InAppNotificationHost({super.key, required this.child});

  final Widget child;

  @override
  State<InAppNotificationHost> createState() => _InAppNotificationHostState();
}

class _InAppNotificationHostState extends State<InAppNotificationHost>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Map<String, dynamic>>? _sub;
  late final AnimationController _animController;
  late final Animation<Offset> _offsetAnim;

  Map<String, dynamic>? _currentNotification;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _sub = PushNotificationService.instance.onForegroundNotification.listen(
      _handleIncomingNotification,
    );
  }

  void _handleIncomingNotification(Map<String, dynamic> data) {
    _dismissTimer?.cancel();
    setState(() {
      _currentNotification = data;
    });
    _animController.forward(from: 0.0);

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentNotification = null;
            });
          }
        });
      }
    });
  }

  void _dismissManually() {
    _dismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentNotification = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _sub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SlideTransition(
                position: _offsetAnim,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFF38BDF8)
                                .withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFF38BDF8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentNotification?['title'] ??
                                      'New Notification',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentNotification?['body'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white60,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _dismissManually,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

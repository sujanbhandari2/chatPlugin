import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  final service = LocalNotificationService();
  ref.onDispose(service.dispose);
  return service;
});

class LocalNotificationService {
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'healthchat_messages',
    'HealthChat Messages',
    description: 'Channel used for chat message notifications',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final _openedConversationController = StreamController<String>.broadcast();

  bool _initialized = false;

  Stream<String> get openedConversationIds =>
      _openedConversationController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> showForegroundMessage(RemoteMessage message) async {
    await initialize();

    final notification = message.notification;
    if (notification == null) {
      return;
    }

    final payload = jsonEncode({
      'conversationId': message.data['conversationId']?.toString(),
    });

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      notification.title ?? 'Healthcare Messenger',
      notification.body ?? 'New message',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  void _handleNotificationPayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;
      final conversationId = decoded['conversationId']?.toString();
      if (conversationId == null || conversationId.isEmpty) {
        return;
      }

      _openedConversationController.add(conversationId);
    } catch (_) {
      // Invalid payload, ignore.
    }
  }

  Future<void> dispose() async {
    await _openedConversationController.close();
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Background tap callback required by flutter_local_notifications.
}

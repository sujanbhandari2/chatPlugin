import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'local_notification_service.dart';
import 'push_token_api.dart';

final pushTokenApiProvider = Provider<PushTokenApi>((ref) {
  final dio = ref.watch(dioProvider);
  return PushTokenApi(dio);
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final messaging = ref.watch(firebaseMessagingProvider);
  final api = ref.watch(pushTokenApiProvider);
  final localNotifications = ref.watch(localNotificationServiceProvider);

  final service = PushNotificationService(
    messaging: messaging,
    api: api,
    localNotifications: localNotifications,
  );
  ref.onDispose(service.dispose);
  return service;
});

final foregroundPushMessagesProvider = StreamProvider<RemoteMessage>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  return service.foregroundMessages;
});

final openedPushMessagesProvider = StreamProvider<RemoteMessage>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  return service.openedMessages;
});

final openedPushConversationIdsProvider = StreamProvider<String>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  return service.openedConversationIds;
});

class PushNotificationService {
  PushNotificationService({
    required FirebaseMessaging messaging,
    required PushTokenApi api,
    required LocalNotificationService localNotifications,
  }) : _messaging = messaging,
       _api = api,
       _localNotifications = localNotifications;

  final FirebaseMessaging _messaging;
  final PushTokenApi _api;
  final LocalNotificationService _localNotifications;

  final _foregroundController = StreamController<RemoteMessage>.broadcast();
  final _openedController = StreamController<RemoteMessage>.broadcast();
  final _openedConversationController = StreamController<String>.broadcast();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  StreamSubscription<String>? _localTapSub;

  bool _initialized = false;
  String? _authToken;
  String? _registeredToken;
  String? _registeredForAuthToken;
  RemoteMessage? _pendingOpenedMessage;
  String? _pendingOpenedConversationId;

  Stream<RemoteMessage> get foregroundMessages => _foregroundController.stream;
  Stream<RemoteMessage> get openedMessages => _openedController.stream;
  Stream<String> get openedConversationIds =>
      _openedConversationController.stream;

  RemoteMessage? consumePendingOpenedMessage() {
    final pending = _pendingOpenedMessage;
    _pendingOpenedMessage = null;
    return pending;
  }

  String? consumePendingOpenedConversationId() {
    final pending = _pendingOpenedConversationId;
    _pendingOpenedConversationId = null;
    return pending;
  }

  Future<void> bindSession(String authToken) async {
    _authToken = authToken;

    await _initializeOnce();
    await _requestPermissions();

    final token = await _messaging.getToken();
    if (token != null) {
      await _registerTokenIfNeeded(token);
    } else {
      debugPrint('[push] FCM token is null (registration skipped).');
    }
  }

  Future<void> unbindSession(String authToken) async {
    final token = await _messaging.getToken();

    if (token != null) {
      try {
        await _api.unregisterToken(authToken: authToken, token: token);
      } catch (error) {
        debugPrint('[push] Failed to unregister token on logout: $error');
      }
    }

    _authToken = null;
    _registeredToken = null;
    _registeredForAuthToken = null;
  }

  Future<void> _initializeOnce() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await _localNotifications.initialize();

    _localTapSub = _localNotifications.openedConversationIds.listen((
      conversationId,
    ) {
      _pendingOpenedConversationId = conversationId;
      _openedConversationController.add(conversationId);
    });

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      _foregroundController.add(message);

      if (Platform.isAndroid) {
        unawaited(_localNotifications.showForegroundMessage(message));
      }
    });

    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _pendingOpenedMessage = message;
      _openedController.add(message);
      _emitConversationIdFromMessage(message);
    });

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      unawaited(_registerTokenIfNeeded(token));
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingOpenedMessage = initialMessage;
      _emitConversationIdFromMessage(initialMessage);
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('[push] Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _registerTokenIfNeeded(String fcmToken) async {
    final authToken = _authToken;
    if (authToken == null) {
      return;
    }

    if (_registeredToken == fcmToken && _registeredForAuthToken == authToken) {
      return;
    }

    try {
      await _api.registerToken(
        authToken: authToken,
        token: fcmToken,
        platform: _platformName,
      );
      _registeredToken = fcmToken;
      _registeredForAuthToken = authToken;
      debugPrint('[push] Registered FCM token successfully.');
    } catch (error) {
      debugPrint('[push] Failed to register FCM token: $error');
    }
  }

  void _emitConversationIdFromMessage(RemoteMessage message) {
    final conversationId = message.data['conversationId']?.toString();
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }

    _pendingOpenedConversationId = conversationId;
    _openedConversationController.add(conversationId);
  }

  String get _platformName {
    if (Platform.isIOS) {
      return 'IOS';
    }

    if (Platform.isAndroid) {
      return 'ANDROID';
    }

    return 'WEB';
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    await _localTapSub?.cancel();
    await _foregroundController.close();
    await _openedController.close();
    await _openedConversationController.close();
  }
}

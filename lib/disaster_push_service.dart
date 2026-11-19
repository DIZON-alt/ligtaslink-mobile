import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class DisasterPushService {
  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isConfigured => Firebase.apps.isNotEmpty;

  Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<void> updateSubscriptions({
    required bool enabled,
    required bool earthquakes,
    required bool typhoons,
  }) async {
    if (!isSupportedPlatform) {
      throw StateError('Push alerts are currently supported on Android and iOS.');
    }
    if (!isConfigured) {
      throw StateError(
        'Configure Firebase for this app and deploy the alert function to enable push notifications.',
      );
    }

    final messaging = FirebaseMessaging.instance;
    if (enabled) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        throw StateError('Notification permission was not granted.');
      }
    }

    await _setTopic(messaging, 'earthquake-alerts', enabled && earthquakes);
    await _setTopic(messaging, 'typhoon-alerts', enabled && typhoons);
  }

  Future<void> _setTopic(
    FirebaseMessaging messaging,
    String topic,
    bool enabled,
  ) {
    return enabled
        ? messaging.subscribeToTopic(topic)
        : messaging.unsubscribeFromTopic(topic);
  }
}

/*import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotifications {
  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Channel for important notifications.',
    importance: Importance.max,
  );

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen((msg) async {
      final n = msg.notification;
      if (n != null && !Platform.isIOS) {
        await _local.show(
          n.hashCode,
          n.title,
          n.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.max,
              priority: Priority.max,
            ),
          ),
          payload: msg.data.toString(),
        );
      }
    });
  }

  static String _sellerTopic(String supplierId) {
    return 'seller-${supplierId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.~%]'), '_')}';
  }

  static Future<void> subscribeSupplier(String supplierId) async {
    await _fcm.subscribeToTopic(_sellerTopic(supplierId));
  }

  static Future<void> unsubscribeSupplier(String supplierId) async {
    await _fcm.unsubscribeFromTopic(_sellerTopic(supplierId));
  }
}
*/
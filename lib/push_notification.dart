import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_notification_test/test.dart';
import 'package:push_notification_test/test_2.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PushNotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static final PushNotificationService _pushNotificationService = PushNotificationService._internal();

  PushNotificationService._internal();

  factory PushNotificationService() {
    return _pushNotificationService;
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future initialise() async {
    var settings = await _firebaseMessaging.getNotificationSettings();

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      await _firebaseMessaging.requestPermission(announcement: true);
    }

    //onLaunch(completely closed - not in background)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      _sendFromNotificationClick(message);
    });
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (response) async {
        log('Notification ${response.payload}');
        final data = jsonDecode(response.payload!);

        navigateNotification(data['click_action'], data);
      },
    );

    //onMessage(app in open)
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      // _sendFromNotificationClick(message, isNavigate: false);
      flutterLocalNotificationsPlugin.show(
        message?.data['id'] ?? 0,
        message?.notification?.title ?? '',
        message?.notification?.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_default_channel',
            'FCM Default Channel',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          ),
        ),
        payload: jsonEncode(message?.data),
      );
    });

    //onResume(app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
      _sendFromNotificationClick(message);
    });
    _firebaseMessaging.getToken().then((token) {
      // logInfo('FirebaseMessaging token: $token');
      log('FirebaseMessaging token: $token');
    });
    _firebaseMessaging.subscribeToTopic('test');
  }

  void _sendFromNotificationClick(RemoteMessage? message) {
    log('Notification ${message?.data}');
    log('Notification ${message?.notification?.toMap()}');
    if (message?.data['click_action'] != null) {
      navigateNotification(message?.data['click_action'], message?.data['body']);
    }
  }

  Future<void> navigateNotification(String action, Map<String, dynamic>? message, {int? id}) async {
    if (action == 'test') {
      navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => const TestPage()));
    }
    if (action == 'test2') {
      navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => const Test2()));
    }
  }
}

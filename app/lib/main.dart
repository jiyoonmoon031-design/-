import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/login_screen.dart';
import 'screens/alert_response_screen.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings = InitializationSettings(
    android: androidInit,
  );

  await localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;

      if (payload == null) return;

      final alertId = int.tryParse(payload);

      if (alertId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AlertResponseScreen(
              alertId: alertId,
            ),
          ),
        );
      }
    },
  );

  const androidChannel = AndroidNotificationChannel(
    'treatment_alert_channel',
    '조치 알림',
    description: '병해 조치 알림 채널',
    importance: Importance.high,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  await FirebaseMessaging.instance.requestPermission();

  final token = await FirebaseMessaging.instance.getToken();
  print('현재 앱 FCM 토큰: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('포그라운드 메시지 도착');
    print('title: ${message.notification?.title}');
    print('body: ${message.notification?.body}');
    print('data: ${message.data}');

    final alertId = message.data['alert_id']?.toString();

    localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? '조치 알림',
      message.notification?.body ?? '설정한 병해 조치 시간이 되었습니다.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'treatment_alert_channel',
          '조치 알림',
          channelDescription: '병해 조치 알림 채널',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: alertId,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('FCM 알림 클릭됨');

    final alertId = int.tryParse(
      message.data['alert_id']?.toString() ?? '',
    );

    if (alertId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlertResponseScreen(
            alertId: alertId,
          ),
        ),
      );
    }
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    Future.delayed(const Duration(seconds: 1), () {
      final alertId = int.tryParse(
        initialMessage.data['alert_id']?.toString() ?? '',
      );

      if (alertId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AlertResponseScreen(
              alertId: alertId,
            ),
          ),
        );
      }
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      home: const LoginScreen(),
    );
  }
}
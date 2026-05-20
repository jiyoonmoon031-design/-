import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'screens/login_screen.dart';
import 'screens/alert_response_screen.dart';
import 'screens/nearby_farm_screen.dart'; // 실제 파일명으로 수정

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void handleNotificationClickByData(Map<String, dynamic> data) {
  final type = data['type']?.toString();

  if (type == 'TREATMENT_ALERT') {
    final alertId = int.tryParse(data['alert_id']?.toString() ?? '');

    if (alertId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlertResponseScreen(alertId: alertId),
        ),
      );
    }
  } else if (type == 'NEARBY_DISEASE_ALERT') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const NearbyFarmScreen(), // 실제 화면명으로 수정
      ),
    );
  }
}

void handleNotificationClickByPayload(String? payload) {
  if (payload == null) return;

  final parts = payload.split('|');
  final type = parts[0];

  if (type == 'TREATMENT_ALERT') {
    if (parts.length < 2) return;

    final alertId = int.tryParse(parts[1]);

    if (alertId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlertResponseScreen(alertId: alertId),
        ),
      );
    }
  } else if (type == 'NEARBY_DISEASE_ALERT') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const NearbyFarmScreen(), // 실제 화면명으로 수정
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(
    nativeAppKey: '4247d8ba70681cad53dc62d303f91062',
  );
  print('Kakao Origin: ${await KakaoSdk.origin}');
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings = InitializationSettings(
    android: androidInit,
  );

  await localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      handleNotificationClickByPayload(response.payload);
    },
  );

  const androidChannel = AndroidNotificationChannel(
    'cropcare_alert_channel',
    'CropCare 알림',
    description: '조치 알림 및 인근 병해 알림 채널',
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

    final type = message.data['type']?.toString();

    String payload = '';

    if (type == 'TREATMENT_ALERT') {
      final alertId = message.data['alert_id']?.toString();
      payload = 'TREATMENT_ALERT|$alertId';
    } else if (type == 'NEARBY_DISEASE_ALERT') {
      payload = 'NEARBY_DISEASE_ALERT';
    }

    localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'CropCare 알림',
      message.notification?.body ?? '새로운 알림이 도착했습니다.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cropcare_alert_channel',
          'CropCare 알림',
          channelDescription: '조치 알림 및 인근 병해 알림 채널',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('FCM 알림 클릭됨');
    handleNotificationClickByData(message.data);
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    Future.delayed(const Duration(seconds: 1), () {
      handleNotificationClickByData(initialMessage.data);
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
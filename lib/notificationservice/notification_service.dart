import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> localNotification() async {
    AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("mipmap/ic_launcher");
    InitializationSettings settings = InitializationSettings(
      android: androidInitializationSettings,
    );
    flutterLocalNotificationsPlugin.initialize(settings: settings);
  }

  void requestNotificationPermission() async {
    NotificationSettings setting = await messaging.requestPermission(
      alert: true,
      badge: true,
      criticalAlert: true,
      sound: true,
    );
    if (setting.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permission granted by user');
    } else if (setting.authorizationStatus == AuthorizationStatus.provisional) {
      print("Permission granted provisionally");
    } else {
      print("Permission denied by user");
    }
  }

  Future<String?> getFcmToken() async {
    String? token = await messaging.getToken();
    print('Token: $token');
    return token;
  }
  void showNotification(RemoteMessage message) {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          "high_importance_channel",
          "High Importance Channel",
          importance: Importance.high,
          priority: Priority.high,
        );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    flutterLocalNotificationsPlugin.show(
      id:DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification?.title ?? "No Tittle",
      body: message.notification?.body ?? " No Body available",
      notificationDetails: notificationDetails,
    );
  }
}

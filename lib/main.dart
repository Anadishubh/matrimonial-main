import 'dart:developer';
import 'package:devotee/chat/firebase_options.dart';
import 'package:devotee/constants/color_constant.dart';
import 'package:devotee/controller/notification_controller.dart';
import 'package:devotee/pages/splash_Screen/splash_screen.dart';
import 'package:devotee/routes/app_routes.dart';
import 'package:devotee/utils/size.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_channel/flutter_notification_channel.dart';
import 'package:flutter_notification_channel/notification_importance.dart';
import 'package:get/get.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'chat/api/chat_controller.dart';

/// Local notification plugin instance
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Firebase Initialization
  await _initializeFirebase();

  // Step 2: Initialize GetX Controller for Notifications
  Get.put(NotificationController());

  // Step 3: Set System UI Overlay
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.primaryColor,
  ));

  // Step 4: Disable Screenshots
  await disableScreenshots();

  // Step 5: Run the App
  runApp(const MyApp());
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _deviceToken;
  final ChatController chatController = Get.put(ChatController());

  @override
  void initState() {
    super.initState();
    _getDeviceToken();
    FirebaseMessaging.instance.requestPermission();
    _initializeFlutterLocalNotifications();

    // Foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("mesaage =============${message.data['userId']}");
      if (chatController.currentChatId != message.data['userId']) {
        _showNotification(message);
      }
    });

    // App background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("User tapped on the notification: ${message.notification?.title}");
    });
  }

  Future<void> _getDeviceToken() async {
    // FirebaseMessaging instance  device token
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    setState(() {
      _deviceToken = token;
    });

    // Device token
    print("Device Token: $_deviceToken");
  }

  void _initializeFlutterLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  void _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // channel Id
      'High Importance Notifications', // channel Name
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'matrimony',
      home: const SplashScreen(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
    );
  }
}

/// Initialize Firebase
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    var result = await FlutterNotificationChannel.registerNotificationChannel(
        description: 'For Showing Message Notification',
        id: 'chats',
        importance: NotificationImportance.IMPORTANCE_HIGH,
        name: 'Chats');
    log('Notification Channel Result: $result');
  } catch (e) {
    log('Error initializing Firebase: $e');
  }
}

/// Disable screenshots and screen recording
Future<void> disableScreenshots() async {
  try {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    log('Screenshots disabled.');
  } catch (e) {
    log('Error disabling screenshots: $e');
  }
}

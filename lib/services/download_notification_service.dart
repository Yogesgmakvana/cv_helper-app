import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../models/app_state.dart';

class DownloadNotificationService {
  DownloadNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _androidDownloads = MethodChannel(
    'cv_helper/downloads',
  );
  static bool _ready = false;

  static Future<void> initialize() async {
    if (_ready) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null &&
        launchPayload.isNotEmpty) {
      await openSavedPdf(launchPayload);
    }
    _ready = true;
  }

  static Future<void> requestPermission() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> _onTap(NotificationResponse response) async {
    final uri = response.payload;
    if (uri != null && uri.isNotEmpty) await openSavedPdf(uri);
  }

  static Future<void> openSavedPdf(String location) async {
    if (location.startsWith('content:') || location.startsWith('file:')) {
      try {
        final opened = await _androidDownloads.invokeMethod<bool>(
          'openSavedPdf',
          {'location': location},
        );
        if (opened == true) return;
      } on PlatformException {
        // Fall back to the file opener for platforms without the Android bridge.
      } on MissingPluginException {
        // Fall back to the file opener for platforms without the Android bridge.
      }
    }
    await OpenFilex.open(location);
  }

  static Future<void> showSaved(String name, String location) async {
    await initialize();
    final fileName = name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
    appState.addNotification(
      AppNotificationModel(
        title: 'Resume saved',
        message: '$fileName is saved in Downloads. Tap to open it.',
        location: location,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: 'Resume saved',
      body: '$fileName is saved in Downloads. Tap to open it.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'resume_downloads',
          'Resume downloads',
          channelDescription: 'Notifications when a resume PDF is saved',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: location,
    );
  }
}

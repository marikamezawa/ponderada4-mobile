import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // O plugin nativo é usado somente em Android e iOS.
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_supported) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermission() async {
    if (!_supported) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleWaterReminder({
    required String plantId,
    required String plantName,
    required int frequencyDays,
  }) async {
    if (!_supported) return;
    await _plugin.periodicallyShowWithDuration(
      plantId.hashCode,
      'Hora de regar!',
      '$plantName está com sede. Não se esqueça!',
      Duration(days: frequencyDays),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'care_reminders',
          'Lembretes de Cuidados',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<void> scheduleFertilizeReminder({
    required String plantId,
    required String plantName,
    required int frequencyDays,
  }) async {
    if (!_supported) return;
    await _plugin.periodicallyShowWithDuration(
      '${plantId}_fertilize'.hashCode,
      'Hora de adubar!',
      '$plantName precisa de nutrientes. Hora de adubar.',
      Duration(days: frequencyDays),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'care_reminders',
          'Lembretes de Cuidados',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<void> cancelReminder(String plantId) async {
    if (!_supported) return;
    await _plugin.cancel(plantId.hashCode);
    await _plugin.cancel('${plantId}_fertilize'.hashCode);
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    await _plugin.cancelAll();
  }
}

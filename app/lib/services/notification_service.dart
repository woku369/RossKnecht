import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Plant/storniert lokale Erinnerungen fuer alle faelligkeitsbasierten
/// Entitaeten (Impfungen, Entwurmung, Gesundheitstermine, Turnierlizenzen,
/// Decken-Impraegnierung, Versicherungen, Wartungs-To-Dos).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'rossknecht_erinnerungen';
  static const _channelName = 'RossKnecht Erinnerungen';
  static const _channelDescription =
      'Erinnerungen zu Impfungen, Entwurmung, Turnier- und Wartungsterminen';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Vienna'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  // Deterministische numerische Notification-ID aus der fachlichen
  // String-ID - erspart ein eigenes DB-Feld fuer die Notification-ID und
  // macht cancelReminder() ohne separate ID-Verwaltung moeglich.
  int _notificationId(String sourceId) => sourceId.hashCode & 0x7fffffff;

  Future<void> scheduleReminder({
    required String sourceId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await init();
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _notificationId(sourceId),
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String sourceId) async {
    await init();
    await _plugin.cancel(_notificationId(sourceId));
  }
}

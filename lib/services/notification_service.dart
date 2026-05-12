import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> sendDwellAlert(String plateNumber, int hours) async {
    if (hours < 24) return;
    await _plugin.show(
      plateNumber.hashCode,
      'تنبيه مكوث طويل',
      'الشاحنة $plateNumber موجودة منذ $hours ساعة',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dwell_alerts',
          'تنبيهات المكوث',
          channelDescription: 'إشعارات الشاحنات التي تجاوزت وقت المكوث',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> sendEventConfirmation(String plateNumber, String eventType) async {
    final label = eventType == 'entry' ? 'دخول' : 'خروج';
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'تم التسجيل',
      'تم تسجيل $label الشاحنة $plateNumber',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_confirmations',
          'تأكيدات العمليات',
          channelDescription: 'إشعارات تأكيد التسجيل',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/reminders/notification_scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzlib;

/// Implementação real de [NotificationScheduler] usando [FlutterLocalNotificationsPlugin].
///
/// Agenda notificações às 09:00 no dia de vencimento do lembrete.
/// Timezone fixado em America/Sao_Paulo (pode ser refinado com detecção automática futuramente).
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'reminders';
  static const String _channelName = 'Lembretes';
  static const String _channelDescription = 'Lembretes do AutoLog';
  static const String _localTimezone = 'America/Sao_Paulo';

  @override
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tzlib.setLocalLocation(tzlib.getLocation(_localTimezone));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  @override
  Future<void> scheduleReminder(Reminder r) async {
    if (r.type != ReminderType.porData) return;
    if (r.isDone) return;
    if (r.dueDate == null) return;
    if (r.dueDate!.isBefore(DateTime.now())) return;
    if (r.deletedAt != null) return;

    final dueDate = r.dueDate!;
    final location = tzlib.getLocation(_localTimezone);
    final scheduledDate = tzlib.TZDateTime(
      location,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9, // 09:00
    );

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      r.id.hashCode.abs(),
      r.title,
      'Lembrete vencendo hoje',
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelReminder(String id) async {
    await _plugin.cancel(id.hashCode.abs());
  }

  @override
  Future<void> showNow({
    required String id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id.hashCode.abs(), title, body, details);
  }
}

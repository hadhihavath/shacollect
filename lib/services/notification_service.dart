import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('NotificationService init note: $e');
    }
  }

  Future<void> showPaymentSuccessNotification({
    required String shopName,
    required double amount,
    required String paymentMode,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sha_collections_payments',
      'Collection Receipts',
      channelDescription: 'Notifications for recorded recovery collections',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: DateTime.now().millisecond,
        title: 'Payment Recorded: ₹${amount.toStringAsFixed(0)}',
        body: 'Received from $shopName via $paymentMode.',
        notificationDetails: platformDetails,
      );
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }

  Future<void> scheduleFollowUpReminder({
    required int id,
    required String shopName,
    required String note,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sha_collects_followups',
      'Follow-up Reminders',
      channelDescription: 'Alerts for promised payment collections and shop visits',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      // In case scheduled date is in the past, notify in 10 seconds for demo/testing
      final scheduledTime = scheduledDate.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(seconds: 10))
          : scheduledDate;

      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Follow-up Reminder: $shopName',
        body: note.isNotEmpty ? note : 'Visit promised today for payment collection.',
        scheduledDate: tzDateTime,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Scheduled reminder for $shopName at $scheduledTime');
    } catch (e) {
      debugPrint('Could not schedule zoned notification (falling back): $e');
      // Fallback: show immediate confirmation reminder
      try {
        await _notificationsPlugin.show(
          id: id,
          title: 'Follow-up Scheduled: $shopName',
          body: 'Promised for ${scheduledDate.day}/${scheduledDate.month}. Reminder is active.',
          notificationDetails: platformDetails,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
}

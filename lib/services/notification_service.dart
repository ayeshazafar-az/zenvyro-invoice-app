// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // Imports the plugin instance we created in main.dart

class NotificationService {
  static Future<void> scheduleNotification(String invoiceId, String customerName, DateTime dueDate) async {
    // Schedule for 9:00 AM on the due date
    final scheduledDate = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9, 0,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: invoiceId.hashCode, // Unique ID for each notification
      title: 'Invoice Due Today!',
      body: 'Reminder: Invoice for $customerName is due today.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'invoice_channel',
          'Invoice Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
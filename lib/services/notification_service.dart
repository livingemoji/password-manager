import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> showPasswordRevealNotification(String entryName) async {
    const android = AndroidNotificationDetails('vault_channel', 'Vault Events');
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(
      0,
      'Password Revealed',
      'Password for $entryName was revealed.',
      details,
    );
  }

  // New method to show a notification when a password is copied to clipboard
  Future<void> showPasswordCopiedNotification(String entryName) async {
    const android = AndroidNotificationDetails('vault_channel', 'Vault Events');
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(
      1,
      'Password Copied',
      'Password for $entryName was copied to clipboard.',
      details,
    );
  }
} 
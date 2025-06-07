import 'package:flutter/services.dart';
import 'package:timer/timer.dart';

class ClipboardService {
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(seconds: 20), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  // New method to copy a password to clipboard and show a notification
  void copyPasswordToClipboard(String password, String entryName, NotificationService notificationService) {
    copyToClipboard(password);
    notificationService.showPasswordCopiedNotification(entryName);
  }
} 
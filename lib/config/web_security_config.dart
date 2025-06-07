import 'package:flutter/foundation.dart';

class WebSecurityConfig {
  // Web-specific security settings
  static const bool enableServiceWorker = true;
  static const bool enableHttps = true;
  static const bool enableCSP = true;
  static const bool enableSecureCookies = true;
  
  // Content Security Policy
  static const String cspHeader = '''
    default-src 'self';
    script-src 'self' 'unsafe-inline' 'unsafe-eval';
    style-src 'self' 'unsafe-inline';
    img-src 'self' data:;
    connect-src 'self';
    font-src 'self';
    object-src 'none';
    media-src 'self';
    frame-src 'none';
  ''';

  // Cookie settings
  static const bool httpOnly = true;
  static const bool secure = true;
  static const bool sameSite = true;
  static const Duration cookieExpiry = Duration(days: 7);

  // Web storage settings
  static const bool useIndexedDB = true;
  static const bool useLocalStorage = false;
  static const bool useSessionStorage = true;

  // Web-specific timeouts
  static const Duration webSessionTimeout = Duration(minutes: 30);
  static const Duration webInactivityTimeout = Duration(minutes: 5);

  // Web-specific security features
  static const bool preventDevTools = kReleaseMode;
  static const bool preventRightClick = true;
  static const bool preventCopyPaste = true;
  static const bool preventScreenshots = true;

  // Web-specific error handling
  static const bool showDetailedErrors = !kReleaseMode;
  static const bool logToConsole = !kReleaseMode;
  static const bool enableErrorReporting = true;

  // Web-specific performance settings
  static const bool enableCompression = true;
  static const bool enableCaching = true;
  static const Duration cacheDuration = Duration(days: 7);

  // Web-specific backup settings
  static const bool enableWebBackup = true;
  static const bool enableAutoBackup = true;
  static const Duration backupInterval = Duration(hours: 24);

  // Web-specific sync settings
  static const bool enableWebSync = true;
  static const Duration syncInterval = Duration(minutes: 15);
  static const bool syncOnChange = true;
} 
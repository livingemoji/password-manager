import 'dart:async';
import 'package:flutter/foundation.dart';

class SecurityConfig {
  // Password Policy
  static const int minPasswordLength = 12;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;

  // Authentication
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration sessionTimeout = Duration(minutes: 5);
  static const Duration biometricTimeout = Duration(minutes: 10);

  // Encryption
  static const int keyLength = 32; // 256 bits
  static const int pbkdf2Iterations = 100000;
  static const int argon2Iterations = 3;
  static const int argon2Memory = 65536;
  static const int argon2Parallelism = 4;
  static const int saltLength = 32;
  static const String encryptionVersion = '1.0';

  // Memory Security
  static const Duration sensitiveDataTimeout = Duration(minutes: 1);
  static const Duration keyTimeout = Duration(minutes: 5);
  static const Duration clipboardTimeout = Duration(seconds: 30);
  static const Duration memoryCleanupInterval = Duration(minutes: 1);
  static const bool enableMemoryProtection = true;
  static const bool clearClipboardOnBackground = true;

  // Input Validation
  static const int maxInputLength = 1024;
  static final RegExp safeInputPattern = RegExp(r'^[a-zA-Z0-9@#$%^&*()_+\-=\[\]{};\'"\\|,.<>\/?]+$');

  // TLS Configuration (for cloud sync)
  static const bool enforceTLS = true;
  static const int minTLSVersion = 1.2;
  static const List<String> allowedCipherSuites = [
    'TLS_AES_256_GCM_SHA384',
    'TLS_CHACHA20_POLY1305_SHA256',
    'TLS_AES_128_GCM_SHA256',
  ];

  // Database Security
  static const bool encryptDatabase = true;
  static const String databaseEncryptionAlgorithm = 'AES-256-GCM';
  static const Duration databaseKeyRotation = Duration(days: 30);

  // Logging
  static const bool logSecurityEvents = true;
  static const bool logFailedAttempts = true;
  static const bool logPasswordReveals = true;
  static const bool logClipboardOperations = true;

  // Security Logging
  static const int maxSecurityLogs = 1000;
  static const bool enableSecurityAudit = true;
  static const Duration securityAuditInterval = Duration(hours: 24);

  // Device Security
  static const bool requireDeviceSecurity = true;
  static const bool enforceScreenLock = true;
  static const bool preventScreenshots = true;

  // Data Export/Import
  static const bool enableDataExport = true;
  static const bool requireAuthenticationForExport = true;
  static const int maxExportSize = 10 * 1024 * 1024; // 10MB

  // Debug Mode
  static bool get isDebugMode => kDebugMode;
  static const bool enableDebugLogging = false;
  static const bool allowInsecureInDebug = false;
} 
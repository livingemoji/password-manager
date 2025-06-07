import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import '../config/security_config.dart';
import 'memory_security_service.dart';
import 'secure_storage_service.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final MemorySecurityService _memorySecurity = MemorySecurityService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  Timer? _inactivityTimer;
  DateTime? _lastActivityTime;
  int _failedAttempts = 0;
  bool _isLocked = false;
  String? _currentSessionToken;

  // Session Management
  Future<void> startSession() async {
    _currentSessionToken = _generateSessionToken();
    _lastActivityTime = DateTime.now();
    _resetInactivityTimer();
    await _secureStorage.storeAppSettings({
      'session_token': _currentSessionToken,
      'session_start': _lastActivityTime!.toIso8601String(),
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(SecurityConfig.sessionTimeout, () {
      _lockSession();
    });
  }

  Future<void> _lockSession() async {
    _isLocked = true;
    _currentSessionToken = null;
    _memorySecurity.clearAllSensitiveData();
    await _secureStorage.storeAppSettings({
      'session_locked': true,
      'lock_time': DateTime.now().toIso8601String(),
    });
  }

  // Activity Tracking
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    _resetInactivityTimer();
  }

  bool isSessionActive() {
    if (_isLocked) return false;
    if (_lastActivityTime == null) return false;
    
    final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime!);
    return timeSinceLastActivity < SecurityConfig.sessionTimeout;
  }

  // Brute Force Protection
  Future<bool> recordFailedAttempt() async {
    _failedAttempts++;
    await _secureStorage.storeAppSettings({
      'failed_attempts': _failedAttempts.toString(),
      'last_failed_attempt': DateTime.now().toIso8601String(),
    });

    if (_failedAttempts >= SecurityConfig.maxLoginAttempts) {
      await _lockAccount();
      return false;
    }
    return true;
  }

  Future<void> _lockAccount() async {
    final lockoutUntil = DateTime.now().add(SecurityConfig.lockoutDuration);
    await _secureStorage.storeAppSettings({
      'account_locked': true,
      'lockout_until': lockoutUntil.toIso8601String(),
    });
  }

  Future<bool> isAccountLocked() async {
    final settings = await _secureStorage.getAppSettings();
    if (settings == null) return false;

    final lockoutUntil = settings['lockout_until'];
    if (lockoutUntil == null) return false;

    final lockoutTime = DateTime.parse(lockoutUntil);
    if (DateTime.now().isAfter(lockoutTime)) {
      await _secureStorage.storeAppSettings({
        'account_locked': false,
        'failed_attempts': '0',
      });
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  // Device Security
  Future<bool> isDeviceSecure() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Clipboard Security
  Future<void> secureClipboard(String data) async {
    _memorySecurity.storeSensitiveData(
      'clipboard_data',
      data,
      cleanupAfter: SecurityConfig.clipboardTimeout,
    );
  }

  // Input Validation
  bool isInputSafe(String input) {
    if (input.length > SecurityConfig.maxInputLength) return false;
    return SecurityConfig.safeInputPattern.hasMatch(input);
  }

  // Secure Random Generation
  String generateSecureRandom(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // Session Token Generation
  String _generateSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return sha256.convert(values).toString();
  }

  // Security Logging
  Future<void> logSecurityEvent(String event, {Map<String, dynamic>? details}) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'event': event,
      'timestamp': timestamp,
      'session_token': _currentSessionToken,
      'details': details,
    };

    // Store in secure storage
    final logs = await _secureStorage.getAppSettings()?['security_logs'] ?? [];
    logs.add(logEntry);
    await _secureStorage.storeAppSettings({
      'security_logs': logs,
    });
  }

  // Security Audit
  Future<Map<String, dynamic>> performSecurityAudit() async {
    final audit = {
      'timestamp': DateTime.now().toIso8601String(),
      'device_secure': await isDeviceSecure(),
      'session_active': isSessionActive(),
      'failed_attempts': _failedAttempts,
      'account_locked': await isAccountLocked(),
      'last_activity': _lastActivityTime?.toIso8601String(),
    };

    await logSecurityEvent('security_audit', details: audit);
    return audit;
  }

  // Secure Data Export
  Future<String> exportSecureData(Map<String, dynamic> data) async {
    final exportToken = _generateSessionToken();
    final exportData = {
      'data': data,
      'export_token': exportToken,
      'timestamp': DateTime.now().toIso8601String(),
      'version': 1,
    };

    await logSecurityEvent('data_export', details: {
      'export_token': exportToken,
    });

    return jsonEncode(exportData);
  }

  // Secure Data Import
  Future<Map<String, dynamic>> importSecureData(String jsonData) async {
    final importData = jsonDecode(jsonData);
    
    if (importData['version'] != 1) {
      throw Exception('Unsupported data version');
    }

    await logSecurityEvent('data_import', details: {
      'import_token': importData['export_token'],
    });

    return importData['data'];
  }

  // Cleanup
  void dispose() {
    _inactivityTimer?.cancel();
    _memorySecurity.clearAllSensitiveData();
  }
} 
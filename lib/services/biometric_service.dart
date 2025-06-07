import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'secure_storage_service.dart';
import '../config/security_config.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService();
  DateTime? _lastAuthTime;

  // Check if biometrics are available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      return await _secureStorage.getBiometricSettings();
    } catch (e) {
      return false;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      // Verify biometric is available
      if (!await isBiometricAvailable()) {
        throw Exception('Biometric authentication is not available');
      }

      // Test authentication
      final authenticated = await authenticate(
        'Verify your identity to enable biometric login',
      );

      if (authenticated) {
        await _secureStorage.storeBiometricSettings(true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Disable biometric authentication
  Future<void> disableBiometric() async {
    await _secureStorage.storeBiometricSettings(false);
  }

  // Authenticate with biometrics
  Future<bool> authenticate(String reason) async {
    try {
      // Check if biometric is enabled
      if (!await isBiometricEnabled()) {
        return false;
      }

      // Check if we need to re-authenticate
      if (_lastAuthTime != null) {
        final timeSinceLastAuth = DateTime.now().difference(_lastAuthTime!);
        if (timeSinceLastAuth < SecurityConfig.biometricTimeout) {
          return true;
        }
      }

      // Perform authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _lastAuthTime = DateTime.now();
      }

      return authenticated;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        return false;
      }
      rethrow;
    }
  }

  // Get biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      default:
        return 'Unknown';
    }
  }

  // Check if authentication is still valid
  bool isAuthenticationValid() {
    if (_lastAuthTime == null) return false;
    
    final timeSinceLastAuth = DateTime.now().difference(_lastAuthTime!);
    return timeSinceLastAuth < SecurityConfig.biometricTimeout;
  }

  // Clear authentication state
  void clearAuthenticationState() {
    _lastAuthTime = null;
  }
} 
import 'package:local_auth/local_auth.dart';
import 'package:argon2/argon2.dart';
import 'dart:async';
import 'storage_service.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final StorageService _storageService;
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  Timer? _lockoutTimer;
  int _failedAttempts = 0;

  AuthService(this._storageService);

  // Hash password using Argon2
  Future<String> hashPassword(String password, String salt) async {
    final params = Argon2Parameters(
      type: Argon2Type.argon2id,
      version: Argon2Version.V13,
      iterations: 3,
      memory: 65536,
      parallelism: 4,
      salt: salt.codeUnits,
    );
    
    final result = await argon2.hashString(
      password,
      parameters: params,
    );
    return result.encodedString;
  }

  // Store master password hash and salt
  Future<void> setMasterPassword(String password) async {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = await hashPassword(password, salt);
    await _storageService.write('master_hash', hash);
    await _storageService.write('master_salt', salt);
    await _storageService.write('failed_attempts', '0');
  }

  // Verify master password with lockout
  Future<bool> verifyMasterPassword(String password) async {
    if (await isLocked()) {
      throw Exception('Account is locked. Please try again later.');
    }

    final salt = await _storageService.read('master_salt');
    final hash = await _storageService.read('master_hash');
    if (salt == null || hash == null) return false;

    final newHash = await hashPassword(password, salt);
    final isValid = newHash == hash;

    if (!isValid) {
      _failedAttempts++;
      await _storageService.write('failed_attempts', _failedAttempts.toString());
      
      if (_failedAttempts >= _maxAttempts) {
        await _lockAccount();
      }
    } else {
      _failedAttempts = 0;
      await _storageService.write('failed_attempts', '0');
    }

    return isValid;
  }

  Future<bool> isLocked() async {
    final lockoutUntil = await _storageService.read('lockout_until');
    if (lockoutUntil == null) return false;
    
    final lockoutTime = DateTime.parse(lockoutUntil);
    if (DateTime.now().isAfter(lockoutTime)) {
      await _storageService.delete('lockout_until');
      return false;
    }
    return true;
  }

  Future<void> _lockAccount() async {
    final lockoutUntil = DateTime.now().add(_lockoutDuration);
    await _storageService.write('lockout_until', lockoutUntil.toIso8601String());
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(_lockoutDuration, () {
      _failedAttempts = 0;
      _storageService.write('failed_attempts', '0');
    });
  }

  // Biometric authentication
  Future<bool> authenticateWithBiometrics() async {
    if (await isLocked()) {
      throw Exception('Account is locked. Please try again later.');
    }

    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) return false;
    
    return await _localAuth.authenticate(
      localizedReason: 'Authenticate to access your vault',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }

  // New method to check if biometrics are available
  Future<bool> isBiometricsAvailable() async {
    return await _localAuth.canCheckBiometrics;
  }

  void dispose() {
    _lockoutTimer?.cancel();
  }
} 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/security_config.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Store encryption key
  Future<void> storeEncryptionKey(String key) async {
    await _storage.write(
      key: 'encryption_key',
      value: key,
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  // Get encryption key
  Future<String?> getEncryptionKey() async {
    return await _storage.read(key: 'encryption_key');
  }

  // Store master password hash
  Future<void> storeMasterPasswordHash(String hash) async {
    await _storage.write(
      key: 'master_password_hash',
      value: hash,
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  // Get master password hash
  Future<String?> getMasterPasswordHash() async {
    return await _storage.read(key: 'master_password_hash');
  }

  // Store biometric settings
  Future<void> storeBiometricSettings(bool enabled) async {
    await _storage.write(
      key: 'biometric_enabled',
      value: enabled.toString(),
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  // Get biometric settings
  Future<bool> getBiometricSettings() async {
    final value = await _storage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  // Store last sync timestamp
  Future<void> storeLastSyncTimestamp(DateTime timestamp) async {
    await _storage.write(
      key: 'last_sync_timestamp',
      value: timestamp.toIso8601String(),
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    final value = await _storage.read(key: 'last_sync_timestamp');
    if (value == null) return null;
    return DateTime.parse(value);
  }

  // Store database encryption key
  Future<void> storeDatabaseKey(String key) async {
    await _storage.write(
      key: 'database_key',
      value: key,
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  // Get database encryption key
  Future<String?> getDatabaseKey() async {
    return await _storage.read(key: 'database_key');
  }

  // Store backup encryption key
  Future<void> storeBackupKey(String key) async {
    await _storage.write(
      key: 'backup_key',
      value: key,
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  // Get backup encryption key
  Future<String?> getBackupKey() async {
    return await _storage.read(key: 'backup_key');
  }

  // Store app settings
  Future<void> storeAppSettings(Map<String, dynamic> settings) async {
    await _storage.write(
      key: 'app_settings',
      value: jsonEncode(settings),
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  // Get app settings
  Future<Map<String, dynamic>?> getAppSettings() async {
    final value = await _storage.read(key: 'app_settings');
    if (value == null) return null;
    return jsonDecode(value) as Map<String, dynamic>;
  }

  // Clear all secure storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Delete specific key
  Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Get all keys
  Future<Map<String, String>> getAllKeys() async {
    return await _storage.readAll();
  }
} 
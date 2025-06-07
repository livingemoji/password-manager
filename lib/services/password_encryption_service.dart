import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../config/security_config.dart';
import 'memory_security_service.dart';

class PasswordEncryptionService {
  static final PasswordEncryptionService _instance = PasswordEncryptionService._internal();
  factory PasswordEncryptionService() => _instance;
  PasswordEncryptionService._internal();

  final MemorySecurityService _memorySecurity = MemorySecurityService();

  // Derive encryption key using PBKDF2
  Uint8List deriveKey(String password, String salt) {
    final key = pbkdf2(
      password: password,
      salt: salt,
      iterations: SecurityConfig.pbkdf2Iterations,
      keyLength: SecurityConfig.keyLength,
    );
    
    // Store key in memory with auto-cleanup
    _memorySecurity.storeSensitiveData(
      'derived_key',
      key,
      cleanupAfter: SecurityConfig.keyTimeout,
    );
    
    return key;
  }

  // PBKDF2 implementation
  Uint8List pbkdf2({
    required String password,
    required String salt,
    required int iterations,
    required int keyLength,
  }) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: keyLength * 8,
    );
    final secretKey = SecretKey(utf8.encode(password));
    final nonce = utf8.encode(salt);
    return pbkdf2.deriveKey(secretKey: secretKey, nonce: nonce).extractSync();
  }

  // Encrypt password with AES-256
  String encryptPassword(String password, Uint8List key) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(key),
      mode: encrypt.AESMode.cbc,
      padding: 'PKCS7',
    ));
    
    final encrypted = encrypter.encrypt(password, iv: iv);
    final result = jsonEncode({
      'iv': iv.base64,
      'data': encrypted.base64,
      'version': 1, // For future compatibility
    });
    
    // Clear sensitive data from memory
    _memorySecurity.overwriteString(password);
    
    return result;
  }

  // Decrypt password with AES-256
  String decryptPassword(String encryptedJson, Uint8List key) {
    final map = jsonDecode(encryptedJson);
    final iv = encrypt.IV.fromBase64(map['iv']);
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(key),
      mode: encrypt.AESMode.cbc,
      padding: 'PKCS7',
    ));
    
    final decrypted = encrypter.decrypt64(map['data'], iv: iv);
    
    // Store decrypted password in memory with auto-cleanup
    _memorySecurity.storeSensitiveData(
      'decrypted_password',
      decrypted,
      cleanupAfter: SecurityConfig.sensitiveDataTimeout,
    );
    
    return decrypted;
  }

  // Encrypt password entry
  Map<String, dynamic> encryptPasswordEntry(Map<String, dynamic> entry, Uint8List key) {
    final encryptedEntry = Map<String, dynamic>.from(entry);
    
    // Encrypt password
    encryptedEntry['password'] = encryptPassword(entry['password'], key);
    
    // Encrypt notes if present
    if (entry['notes'] != null) {
      encryptedEntry['notes'] = encryptPassword(entry['notes'], key);
    }
    
    // Add encryption metadata
    encryptedEntry['encryption_version'] = 1;
    encryptedEntry['encryption_timestamp'] = DateTime.now().toIso8601String();
    
    return encryptedEntry;
  }

  // Decrypt password entry
  Map<String, dynamic> decryptPasswordEntry(Map<String, dynamic> entry, Uint8List key) {
    final decryptedEntry = Map<String, dynamic>.from(entry);
    
    // Decrypt password
    decryptedEntry['password'] = decryptPassword(entry['password'], key);
    
    // Decrypt notes if present
    if (entry['notes'] != null) {
      decryptedEntry['notes'] = decryptPassword(entry['notes'], key);
    }
    
    // Remove encryption metadata
    decryptedEntry.remove('encryption_version');
    decryptedEntry.remove('encryption_timestamp');
    
    return decryptedEntry;
  }

  // Generate a secure salt
  String generateSalt() {
    final random = encrypt.IV.fromSecureRandom(16);
    return base64Encode(random.bytes);
  }

  // Verify password strength
  bool isPasswordStrong(String password) {
    if (password.length < SecurityConfig.minPasswordLength) return false;
    
    bool hasUppercase = false;
    bool hasLowercase = false;
    bool hasNumbers = false;
    bool hasSpecialChars = false;
    
    for (var char in password.codeUnits) {
      if (char >= 65 && char <= 90) hasUppercase = true;
      if (char >= 97 && char <= 122) hasLowercase = true;
      if (char >= 48 && char <= 57) hasNumbers = true;
      if ((char >= 33 && char <= 47) || 
          (char >= 58 && char <= 64) || 
          (char >= 91 && char <= 96) || 
          (char >= 123 && char <= 126)) {
        hasSpecialChars = true;
      }
    }
    
    return hasUppercase && hasLowercase && hasNumbers && hasSpecialChars;
  }

  // Hash password for storage
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Verify password hash
  bool verifyPasswordHash(String password, String salt, String storedHash) {
    final hash = hashPassword(password, salt);
    return hash == storedHash;
  }

  // Clear sensitive data from memory
  void clearSensitiveData() {
    _memorySecurity.clearAllSensitiveData();
  }

  // Dispose
  void dispose() {
    clearSensitiveData();
  }
} 
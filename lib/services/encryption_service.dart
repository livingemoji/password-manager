import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'memory_security_service.dart';

class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _iterations = 100000;
  final MemorySecurityService _memorySecurity = MemorySecurityService();

  // Derive key from master password using PBKDF2
  Uint8List deriveKey(String password, String salt) {
    final key = pbkdf2(
      password: password,
      salt: salt,
      iterations: _iterations,
      keyLength: _keyLength,
    );
    
    // Store key in memory with auto-cleanup
    _memorySecurity.storeSensitiveData('derived_key', key, 
      cleanupAfter: const Duration(minutes: 5));
    
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

  // Encrypt data with memory protection
  String encryptData(String plainText, Uint8List key) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(key),
      mode: encrypt.AESMode.cbc,
      padding: 'PKCS7',
    ));
    
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final result = jsonEncode({'iv': iv.base64, 'data': encrypted.base64});
    
    // Clear sensitive data from memory
    _memorySecurity.overwriteString(plainText);
    
    return result;
  }

  // Decrypt data with memory protection
  String decryptData(String encryptedJson, Uint8List key) {
    final map = jsonDecode(encryptedJson);
    final iv = encrypt.IV.fromBase64(map['iv']);
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(key),
      mode: encrypt.AESMode.cbc,
      padding: 'PKCS7',
    ));
    
    final decrypted = encrypter.decrypt64(map['data'], iv: iv);
    
    // Store decrypted data in memory with auto-cleanup
    _memorySecurity.storeSensitiveData('decrypted_data', decrypted,
      cleanupAfter: const Duration(minutes: 1));
    
    return decrypted;
  }

  // Encrypt password entry with memory protection
  String encryptPasswordEntry(PasswordEntry entry, Uint8List key) {
    final json = jsonEncode(entry.toJson());
    final encrypted = encryptData(json, key);
    
    // Clear sensitive data from memory
    _memorySecurity.overwriteString(json);
    
    return encrypted;
  }

  void dispose() {
    _memorySecurity.clearAllSensitiveData();
  }
} 
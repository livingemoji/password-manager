import 'dart:async';
import 'dart:typed_data';

class MemorySecurityService {
  static final MemorySecurityService _instance = MemorySecurityService._internal();
  factory MemorySecurityService() => _instance;
  MemorySecurityService._internal();

  final Map<String, Timer> _cleanupTimers = {};
  final Map<String, dynamic> _sensitiveData = {};

  // Store sensitive data with auto-cleanup
  void storeSensitiveData(String key, dynamic data, {Duration? cleanupAfter}) {
    _sensitiveData[key] = data;
    
    if (cleanupAfter != null) {
      _cleanupTimers[key]?.cancel();
      _cleanupTimers[key] = Timer(cleanupAfter, () {
        clearSensitiveData(key);
      });
    }
  }

  // Get sensitive data
  T? getSensitiveData<T>(String key) {
    return _sensitiveData[key] as T?;
  }

  // Clear specific sensitive data
  void clearSensitiveData(String key) {
    if (_sensitiveData[key] is Uint8List) {
      final bytes = _sensitiveData[key] as Uint8List;
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
    }
    _sensitiveData.remove(key);
    _cleanupTimers[key]?.cancel();
    _cleanupTimers.remove(key);
  }

  // Clear all sensitive data
  void clearAllSensitiveData() {
    _sensitiveData.forEach((key, value) {
      if (value is Uint8List) {
        for (var i = 0; i < value.length; i++) {
          value[i] = 0;
        }
      }
    });
    _sensitiveData.clear();
    _cleanupTimers.forEach((_, timer) => timer.cancel());
    _cleanupTimers.clear();
  }

  // Overwrite sensitive string data
  void overwriteString(String data) {
    if (data.isEmpty) return;
    final bytes = data.codeUnits;
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }

  void dispose() {
    clearAllSensitiveData();
  }
} 
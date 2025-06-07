import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _storage;

  StorageService(this._storage);

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
} 
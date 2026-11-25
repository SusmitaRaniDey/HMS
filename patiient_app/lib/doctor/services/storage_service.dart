import 'package:get_storage/get_storage.dart';

import '../config/environment.dart';

class StorageService {
  final _storage = GetStorage();

  // Token Management
  Future<void> saveToken(String token) async {
    await _storage.write(Environment.TOKEN_KEY, token);
  }

  String? getToken() {
    return _storage.read(Environment.TOKEN_KEY);
  }

  Future<void> removeToken() async {
    await _storage.remove(Environment.TOKEN_KEY);
  }

  bool hasToken() {
    return _storage.hasData(Environment.TOKEN_KEY);
  }

  // Doctor Data Management
  Future<void> saveDoctor(Map<String, dynamic> doctor) async {
    await _storage.write(Environment.DOCTOR_KEY, doctor);
  }

  Map<String, dynamic>? getDoctor() {
    return _storage.read(Environment.DOCTOR_KEY);
  }

  Future<void> removeDoctor() async {
    await _storage.remove(Environment.DOCTOR_KEY);
  }

  // Generic Read/Write
  Future<void> write(String key, dynamic value) async {
    await _storage.write(key, value);
  }

  T? read<T>(String key) {
    return _storage.read<T>(key);
  }

  Future<void> remove(String key) async {
    await _storage.remove(key);
  }

  // Clear All Data
  Future<void> clearAll() async {
    await _storage.erase();
  }
}
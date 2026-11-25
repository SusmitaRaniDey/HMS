import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../config/environment.dart';

class StorageService extends GetxService {
  late GetStorage _box;

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // ========== TOKEN MANAGEMENT ==========

  Future<void> saveToken(String token) async {
    await _box.write(Environment.TOKEN_KEY, token);
  }

  String? getToken() {
    return _box.read(Environment.TOKEN_KEY);
  }

  Future<void> removeToken() async {
    await _box.remove(Environment.TOKEN_KEY);
  }

  bool hasToken() {
    return _box.hasData(Environment.TOKEN_KEY);
  }

  // ========== PATIENT DATA MANAGEMENT ==========

  Future<void> savePatient(Map<String, dynamic> patientData) async {
    await _box.write(Environment.PATIENT_KEY, patientData);
  }

  Map<String, dynamic>? getPatient() {
    return _box.read(Environment.PATIENT_KEY);
  }

  Future<void> removePatient() async {
    await _box.remove(Environment.PATIENT_KEY);
  }

  // ========== CLEAR ALL DATA (LOGOUT) ==========

  Future<void> clearAll() async {
    await _box.erase();
  }

  // ========== GENERIC METHODS ==========

  Future<void> write(String key, dynamic value) async {
    await _box.write(key, value);
  }

  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  Future<void> remove(String key) async {
    await _box.remove(key);
  }

  bool has(String key) {
    return _box.hasData(key);
  }
}
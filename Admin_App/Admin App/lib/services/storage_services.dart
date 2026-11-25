import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../config/environment.dart';
import '../models/admin_model.dart';

class StorageService extends GetxService {
  late GetStorage box;

  Future<StorageService> init() async {
    await GetStorage.init();
    box = GetStorage();
    return this;
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await box.write(Environment.TOKEN_KEY, token);
  }

  String? getToken() {
    return box.read(Environment.TOKEN_KEY);
  }

  Future<void> removeToken() async {
    await box.remove(Environment.TOKEN_KEY);
  }

  bool hasToken() {
    return box.hasData(Environment.TOKEN_KEY);
  }

  // Admin Data Management
  Future<void> saveAdmin(Map<String, dynamic> adminData) async {
    await box.write(Environment.ADMIN_KEY, adminData);
  }

  Map<String, dynamic>? getAdmin() {
    return box.read(Environment.ADMIN_KEY);
  }

  /// Typed accessor for the currently logged-in admin, used for
  /// client-side privilege checks (e.g. gating the Staff/super-admin UI).
  /// Returns null if no admin is stored or the stored data is malformed.
  AdminModel? getAdminModel() {
    final data = getAdmin();
    if (data == null) return null;
    try {
      return AdminModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeAdmin() async {
    await box.remove(Environment.ADMIN_KEY);
  }

  // Clear All Data (Logout)
  Future<void> clearAll() async {
    await box.erase();
  }

  // Generic Methods
  Future<void> write(String key, dynamic value) async {
    await box.write(key, value);
  }

  T? read<T>(String key) {
    return box.read<T>(key);
  }

  Future<void> remove(String key) async {
    await box.remove(key);
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _permissionsKey = 'permissions';
  static const _usernameKey = 'username';
  static const _roleKey = 'role';
  static const _browserSessionKey = 'browser_session_id';

  // TOKEN
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // USERNAME
  static Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // ROLE
  static Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  // PERMISSIONS
  static Future<void> savePermissions(String permissions) async {
    await _storage.write(key: _permissionsKey, value: permissions);
  }

  static Future<String?> getPermissions() async {
    return await _storage.read(key: _permissionsKey);
  }

  // BROWSER SESSION
  static Future<void> saveBrowserSessionId(String id) async {
    await _storage.write(key: _browserSessionKey, value: id);
  }

  static Future<String?> getBrowserSessionId() async {
    return await _storage.read(key: _browserSessionKey);
  }

  static Future<void> clearBrowserSessionId() async {
    await _storage.delete(key: _browserSessionKey);
  }

  // CLEAR ALL
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

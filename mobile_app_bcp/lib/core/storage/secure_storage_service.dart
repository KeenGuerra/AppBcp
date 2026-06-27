// secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_access_token';
  static const _roleKey = 'user_role';
  static const _nameKey = 'user_name';
  static const _docKey = 'user_document';

  static Future<void> saveSession({
    required String token,
    required String role,
    required String name,
    required String document,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _docKey, value: document);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  static Future<String?> getName() async {
    return await _storage.read(key: _nameKey);
  }

  static Future<String?> getDocument() async {
    return await _storage.read(key: _docKey);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _docKey);
  }
}

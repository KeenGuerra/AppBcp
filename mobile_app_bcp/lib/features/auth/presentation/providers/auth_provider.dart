// auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile_app_bcp/core/network/dio_client.dart';
import 'package:mobile_app_bcp/core/storage/secure_storage_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? token;
  final String? role;
  final String? name;
  final String? document;
  final bool isLocked;
  final int failedAttempts;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.token,
    this.role,
    this.name,
    this.document,
    this.isLocked = false,
    this.failedAttempts = 0,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? token,
    String? role,
    String? name,
    String? document,
    bool? isLocked,
    int? failedAttempts,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Nullable to reset error
      token: token ?? this.token,
      role: role ?? this.role,
      name: name ?? this.name,
      document: document ?? this.document,
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static AuthNotifier? instance;

  AuthNotifier() : super(AuthState()) {
    instance = this;
    _loadSession();
  }

  static const String _failedAttemptsPrefKey = 'login_failed_attempts';
  static const String _lockUntilPrefKey = 'login_lock_until';

  void clearSessionLocal() {
    state = AuthState();
  }

  Future<void> _loadSession() async {
    state = state.copyWith(isLoading: true);
    
    // Check local lock first
    final prefs = await SharedPreferences.getInstance();
    final failed = prefs.getInt(_failedAttemptsPrefKey) ?? 0;
    final lockUntilMs = prefs.getInt(_lockUntilPrefKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    bool locked = false;
    if (failed >= 5 && lockUntilMs > now) {
      locked = true;
    } else if (lockUntilMs <= now && lockUntilMs > 0) {
      // Lock expired, reset
      await prefs.setInt(_failedAttemptsPrefKey, 0);
      await prefs.setInt(_lockUntilPrefKey, 0);
    }

    // 8h inactivity check
    final lastActivity = prefs.getInt('last_activity_time') ?? 0;
    if (lastActivity > 0 && now - lastActivity > 8 * 60 * 60 * 1000) {
      await SecureStorageService.clearSession();
      await prefs.setInt('last_activity_time', 0);
      state = AuthState();
      return;
    }

    final token = await SecureStorageService.getToken();
    final role = await SecureStorageService.getRole();
    final name = await SecureStorageService.getName();
    final doc = await SecureStorageService.getDocument();

    state = AuthState(
      token: token,
      role: role,
      name: name,
      document: doc,
      isLocked: locked,
      failedAttempts: locked ? failed : 0,
    );
  }

  Future<bool> login({
    String? Dni,
    String? CodigoEmpleado,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // 1. Check local lock
    final prefs = await SharedPreferences.getInstance();
    final lockUntilMs = prefs.getInt(_lockUntilPrefKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (state.failedAttempts >= 5 && lockUntilMs > now) {
      final remainingMin = ((lockUntilMs - now) / 60000).ceil();
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login bloqueado. Intente de nuevo en $remainingMin minutos.',
        isLocked: true,
      );
      return false;
    }

    try {
      final response = await DioClient.instance.post('/auth/login', data: {
        'documento': Dni,
        'codigo_empleado': CodigoEmpleado,
        'password': password,
      });

      final data = response.data;
      final token = data['access_token'];
      final user = data['usuario'];
      final role = user['rol'];
      final name = user['nombre'];
      final doc = user['documento'];

      // Save session
      await SecureStorageService.saveSession(
        token: token,
        role: role,
        name: name,
        document: doc,
      );

      // Reset local locks & update activity time
      await prefs.setInt(_failedAttemptsPrefKey, 0);
      await prefs.setInt(_lockUntilPrefKey, 0);
      await prefs.setInt('last_activity_time', DateTime.now().millisecondsSinceEpoch);

      state = AuthState(
        token: token,
        role: role,
        name: name,
        document: doc,
        isLocked: false,
        failedAttempts: 0,
      );
      return true;
    } on DioException catch (e) {
      // Increment failed attempts
      int failed = (prefs.getInt(_failedAttemptsPrefKey) ?? 0) + 1;
      await prefs.setInt(_failedAttemptsPrefKey, failed);
      
      bool locked = false;
      if (failed >= 5) {
        locked = true;
        // Lock for 30 minutes
        final lockUntil = DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch;
        await prefs.setInt(_lockUntilPrefKey, lockUntil);
      }

      final msg = e.response?.data?['detail'] ?? 'Error de conexión con el servidor';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
        failedAttempts: failed,
        isLocked: locked,
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await DioClient.instance.post('/auth/logout');
    } catch (_) {}
    await SecureStorageService.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity_time', 0);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

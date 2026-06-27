// auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:mobile_app_bcp/core/storage/secure_storage_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app_bcp/features/auth/presentation/providers/auth_provider.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      
      // 8h Inactivity check
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt('last_activity_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (lastActivity > 0 && now - lastActivity > 8 * 60 * 60 * 1000) {
        await SecureStorageService.clearSession();
        await prefs.setInt('last_activity_time', 0);
        if (AuthNotifier.instance != null) {
          AuthNotifier.instance!.clearSessionLocal();
        }
        handler.reject(DioException(
          requestOptions: options,
          error: 'Sesión expirada por inactividad.',
          type: DioExceptionType.cancel,
        ));
        return;
      }
      
      // Update last activity time
      await prefs.setInt('last_activity_time', now);
    }
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      // Session expired or unauthorized
      await SecureStorageService.clearSession();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_activity_time', 0);
      if (AuthNotifier.instance != null) {
        AuthNotifier.instance!.clearSessionLocal();
      }
    }
    return super.onError(err, handler);
  }
}

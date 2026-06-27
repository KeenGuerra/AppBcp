// dio_client.dart
import 'package:dio/dio.dart';
import 'package:mobile_app_bcp/core/config/api_config.dart';
import 'package:mobile_app_bcp/core/network/auth_interceptor.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(AuthInterceptor());

  static Dio get instance => _dio;
}

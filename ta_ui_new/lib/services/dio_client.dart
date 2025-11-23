import 'package:dio/dio.dart';
import 'auth_service.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://b8a500371b41.ngrok-free.app',  // Backend URL
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Dio get instance {
    // Interceptor para agregar token JWT
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar token a todas las peticiones
          final token = await AuthService().getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('=== TOKEN ENVIADO ===');
            print(token.substring(0, 50) + '...');  // Solo los primeros 50 chars
            print('=====================');
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('[DIO ERROR] ${error.message}');
          return handler.next(error);
        },
      ),
    );
    return _dio;
  }
}
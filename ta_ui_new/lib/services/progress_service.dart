import 'package:dio/dio.dart';
import 'dio_client.dart';

class ProgressService {
  final Dio _dio = DioClient.instance;

  /// Obtiene las estadísticas de progreso emocional del usuario
  /// Incluye: conversaciones (positiva/negativa/neutra) y emociones faciales (FER)
  Future<Map<String, dynamic>> getProgressStatistics({
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/progress/statistics',
        queryParameters: {'user_id': userId},
      );

      if (response.data['success'] == true) {
        return response.data['statistics'] as Map<String, dynamic>;
      }
      throw response.data['error'] ?? 'Error al obtener estadísticas';
    } catch (e) {
      if (e is DioException) {
        // Si el endpoint no existe todavía, retornar datos vacíos
        if (e.response?.statusCode == 404) {
          return {
            'conversations': {
              'positiva': 0,
              'negativa': 0,
              'neutra': 0,
            },
            'facial_emotions': {
              'happy': 0,
              'sad': 0,
              'angry': 0,
              'fear': 0,
              'surprise': 0,
              'neutral': 0,
            },
          };
        }
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }

  /// Obtiene estadísticas de conversaciones (positiva/negativa/neutra)
  Future<Map<String, int>> getConversationStatistics({
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/progress/conversations',
        queryParameters: {'user_id': userId},
      );

      if (response.data['success'] == true) {
        final stats = response.data['statistics'] as Map<String, dynamic>;
        return stats.map((key, value) => MapEntry(key, value as int));
      }
      throw response.data['error'] ?? 'Error al obtener estadísticas';
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return {'positiva': 0, 'negativa': 0, 'neutra': 0};
      }
      rethrow;
    }
  }

  /// Obtiene estadísticas de emociones faciales (FER)
  Future<Map<String, int>> getFacialEmotionStatistics({
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/progress/facial-emotions',
        queryParameters: {'user_id': userId},
      );

      if (response.data['success'] == true) {
        final stats = response.data['statistics'] as Map<String, dynamic>;
        return stats.map((key, value) => MapEntry(key, value as int));
      }
      throw response.data['error'] ?? 'Error al obtener estadísticas';
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return {
          'happy': 0,
          'sad': 0,
          'angry': 0,
          'fear': 0,
          'surprise': 0,
          'neutral': 0,
        };
      }
      rethrow;
    }
  }
}

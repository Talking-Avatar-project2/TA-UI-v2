import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../models/chatbot_message.dart';

class ChatService {
  final Dio _dio = DioClient.instance;

  /// Envía un mensaje al chatbot y retorna la respuesta
  Future<String> sendMessage({
    required String message,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        '/chatbot/respond',
        data: {
          'message': message,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        return response.data['response'] ?? 'Sin respuesta';
      }
      throw 'Error del servidor: ${response.statusCode}';
    } catch (e) {
      if (e is DioException) {
        throw e.response?.data['error'] ?? 'Error de conexión con el servidor';
      }
      rethrow;
    }
  }

  /// Guarda un mensaje de voz (transcripción) en el historial
  Future<void> saveVoiceMessage({
    required String userId,
    required String userMessage,
    required String botResponse,
    int? audioDurationMs,
    double? transcriptionConfidence,
  }) async {
    try {
      final response = await _dio.post(
        '/chatbot/save-voice-message',
        data: {
          'user_id': userId,
          'user_message': userMessage,
          'bot_response': botResponse,
          if (audioDurationMs != null) 'audio_duration_ms': audioDurationMs,
          if (transcriptionConfidence != null)
            'transcription_confidence': transcriptionConfidence,
        },
      );

      if (response.data['success'] != true) {
        throw response.data['error'] ?? 'Error al guardar mensaje de voz';
      }
    } catch (e) {
      if (e is DioException) {
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }

  /// Obtiene el historial de mensajes del usuario
  Future<List<ChatbotMessage>> getChatHistory({
    required String userId,
    int limit = 50,
    String messageType = 'all', // 'text', 'voice', 'all'
  }) async {
    try {
      final response = await _dio.get(
        '/chatbot/history',
        queryParameters: {
          'user_id': userId,
          'limit': limit,
          'message_type': messageType,
        },
      );

      if (response.data['success'] == true) {
        final List messages = response.data['messages'] ?? [];
        return messages
            .map((json) => ChatbotMessage.fromJson(json))
            .toList()
            .reversed // Invertir para que los más antiguos estén primero
            .toList();
      }
      throw response.data['error'] ?? 'Error al obtener historial';
    } catch (e) {
      if (e is DioException) {
        // Si el endpoint no existe todavía (backend no implementado), retornar lista vacía
        if (e.response?.statusCode == 404) {
          return [];
        }
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }

  /// Elimina todo el historial de un usuario
  Future<void> deleteAllMessages(String userId) async {
    try {
      final response = await _dio.delete(
        '/chatbot/history/$userId',
      );

      if (response.data['success'] != true) {
        throw response.data['error'] ?? 'Error al eliminar historial';
      }
    } catch (e) {
      if (e is DioException) {
        // Si el endpoint no existe, ignorar error
        if (e.response?.statusCode == 404) {
          return;
        }
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }

  /// Obtiene estadísticas de emociones del usuario
  Future<Map<String, int>> getEmotionStatistics(String userId) async {
    try {
      final response = await _dio.get(
        '/chatbot/emotion-statistics',
        queryParameters: {'user_id': userId},
      );

      if (response.data['success'] == true) {
        final stats = response.data['statistics'] as Map<String, dynamic>;
        return stats.map((key, value) => MapEntry(key, value as int));
      }
      throw response.data['error'] ?? 'Error al obtener estadísticas';
    } catch (e) {
      if (e is DioException) {
        // Si el endpoint no existe, retornar mapa vacío
        if (e.response?.statusCode == 404) {
          return {};
        }
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }
}

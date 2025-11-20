import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/stt_response.dart';
import '../models/tts_response.dart';
import '../models/chatbot_message.dart';

/// Servicio para consumir la API de voz y emociones
class VoiceApiService {
  final String baseUrl;
  final Duration timeout;

  VoiceApiService({
    this.baseUrl = 'http://192.168.18.5:5002',  // Voice API via red local
    this.timeout = const Duration(seconds: 60),
  });

  /// Manejo centralizado de errores y timeouts
  Future<T> _handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await request().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Timeout de conexión (${timeout.inSeconds}s)');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          return parser(data);
        } else {
          throw Exception(data['error'] ?? 'Error desconocido del servidor');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException catch (e) {
      throw Exception('Tiempo de espera agotado: ${e.message}');
    } on FormatException {
      throw Exception('Respuesta inválida del servidor');
    } catch (e) {
      rethrow;
    }
  }

  /// Test de conexión con el servidor
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Speech-to-Text usando multipart/form-data
  Future<SttResponse> speechToText(File audioFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/stt'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SttResponse.fromJson(data);
      } else {
        throw Exception('Error STT: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Timeout en Speech-to-Text');
    } catch (e) {
      throw Exception('Error en STT: $e');
    }
  }

  /// Speech-to-Text usando base64
  Future<SttResponse> speechToTextBase64(
    Uint8List audioBytes,
    String format,
  ) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/api/stt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio': base64Encode(audioBytes),
          'format': format,
        }),
      ),
      (data) => SttResponse.fromJson(data),
    );
  }

  /// Text-to-Speech
  Future<TtsResponse> textToSpeech(
    String text, {
    String language = 'es',
    bool returnBase64 = true,
  }) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/api/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'language': language,
          'base64': returnBase64,
        }),
      ),
      (data) => TtsResponse.fromJson(data),
    );
  }

  /// Detección de emociones en imagen
  Future<Map<String, dynamic>> detectEmotions(Uint8List imageBytes) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/api/emotions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Encode(imageBytes),
        }),
      ),
      (data) => data,
    );
  }

  /// Endpoint de chatbot completo (audio → texto → respuesta → audio)
  Future<ChatbotResponse> chatbot(File audioFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/chatbot'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatbotResponse.fromJson(data);
      } else {
        throw Exception('Error Chatbot: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Timeout en Chatbot');
    } catch (e) {
      throw Exception('Error en Chatbot: $e');
    }
  }

  /// Flujo completo personalizado: STT → Generar respuesta → TTS
  Future<Map<String, dynamic>> completeVoiceFlow(
    File audioFile,
    Future<String> Function(String userText) generateResponse,
  ) async {
    try {
      // 1. Speech to Text
      final sttResponse = await speechToText(audioFile);

      if (!sttResponse.success) {
        throw Exception(sttResponse.error ?? 'Error en STT');
      }

      final userText = sttResponse.text;

      // 2. Generar respuesta (usando función personalizada)
      final botText = await generateResponse(userText);

      // 3. Text to Speech
      final ttsResponse = await textToSpeech(botText);

      if (!ttsResponse.success) {
        throw Exception(ttsResponse.error ?? 'Error en TTS');
      }

      return {
        'success': true,
        'userText': userText,
        'botText': botText,
        'audioData': ttsResponse.getAudioBytes(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

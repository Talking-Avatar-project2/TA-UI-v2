import 'dart:typed_data';
import 'dart:convert';

/// Modelo de mensaje del chatbot
class ChatbotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? audioData;

  ChatbotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.audioData,
  });

  /// Constructor para mensaje del usuario
  factory ChatbotMessage.user(String text, {Uint8List? audioData}) {
    return ChatbotMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      audioData: audioData,
    );
  }

  /// Constructor para mensaje del bot
  factory ChatbotMessage.bot(String text, {Uint8List? audioData}) {
    return ChatbotMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      audioData: audioData,
    );
  }

  /// Copia el mensaje con nuevos valores
  ChatbotMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    Uint8List? audioData,
  }) {
    return ChatbotMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      audioData: audioData ?? this.audioData,
    );
  }
}

/// Modelo de respuesta del endpoint chatbot completo
class ChatbotResponse {
  final bool success;
  final String? userText;
  final String? botText;
  final String? botAudioBase64;
  final String? audioFormat;
  final String? error;

  ChatbotResponse({
    required this.success,
    this.userText,
    this.botText,
    this.botAudioBase64,
    this.audioFormat,
    this.error,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      success: json['success'] ?? false,
      userText: json['user_text'],
      botText: json['bot_text'],
      botAudioBase64: json['bot_audio'],
      audioFormat: json['audio_format'],
      error: json['error'],
    );
  }

  /// Convierte el audio base64 a bytes
  Uint8List? getAudioBytes() {
    if (botAudioBase64 == null) return null;
    try {
      return base64Decode(botAudioBase64!);
    } catch (e) {
      return null;
    }
  }
}

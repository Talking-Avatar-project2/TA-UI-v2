import 'dart:typed_data';
import 'dart:convert';

/// Modelo de mensaje del chatbot
class ChatbotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? audioData;
  final String userId;
  final String messageType; // "text" o "voice"
  final String? emotionType; // "Positiva", "Negativa", "Neutra"

  ChatbotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.userId,
    this.audioData,
    this.messageType = "text",
    this.emotionType,
  });

  /// Constructor para mensaje del usuario
  factory ChatbotMessage.user(
    String text, {
    required String userId,
    Uint8List? audioData,
    String messageType = "text",
  }) {
    return ChatbotMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      userId: userId,
      audioData: audioData,
      messageType: messageType,
    );
  }

  /// Constructor para mensaje del bot
  factory ChatbotMessage.bot(
    String text, {
    required String userId,
    Uint8List? audioData,
    String messageType = "text",
    String? emotionType,
  }) {
    return ChatbotMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      userId: userId,
      audioData: audioData,
      messageType: messageType,
      emotionType: emotionType,
    );
  }

  /// Serializa a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_message': isUser ? text : null,
      'bot_response': !isUser ? text : null,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'message_type': messageType,
      'emotion_type': emotionType,
    };
  }

  /// Deserializa desde JSON del backend
  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    final isUser = json['is_user'] ?? false;
    final text = isUser
        ? (json['user_message'] ?? '')
        : (json['bot_response'] ?? '');

    return ChatbotMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      userId: json['user_id'] ?? 'unknown',
      messageType: json['message_type'] ?? 'text',
      emotionType: json['emotion_type'],
    );
  }

  /// Copia el mensaje con nuevos valores
  ChatbotMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    Uint8List? audioData,
    String? userId,
    String? messageType,
    String? emotionType,
  }) {
    return ChatbotMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      audioData: audioData ?? this.audioData,
      messageType: messageType ?? this.messageType,
      emotionType: emotionType ?? this.emotionType,
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

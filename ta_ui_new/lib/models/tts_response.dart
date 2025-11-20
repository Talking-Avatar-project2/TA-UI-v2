import 'dart:typed_data';
import 'dart:convert';

/// Modelo de respuesta para Text-to-Speech
class TtsResponse {
  final bool success;
  final String? audioBase64;
  final String? format;
  final String? error;

  TtsResponse({
    required this.success,
    this.audioBase64,
    this.format,
    this.error,
  });

  factory TtsResponse.fromJson(Map<String, dynamic> json) {
    return TtsResponse(
      success: json['success'] ?? false,
      audioBase64: json['audio'],
      format: json['format'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'audio': audioBase64,
      'format': format,
      'error': error,
    };
  }

  /// Convierte el audio base64 a bytes
  Uint8List? getAudioBytes() {
    if (audioBase64 == null) return null;
    try {
      return base64Decode(audioBase64!);
    } catch (e) {
      return null;
    }
  }
}

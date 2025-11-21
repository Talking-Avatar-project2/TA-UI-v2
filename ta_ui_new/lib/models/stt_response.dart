/// Modelo de respuesta para Speech-to-Text
class SttResponse {
  final bool success;
  final String text;
  final String? language;
  final double? duration;
  final double? confidence; // Confianza de la transcripción (0.0-1.0)
  final String? error;

  SttResponse({
    required this.success,
    required this.text,
    this.language,
    this.duration,
    this.confidence,
    this.error,
  });

  factory SttResponse.fromJson(Map<String, dynamic> json) {
    return SttResponse(
      success: json['success'] ?? false,
      text: json['text'] ?? '',
      language: json['language'],
      duration: json['duration']?.toDouble(),
      confidence: json['confidence']?.toDouble(),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'text': text,
      'language': language,
      'duration': duration,
      'confidence': confidence,
      'error': error,
    };
  }
}

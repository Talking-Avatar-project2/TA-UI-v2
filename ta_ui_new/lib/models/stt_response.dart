/// Modelo de respuesta para Speech-to-Text
class SttResponse {
  final bool success;
  final String text;
  final String? language;
  final double? duration;
  final String? error;

  SttResponse({
    required this.success,
    required this.text,
    this.language,
    this.duration,
    this.error,
  });

  factory SttResponse.fromJson(Map<String, dynamic> json) {
    return SttResponse(
      success: json['success'] ?? false,
      text: json['text'] ?? '',
      language: json['language'],
      duration: json['duration']?.toDouble(),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'text': text,
      'language': language,
      'duration': duration,
      'error': error,
    };
  }
}

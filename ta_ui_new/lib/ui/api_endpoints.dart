// lib/ui/api_endpoints.dart

class ApiEndpoints {
  // Cambia esta URL según dónde corra tu backend
  //   - Web en misma PC: "http://127.0.0.1:5000"
  //   - Emulador Android: "http://10.0.2.2:5000"
  //   - Dispositivo físico: IP de tu PC, ej: "http://192.168.1.36:5000"
  static const String baseUrl = 'http://192.168.1.36:5000';

  // Chatbot
  static const String chatbotRespond = '$baseUrl/chatbot/respond';

  // Avatar - LiveAvatar 4.0
  static const String avatarSessionToken = '$baseUrl/avatar/session/token';
  static const String avatarSessionStart = '$baseUrl/avatar/session/start';
  static const String avatarSessionStop  = '$baseUrl/avatar/session/stop';
  static const String avatarSendText     = '$baseUrl/avatar/send-text';

  // (Opcional) listar recursos si luego los usas desde el frontend
  static const String avatarListAvatars  = '$baseUrl/avatar/avatars';
  static const String avatarListVoices   = '$baseUrl/avatar/voices';
  static const String avatarListContexts = '$baseUrl/avatar/contexts';

  // Reconocimiento facial (rutas reales del backend)
  static const String facialRecognition       = '$baseUrl/recognition/recognize';
  static const String facialRecognitionStream = '$baseUrl/recognition/stream';
}

class ApiEndpoints {
  // Para emulador Android usa: http://10.0.2.2:5000
  // Para dispositivo físico usa: http://192.168.18.5:5000
  // Para iOS simulator usa: http://localhost:5000
  static const String baseUrl = "http://192.168.18.5:5000"; // IP de red local - backend corriendo en Windows
  //static const String baseUrl = "http://10.0.2.2:5000"; // Descomentar para emulador Android
  //static const String baseUrl = "http://172.17.242.140:5000"; // WSL IP - NO USAR (timeouts)

  // Endpoints del backend
  static const String chatbotRespond = "$baseUrl/chatbot/respond";
  static const String avatarExpress = "$baseUrl/avatar/express";
  static const String startAvatar = "$baseUrl/avatar/start-avatar"; // Nuevo endpoint
  static const String facialRecognition = "$baseUrl/facial_recognition/recognize";
  static const String facialRecognitionStream = "$baseUrl/facial_recognition/stream";
  static const String detectEmotionYolo = "$baseUrl/recognition/detect-emotion-yolo";
}

// lib/ui/api_endpoints.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../services/server_discovery_service.dart';

class ApiEndpoints {
  static String? _cachedBaseUrl;
  static bool _isDiscovering = false;

  /// Obtiene la URL base con auto-detección
  /// NOTA: Este getter es síncrono. Para la primera carga, usa initializeAsync()
  static String get baseUrl {
    // Si ya tenemos URL en cache, usarla
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    // Fallback a URL por defecto según plataforma
    String url;
    if (kIsWeb) {
      url = 'https://api.danassistantassistant.website/';
    } else if (Platform.isAndroid) {
      url = const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://10.0.2.2:5000',
      );
    } else if (Platform.isIOS) {
      url = const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:5000',
      );
    } else {
      url = const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:5000',
      );
    }

    if (kDebugMode) {
      print('🌐 [API] Usando URL por defecto: $url');
      print('💡 [API] Ejecuta initializeAsync() para auto-detección');
    }

    return url;
  }

  /// Inicializa la URL con auto-detección (llamar al inicio de la app)
  static Future<String> initializeAsync() async {
    if (_isDiscovering) {
      // Si ya está en proceso de discovery, esperar
      while (_isDiscovering) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedBaseUrl ?? baseUrl;
    }

    _isDiscovering = true;

    try {
      if (kDebugMode) {
        print('🚀 [API] Iniciando auto-detección de servidor...');
      }

      final discoveredUrl = await ServerDiscoveryService.discoverServer();

      if (discoveredUrl != null) {
        _cachedBaseUrl = discoveredUrl;
        if (kDebugMode) {
          print('✅ [API] Servidor auto-detectado: $discoveredUrl');
        }
        return discoveredUrl;
      } else {
        // No se encontró servidor, usar fallback
        _cachedBaseUrl = baseUrl;
        if (kDebugMode) {
          print('⚠️  [API] No se detectó servidor, usando fallback: $_cachedBaseUrl');
        }
        return _cachedBaseUrl!;
      }
    } finally {
      _isDiscovering = false;
    }
  }

  /// Configura manualmente la URL base
  static Future<void> setManualUrl(String url) async {
    await ServerDiscoveryService.setManualUrl(url);
    _cachedBaseUrl = url;
    if (kDebugMode) {
      print('💾 [API] URL manual configurada: $url');
    }
  }

  /// Limpia la configuración y fuerza re-detección
  static Future<void> resetConfiguration() async {
    await ServerDiscoveryService.clearSavedUrl();
    _cachedBaseUrl = null;
    if (kDebugMode) {
      print('🔄 [API] Configuración reseteada');
    }
  }

  // Voice API URL (puerto 5002)
  static String get voiceApiUrl {
    // Usar la misma IP pero con puerto 5002
    final base = baseUrl.replaceAll(':5000', ':5002');

    if (kDebugMode) {
      print('🎤 [Voice API] URL configurada: $base');
    }

    return base;
  }

  // ALTERNATIVA: IP configurable manualmente (descomenta si prefieres esta opción)
  // static const String baseUrl = 'http://192.168.18.5:5000';

  // Chatbot
  static String get chatbotRespond => '$baseUrl/chatbot/respond';

  // Avatar - LiveAvatar 4.0
  static String get avatarSessionToken => '$baseUrl/avatar/session/token';
  static String get avatarSessionStart => '$baseUrl/avatar/session/start';
  static String get avatarSessionStop => '$baseUrl/avatar/session/stop';
  static String get avatarSendText => '$baseUrl/avatar/send-text';

  // (Opcional) listar recursos si luego los usas desde el frontend
  static String get avatarListAvatars => '$baseUrl/avatar/avatars';
  static String get avatarListVoices => '$baseUrl/avatar/voices';
  static String get avatarListContexts => '$baseUrl/avatar/contexts';

  // Reconocimiento facial (rutas reales del backend)
  static String get facialRecognition => '$baseUrl/recognition/recognize';
  static String get facialRecognitionStream => '$baseUrl/recognition/stream';

  // Perfil de usuario
  static String get profileUploadPhoto => '$baseUrl/profile/upload-photo';
  static String get profileDeletePhoto => '$baseUrl/profile/delete-photo';
}

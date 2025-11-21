import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para descubrir y guardar la URL del servidor automáticamente
class ServerDiscoveryService {
  static const String _savedUrlKey = 'api_base_url';
  static const int _timeout = 2; // segundos

  /// Lista de URLs a probar en orden de prioridad
  static Future<List<String>> _getCandidateUrls() async {
    final List<String> candidates = [];

    if (kIsWeb) {
      // Web: Solo localhost
      candidates.addAll([
        'http://127.0.0.1:5000',
        'http://localhost:5000',
      ]);
    } else if (Platform.isAndroid) {
      // Android: Emulador primero, luego IPs comunes
      candidates.addAll([
        'http://10.0.2.2:5000', // Emulador
        'http://192.168.18.5:5000', // IP común 1
        'http://192.168.1.1:5000', // IP común 2
        'http://192.168.0.1:5000', // IP común 3
      ]);

      // Intentar obtener la IP del gateway (router)
      try {
        final interfaces = await NetworkInterface.list();
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              // Generar IPs probables basadas en el rango de red
              final parts = addr.address.split('.');
              if (parts.length == 4) {
                // Probar .1, .5, .10, .100 en el mismo segmento
                final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
                candidates.addAll([
                  '$subnet.5:5000',
                  '$subnet.1:5000',
                  '$subnet.10:5000',
                  '$subnet.100:5000',
                ]);
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️  [Discovery] No se pudo obtener interfaces de red: $e');
        }
      }
    } else {
      // iOS, Desktop: localhost
      candidates.addAll([
        'http://127.0.0.1:5000',
        'http://localhost:5000',
      ]);
    }

    // Eliminar duplicados manteniendo el orden
    return candidates.toSet().toList();
  }

  /// Verifica si una URL es accesible
  static Future<bool> _testUrl(String url) async {
    try {
      if (kDebugMode) {
        print('🔍 [Discovery] Probando: $url');
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: _timeout));

      final success = response.statusCode >= 200 && response.statusCode < 300;

      if (kDebugMode) {
        print(success
            ? '✅ [Discovery] Conectado: $url (${response.statusCode})'
            : '❌ [Discovery] Error: $url (${response.statusCode})');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Discovery] Fallo: $url - $e');
      }
      return false;
    }
  }

  /// Descubre automáticamente el servidor
  static Future<String?> discoverServer() async {
    if (kDebugMode) {
      print('🌐 [Discovery] Iniciando auto-detección de servidor...');
    }

    // 1. Intentar cargar URL guardada
    final savedUrl = await _getSavedUrl();
    if (savedUrl != null) {
      if (kDebugMode) {
        print('💾 [Discovery] Probando URL guardada: $savedUrl');
      }
      if (await _testUrl(savedUrl)) {
        if (kDebugMode) {
          print('✅ [Discovery] URL guardada funciona: $savedUrl');
        }
        return savedUrl;
      } else {
        if (kDebugMode) {
          print('⚠️  [Discovery] URL guardada no responde, buscando alternativas...');
        }
      }
    }

    // 2. Probar URLs candidatas
    final candidates = await _getCandidateUrls();
    if (kDebugMode) {
      print('🔍 [Discovery] Probando ${candidates.length} URLs candidatas...');
    }

    for (final url in candidates) {
      if (await _testUrl(url)) {
        // Guardar URL que funcionó
        await _saveUrl(url);
        if (kDebugMode) {
          print('✅ [Discovery] Servidor encontrado y guardado: $url');
        }
        return url;
      }
    }

    if (kDebugMode) {
      print('❌ [Discovery] No se encontró ningún servidor disponible');
    }
    return null;
  }

  /// Obtiene la URL guardada
  static Future<String?> _getSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_savedUrlKey);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  [Discovery] Error al cargar URL guardada: $e');
      }
      return null;
    }
  }

  /// Guarda la URL que funcionó
  static Future<void> _saveUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedUrlKey, url);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  [Discovery] Error al guardar URL: $e');
      }
    }
  }

  /// Permite configurar manualmente una URL
  static Future<void> setManualUrl(String url) async {
    await _saveUrl(url);
    if (kDebugMode) {
      print('💾 [Discovery] URL manual guardada: $url');
    }
  }

  /// Limpia la URL guardada (para forzar re-detección)
  static Future<void> clearSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedUrlKey);
      if (kDebugMode) {
        print('🗑️  [Discovery] URL guardada eliminada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  [Discovery] Error al eliminar URL: $e');
      }
    }
  }
}

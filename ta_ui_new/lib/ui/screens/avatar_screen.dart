import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_endpoints.dart';
import 'livekit_avatar_player_screen.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  _AvatarScreenState createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  static const String _userId = 'test-user';

  bool _isBusy = false;
  bool _sessionActive = false;

  String? _sessionId;
  String? _sessionToken;
  String? _livekitUrl;
  String? _livekitClientToken;

  String? _lastError;

  void _setBusy(bool value) {
    setState(() {
      _isBusy = value;
      _lastError = null;
    });
  }

  void _setError(String message) {
    setState(() {
      _lastError = message;
      _isBusy = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 1) Crear token de sesión
  Future<void> _createSessionToken() async {
    _setBusy(true);

    try {
      final body = jsonEncode({"user_id": _userId, "mode": "FULL"});

      final response = await http.post(
        Uri.parse(ApiEndpoints.avatarSessionToken),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 201) {
        _setError(
          "Error al crear token: HTTP ${response.statusCode} ${response.body}",
        );
        return;
      }

      final data = jsonDecode(response.body);
      final session = data['session'] ?? {};

      setState(() {
        _sessionId = session['session_id'];
        _sessionToken = session['session_token'];
      });

      _setBusy(false);
    } catch (e) {
      _setError("Error de conexión al crear token: $e");
    }
  }

  // 2) Start session (y luego abrir LiveKit)
  Future<void> _startSession() async {
    // si no hay token todavía, lo creamos
    if (_sessionToken == null) {
      await _createSessionToken();
      if (_sessionToken == null) {
        return;
      }
    }

    _setBusy(true);

    try {
      final body = jsonEncode({"user_id": _userId});

      final response = await http.post(
        Uri.parse(ApiEndpoints.avatarSessionStart),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        _setError(
          "Error al iniciar sesión: HTTP ${response.statusCode} ${response.body}",
        );
        return;
      }

      final data = jsonDecode(response.body);
      final session = data['session'] ?? {};
      final startResponse = session['start_response'] ?? {};
      final rawData = startResponse['data'] ?? {};

      setState(() {
        _sessionActive = true;
        _livekitUrl = rawData['livekit_url'];
        _livekitClientToken = rawData['livekit_client_token'];
      });

      _setBusy(false);

      // Si tenemos URL y token => abrimos la pantalla LiveKit
      if (_livekitUrl != null && _livekitClientToken != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveKitAvatarPlayerScreen(
              livekitUrl: _livekitUrl!,
              token: _livekitClientToken!,
            ),
          ),
        );
      } else {
        _setError("La API no devolvió livekit_url o livekit_client_token.");
      }
    } catch (e) {
      _setError("Error de conexión al iniciar sesión: $e");
    }
  }

  // 3) Stop session (backend + limpiar estado)
  Future<void> _stopSession() async {
    if (!_sessionActive) {
      _setError("No hay sesión activa para detener.");
      return;
    }

    _setBusy(true);

    try {
      final body = jsonEncode({"user_id": _userId});

      final response = await http.post(
        Uri.parse(ApiEndpoints.avatarSessionStop),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        _setError(
          "Error al detener sesión: HTTP ${response.statusCode} ${response.body}",
        );
        return;
      }

      setState(() {
        _sessionActive = false;
        _sessionId = null;
        _sessionToken = null;
        _livekitUrl = null;
        _livekitClientToken = null;
      });

      _setBusy(false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sesión detenida correctamente.")),
      );
    } catch (e) {
      _setError("Error de conexión al detener sesión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionText = _sessionActive
        ? "Sesión ACTIVA\nsession_id: $_sessionId"
        : "Sesión inactiva\nCrea e inicia una sesión para obtener LiveKit.";

    return Scaffold(
      appBar: AppBar(title: const Text("Avatar Interactivo (LiveAvatar)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text(
                  _sessionActive ? "Sesión ACTIVA" : "Sesión inactiva",
                ),
                subtitle: Text(sessionText),
                trailing: _isBusy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isBusy ? null : _startSession,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Iniciar conversación"),
                ),
                ElevatedButton.icon(
                  onPressed: _isBusy ? null : _stopSession,
                  icon: const Icon(Icons.stop),
                  label: const Text("Terminar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_livekitUrl != null && _livekitClientToken != null) ...[
              const Text(
                "LiveKit listo (para integrar video/voz):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("livekit_url:\n$_livekitUrl"),
              const SizedBox(height: 8),
              Text(
                "livekit_client_token:\n$_livekitClientToken",
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),

            if (_lastError != null)
              Text(_lastError!, style: const TextStyle(color: Colors.red)),

            const Spacer(),

            const Text(
              "En esta versión free el avatar piensa por su cuenta (contexto remoto). "
              "En tu tesis, el texto vendrá de chatbot_management y se mandará como avatar.speak_text.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

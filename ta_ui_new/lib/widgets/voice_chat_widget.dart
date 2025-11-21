import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/chatbot_message.dart';
import '../services/voice_api_service.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import '../ui/api_endpoints.dart';
import 'recording_button.dart';
import 'message_bubble.dart';

/// Widget principal de chat por voz
class VoiceChatWidget extends StatefulWidget {
  final String apiUrl;

  const VoiceChatWidget({
    super.key,
    this.apiUrl = 'http://192.168.18.5:5000',
  });

  @override
  State<VoiceChatWidget> createState() => _VoiceChatWidgetState();
}

class _VoiceChatWidgetState extends State<VoiceChatWidget> {
  // Servicios
  late final VoiceApiService _apiService;
  final ChatService _chatService = ChatService();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  // Estado
  RecordingState _recordingState = RecordingState.idle;
  final List<ChatbotMessage> _messages = [];
  String? _currentRecordingPath;
  String _statusMessage = 'Listo para hablar';
  String? _userId;

  // UI
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiService = VoiceApiService(baseUrl: widget.apiUrl);
    _initializeWidget();
  }

  /// Inicializar widget y obtener userId
  Future<void> _initializeWidget() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.firebaseUser?.uid;
    await _checkServerConnection();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Verificar conexión con el servidor
  Future<void> _checkServerConnection() async {
    final isConnected = await _apiService.checkHealth();
    if (!mounted) return;

    setState(() {
      _statusMessage = isConnected
          ? 'Conectado al servidor'
          : 'Servidor no disponible. Verifica la conexión.';
    });

    if (!isConnected) {
      _showError('No se pudo conectar al servidor en ${widget.apiUrl}');
    }
  }

  /// Solicitar permisos de micrófono
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      _showError(
        'Se necesita permiso de micrófono. '
        'Por favor, habilítalo en la configuración.',
      );
      return false;
    }

    return status.isGranted;
  }

  /// Iniciar grabación
  Future<void> _startRecording() async {
    // Verificar permisos
    if (!await _requestMicrophonePermission()) return;

    try {
      // Verificar si el grabador tiene permisos
      if (!await _recorder.hasPermission()) {
        _showError('No hay permisos de grabación');
        return;
      }

      // Crear ruta temporal para el archivo
      final tempDir = Directory.systemTemp;
      _currentRecordingPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Iniciar grabación
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );

      setState(() {
        _recordingState = RecordingState.recording;
        _statusMessage = 'Grabando... Suelta para enviar';
      });
    } catch (e) {
      _showError('Error al iniciar grabación: $e');
    }
  }

  /// Detener grabación y procesar
  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();

      if (path == null || _currentRecordingPath == null) {
        setState(() => _recordingState = RecordingState.idle);
        return;
      }

      setState(() {
        _recordingState = RecordingState.processing;
        _statusMessage = 'Procesando tu mensaje...';
      });

      // Procesar el audio
      await _processAudio(File(_currentRecordingPath!));
    } catch (e) {
      _showError('Error al detener grabación: $e');
      setState(() => _recordingState = RecordingState.idle);
    }
  }

  /// Procesar audio grabado
  Future<void> _processAudio(File audioFile) async {
    try {
      // 1. Speech to Text
      setState(() => _statusMessage = 'Transcribiendo audio...');
      final sttResponse = await _apiService.speechToText(audioFile);

      if (!sttResponse.success) {
        throw Exception(sttResponse.error ?? 'Error en transcripción');
      }

      final userText = sttResponse.text;

      // Añadir mensaje del usuario
      if (_userId != null) {
        setState(() {
          _messages.add(ChatbotMessage.user(
            userText,
            userId: _userId!,
            messageType: 'voice',
          ));
          _statusMessage = 'Generando respuesta...';
        });
      }
      _scrollToBottom();

      // 2. Generar respuesta (aquí puedes integrar tu lógica personalizada)
      final botText = await _generateBotResponse(userText);

      // Extraer emoción del bot response
      String? emotion;
      String cleanBotText = botText;
      final emotionMatch = RegExp(r'^\(([^)]+)\)\s*').firstMatch(botText);
      if (emotionMatch != null) {
        emotion = emotionMatch.group(1);
        cleanBotText = botText.substring(emotionMatch.end);
      }

      // 3. Text to Speech
      setState(() => _statusMessage = 'Convirtiendo respuesta a audio...');
      final ttsResponse = await _apiService.textToSpeech(cleanBotText);

      if (!ttsResponse.success) {
        throw Exception(ttsResponse.error ?? 'Error en síntesis de voz');
      }

      final audioData = ttsResponse.getAudioBytes();

      // Añadir mensaje del bot
      if (_userId != null) {
        setState(() {
          _messages.add(ChatbotMessage.bot(
            cleanBotText,
            userId: _userId!,
            audioData: audioData,
            messageType: 'voice',
            emotionType: emotion,
          ));
          _recordingState = RecordingState.playing;
          _statusMessage = 'Reproduciendo respuesta...';
        });
      }
      _scrollToBottom();

      // 4. Guardar en el backend (transcripción + respuesta)
      if (_userId != null) {
        try {
          await _chatService.saveVoiceMessage(
            userId: _userId!,
            userMessage: userText,
            botResponse: botText, // Con etiqueta de emoción
            audioDurationMs: null, // TODO: calcular duración si es necesario
            transcriptionConfidence: sttResponse.confidence,
          );
        } catch (e) {
          // No mostrar error al usuario, solo log
          print('Error al guardar mensaje de voz: $e');
        }
      }

      // 5. Reproducir audio automáticamente
      if (audioData != null) {
        await _player.play(BytesSource(audioData));

        // Esperar a que termine la reproducción
        _player.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _recordingState = RecordingState.idle;
              _statusMessage = 'Listo para hablar';
            });
          }
        });
      } else {
        setState(() {
          _recordingState = RecordingState.idle;
          _statusMessage = 'Listo para hablar';
        });
      }
    } catch (e) {
      String errorMsg = 'Error desconocido';
      if (e.toString().contains('Timeout')) {
        errorMsg = 'Tiempo de espera agotado. El servidor tardó demasiado en responder. Intenta con un audio más corto o verifica tu conexión.';
      } else if (e.toString().contains('SocketException')) {
        errorMsg = 'No se pudo conectar al servidor. Verifica que el servidor esté corriendo en WSL.';
      } else {
        errorMsg = 'Error al procesar: $e';
      }

      _showError(errorMsg);
      setState(() {
        _recordingState = RecordingState.idle;
        _statusMessage = 'Error. Intenta de nuevo.';
      });
    } finally {
      // Limpiar archivo temporal
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }
  }

  /// Generar respuesta del bot usando la misma API que el modo texto
  Future<String> _generateBotResponse(String userText) async {
    try {
      if (_userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.chatbotRespond),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userText,
          'user_id': _userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No recibí respuesta del servidor.';
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      // En caso de error, devolver un mensaje de error amigable
      return 'Lo siento, no pude procesar tu mensaje. Error: $e';
    }
  }

  /// Scroll al final de la lista
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Mostrar error al usuario
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Estado del sistema
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: _recordingState == RecordingState.idle
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista de mensajes
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Presiona el botón para comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: _messages[index]);
                  },
                ),
        ),

        // Botón de grabación
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: RecordingButton(
            state: _recordingState,
            onStartRecording: _startRecording,
            onStopRecording: _stopRecording,
          ),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_endpoints.dart';
import '../../widgets/voice_chat_widget.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _messages = <Map<String, String>>[];
  bool _isVoiceMode = false; // Modo de chat: false = texto, true = voz

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      String userMessage = _messageController.text.trim();

      // Añade el mensaje del usuario a la lista
      setState(() {
        _messages.add({"type": "user", "text": userMessage});
      });

      _messageController.clear();

      try {
        final response = await http.post(
          Uri.parse(ApiEndpoints.chatbotRespond),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': userMessage}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _messages.add({"type": "bot", "text": data['response']});
          });
        } else {
          setState(() {
            _messages.add({"type": "error", "text": "Error: El chatbot no pudo responder."});
          });
        }
      } catch (e) {
        setState(() {
          _messages.add({"type": "error", "text": "Error de conexión: $e"});
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
    });
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message['type'] == 'user';
    bool isError = message['type'] == 'error';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isError
              ? Colors.red.shade100
              : (isUser ? Colors.blue.shade100 : Colors.grey.shade300),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
          ),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(
            color: isError ? Colors.red.shade900 : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTextChatMode() {
    return Column(
      children: [
        // Encabezado con avatar y bienvenida
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade300,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bienvenido, Usuario",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "¡Hola!\nTu compañero emocional inteligente está aquí.\nPuedes contarme lo que sientes.\nEstoy listo para ofrecerte apoyo y respuestas personalizadas.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      softWrap: true,
                    ),
                  ],
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
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Escribe un mensaje para comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(_messages[index]);
                  },
                ),
        ),

        // Campo de entrada de texto
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Escribe un mensaje...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(_isVoiceMode ? "Chat por Voz" : "Chatbot"),
        actions: [
          // Botón para alternar entre modo texto y voz
          IconButton(
            icon: Icon(_isVoiceMode ? Icons.keyboard : Icons.mic),
            tooltip: _isVoiceMode ? 'Cambiar a texto' : 'Cambiar a voz',
            onPressed: _toggleMode,
          ),
        ],
      ),
      body: _isVoiceMode
          ? VoiceChatWidget(
              apiUrl: 'http://192.168.18.5:5002',  // Voice API via red local
            )
          : _buildTextChatMode(),
    );
  }
}

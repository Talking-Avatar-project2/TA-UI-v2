import 'package:flutter/material.dart';
import '../widgets/voice_chat_widget.dart';

/// Pantalla principal de chat por voz
class VoiceChatScreen extends StatelessWidget {
  final String apiUrl;

  const VoiceChatScreen({
    super.key,
    this.apiUrl = 'http://192.168.18.5:5000',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat por Voz'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Información',
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: VoiceChatWidget(apiUrl: apiUrl),
      ),
    );
  }

  /// Mostrar diálogo de información
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.blue),
            SizedBox(width: 8),
            Text('Cómo usar'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Presiona y mantén el botón del micrófono',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '2. Habla con claridad',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '3. Suelta el botón para enviar tu mensaje',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '4. Espera la respuesta del asistente',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                'Características:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Transcripción automática de voz'),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Síntesis de voz natural'),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Historial de conversación'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

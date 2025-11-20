import 'package:flutter/material.dart';
import '../screens/voice_chat_screen.dart';

/// Ejemplo de cómo integrar el chat por voz en tu aplicación
class VoiceChatExample extends StatelessWidget {
  const VoiceChatExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo de Chat por Voz'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Método 1: Navegar a la pantalla completa
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/voice-chat');
              },
              icon: const Icon(Icons.mic),
              label: const Text('Abrir Chat por Voz (Ruta)'),
            ),

            const SizedBox(height: 16),

            // Método 2: Navegar con URL personalizada
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VoiceChatScreen(
                      apiUrl: 'http://192.168.18.5:5000',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.mic_external_on),
              label: const Text('Abrir Chat por Voz (URL Custom)'),
            ),

            const SizedBox(height: 32),

            // Información
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Instrucciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Asegúrate de que el servidor esté corriendo en WSL',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '2. Verifica la IP con: ip addr show eth0',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '3. Mantén presionado el botón para grabar',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '4. Suelta para enviar y recibir respuesta',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

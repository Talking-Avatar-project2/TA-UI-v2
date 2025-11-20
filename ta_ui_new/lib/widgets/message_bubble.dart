import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/chatbot_message.dart';

/// Burbuja de mensaje en el chat
class MessageBubble extends StatefulWidget {
  final ChatbotMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (widget.message.audioData == null) return;

    try {
      setState(() => _isPlaying = true);

      await _audioPlayer.play(
        BytesSource(widget.message.audioData!),
      );

      // Esperar a que termine la reproducción
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final hasAudio = widget.message.audioData != null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con ícono
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy,
                  size: 16,
                  color: isUser ? Colors.blue[700] : Colors.grey[700],
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'Tú' : 'Asistente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.blue[700] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Texto del mensaje
            Text(
              widget.message.text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),

            // Botón de reproducir audio (solo para mensajes del bot)
            if (!isUser && hasAudio) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: _isPlaying ? null : _playAudio,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying ? Icons.volume_up : Icons.play_arrow,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPlaying ? 'Reproduciendo...' : 'Reproducir audio',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Timestamp
            const SizedBox(height: 4),
            Text(
              _formatTime(widget.message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chatbot_message.dart';
import '../../services/chat_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/voice_chat_widget.dart';
import '../api_endpoints.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<ChatbotMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isVoiceMode = false;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isLoadingHistory = true;

  String? _userId;

  // Colores de la marca
  final Color _primaryColor = const Color(0xFF6A11CB);
  final Color _secondaryColor = const Color(0xFF2575FC);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.firebaseUser?.uid;

    if (_userId == null) {
      setState(() => _isLoadingHistory = false);
      _showError('No hay usuario autenticado');
      return;
    }

    await _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null) return;
    setState(() => _isLoadingHistory = true);

    try {
      final history = await _chatService.getChatHistory(
        userId: _userId!,
        limit: 100,
        messageType: 'text',
      );

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(history);
          _isLoadingHistory = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        // print('No se pudo cargar historial: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _userId == null) return;
    if (_isSending) return;

    String userMessage = _messageController.text.trim();
    _messageController.clear();

    final userChatMessage = ChatbotMessage.user(
      userMessage,
      userId: _userId!,
      messageType: 'text',
    );

    setState(() {
      _messages.add(userChatMessage);
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final botResponse = await _chatService.sendMessage(
        message: userMessage,
        userId: _userId!,
      );

      String? emotion;
      String cleanResponse = botResponse;

      final emotionMatch = RegExp(r'^\(([^)]+)\)\s*').firstMatch(botResponse);
      if (emotionMatch != null) {
        emotion = emotionMatch.group(1);
        cleanResponse = botResponse.substring(emotionMatch.end);
      }

      final botChatMessage = ChatbotMessage.bot(
        cleanResponse,
        userId: _userId!,
        messageType: 'text',
        emotionType: emotion,
      );

      if (mounted) {
        setState(() {
          _messages.add(botChatMessage);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatbotMessage.bot(
            'Lo siento, ocurrió un error de conexión.',
            userId: _userId!,
            messageType: 'text',
          ));
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _clearHistory() async {
    // Diálogo estilizado
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Limpiar historial'),
        content: const Text('¿Quieres borrar toda la conversación? No podrás recuperarla.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Borrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && _userId != null) {
      try {
        setState(() => _isLoading = true);
        await _chatService.deleteAllMessages(_userId!);

        if (mounted) {
          setState(() {
            _messages.clear();
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Chat limpiado'),
              backgroundColor: _primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Error al eliminar historial');
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
    });
  }

  // ===========================================================================
  // WIDGETS DE UI MEJORADOS
  // ===========================================================================

  /// Construye una burbuja de chat moderna con gradientes y sombras
  Widget _buildMessage(ChatbotMessage message) {
    final isUser = message.isUser;
    
    // Bordes redondeados con "colita" en el lado correspondiente
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          // Si es usuario, usa el gradiente. Si es bot, usa blanco.
          gradient: isUser
              ? LinearGradient(colors: [_primaryColor, _secondaryColor])
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF2D3436),
                fontSize: 16,
                height: 1.4, // Mejor legibilidad
              ),
            ),
            // Emociones o badge de voz
            if (message.emotionType != null && !isUser) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getEmotionEmoji(message.emotionType!),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            if (message.messageType == 'voice') ...[
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 14, color: isUser ? Colors.white70 : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Audio',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'positiva': return 'Te percibo: 😊 Positivo';
      case 'negativa': return 'Te percibo: 😔 Negativo';
      case 'neutra': return 'Te percibo: 😐 Neutro';
      default: return '😐';
    }
  }

  /// Modo Texto mejorado con Input Flotante
  Widget _buildTextChatMode() {
    return Column(
      children: [
        // Lista de mensajes
        Expanded(
          child: Container(
            color: _backgroundColor, // Fondo limpio
            child: _isLoadingHistory
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessage(_messages[index]),
                      ),
          ),
        ),

        // Indicador de escribiendo
        if (_isSending)
          Container(
            color: _backgroundColor,
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                 SizedBox(
                  width: 15, height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                ),
                const SizedBox(width: 8),
                Text(
                  'Analizando respuesta...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

        // Input Flotante Moderno
        Container(
          color: _backgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), // Padding inferior para iPhone X+
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Cuéntame, ¿qué piensas?",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón Enviar con Gradiente
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isSending 
                      ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                      : LinearGradient(colors: [_primaryColor, _secondaryColor]),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Estado vacío amigable
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 50, color: _primaryColor),
          ),
          const SizedBox(height: 20),
          const Text(
            "¡Hola!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
          ),
          const SizedBox(height: 10),
          Text(
            "Soy tu compañero virtual.\nEstoy aquí para escucharte.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      // AppBar Minimalista y Limpio
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de estado (puntito verde)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              _isVoiceMode ? "Modo Voz" : "Chatbot",
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isVoiceMode ? Icons.keyboard_alt_outlined : Icons.mic_none_rounded,
              color: _primaryColor,
            ),
            tooltip: _isVoiceMode ? 'Escribir' : 'Hablar',
            onPressed: _toggleMode,
          ),
          if (!_isVoiceMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
              onPressed: _clearHistory,
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: _isVoiceMode
          ? VoiceChatWidget(apiUrl: ApiEndpoints.voiceApiUrl)
          : _buildTextChatMode(),
    );
  }
}
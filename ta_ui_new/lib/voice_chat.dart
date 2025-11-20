// Biblioteca de Chat por Voz
//
// Esta biblioteca proporciona una integración completa de chat por voz
// con servicios de Speech-to-Text (STT) y Text-to-Speech (TTS).
//
// Ejemplo de uso:
// import 'package:ta_ui_new/voice_chat.dart';
//
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => const VoiceChatScreen(),
//   ),
// );

// Screens
export 'screens/voice_chat_screen.dart';

// Widgets
export 'widgets/voice_chat_widget.dart';
export 'widgets/recording_button.dart';
export 'widgets/message_bubble.dart';

// Services
export 'services/voice_api_service.dart';

// Models
export 'models/stt_response.dart';
export 'models/tts_response.dart';
export 'models/chatbot_message.dart';

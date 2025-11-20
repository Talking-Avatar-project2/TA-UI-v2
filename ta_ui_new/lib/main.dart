import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/camera_permission_screen.dart';
import 'ui/screens/chatbot_screen.dart';
import 'ui/screens/avatar_screen.dart';
import 'ui/screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frontend MVP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define la pantalla inicial
      home: const HomeScreen(),
      // Define las rutas
      routes: {
        '/chatbot': (context) => const ChatbotScreen(),
        '/camera': (context) => const CameraPermissionScreen(),
        '/avatar': (context) => const AvatarScreen(),
        '/recommendations': (context) => const PlaceholderScreen("Recomendaciones"),
        '/progress': (context) => const PlaceholderScreen("Progreso"),
        '/evaluation': (context) => const PlaceholderScreen("Evaluación"),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// PlaceholderScreen para pantallas en desarrollo
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text("Pantalla en desarrollo: $title"),
      ),
    );
  }
}

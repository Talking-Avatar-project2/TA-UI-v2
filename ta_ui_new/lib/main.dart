import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:ta_ui_new/ui/screens/progress_screen.dart';
import 'package:ta_ui_new/ui/screens/home_screen.dart';
import 'package:ta_ui_new/ui/screens/camera_permission_screen.dart';
import 'package:ta_ui_new/ui/screens/chatbot_screen.dart';
import 'package:ta_ui_new/ui/screens/avatar_screen.dart';
import 'package:ta_ui_new/ui/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const HomeScreen(),
      routes: {
        '/chatbot': (context) => const ChatbotScreen(),
        '/camera': (context) => const CameraPermissionScreen(),
        '/avatar': (context) => const AvatarScreen(),
        '/recommendations': (context) =>
        const PlaceholderScreen("Recomendaciones"),
        '/progress': (context) => const ProgressScreen(),
        '/evaluation': (context) =>
        const PlaceholderScreen("Evaluación"),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

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

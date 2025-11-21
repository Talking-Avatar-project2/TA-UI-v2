import 'package:flutter/material.dart';
import 'package:ta_ui_new/ui/screens/forgot_password_screen.dart';
import 'package:ta_ui_new/ui/screens/login_screen.dart';
import 'package:ta_ui_new/ui/screens/register_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/camera_permission_screen.dart';
import 'ui/screens/chatbot_screen.dart';
import 'ui/screens/avatar_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/progress_screen.dart';
import 'ui/api_endpoints.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-detectar servidor al inicio
  await ApiEndpoints.initializeAsync();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frontend MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define la pantalla inicial
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isAuthenticated) {
            return HomeScreen();
          }
          return LoginScreen();
        },
      ),
      // Define las rutas
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
        '/settings': (context) => const SettingsScreen(),
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/forgot-password': (_) => ForgotPasswordScreen(),
        '/home': (_) => HomeScreen(),
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

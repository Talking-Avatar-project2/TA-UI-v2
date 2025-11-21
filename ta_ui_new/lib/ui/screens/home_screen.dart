import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Carga la URL de la foto de perfil
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('profile_image_url');
    if (savedUrl != null && mounted) {
      setState(() {
        _profileImageUrl = savedUrl;
      });
    }
    else{
      setState(() {
        _profileImageUrl = null;
      });
    }
  }

  /// Recarga la foto cuando se vuelve a esta pantalla
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar la foto cada vez que se regresa a esta pantalla
    _loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // Sin sombra
        backgroundColor: Colors.transparent, // Fondo transparente
        title: const Text(""),
      ),
      body: Column(
        children: [
          // Encabezado con el avatar del usuario
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.blue.shade400],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Foto de perfil dinámica
                GestureDetector(
                  onTap: () async {
                    // Navegar a perfil y recargar al volver
                    await Navigator.pushNamed(context, '/profile');
                    _loadProfileImage(); // Recargar después de volver
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _getProfileImage(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Usuario",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Espacio para las opciones en cuadrícula
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildGridOption(
                      context,
                      "Chatbot",
                      Icons.chat,
                      Colors.blue,
                      "/chatbot",
                    ),
                    _buildGridOption(
                      context,
                      "Avatar",
                      Icons.face,
                      Colors.green,
                      "/camera",
                    ),
                    _buildGridOption(
                      context,
                      "Recomendaciones",
                      Icons.favorite,
                      Colors.red,
                      "/recommendations",
                    ),
                    _buildGridOption(
                      context,
                      "Progreso",
                      Icons.bar_chart,
                      Colors.orange,
                      "/progress",
                    ),
                    _buildGridOption(
                      context,
                      "Evaluación",
                      Icons.assignment,
                      Colors.purple,
                      "/evaluation",
                    ),
                    _buildGridOption(
                      context,
                      "Perfil",
                      Icons.person,
                      Colors.teal,
                      "/profile",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene la imagen de perfil a mostrar
  ImageProvider _getProfileImage() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }else{
      return const AssetImage('assets/images/profile_placeholder.png');
    }
  }

  Widget _buildGridOption(
      BuildContext context, String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, route);
        // Recargar foto si vuelve de perfil
        if (route == '/profile') {
          _loadProfileImage();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                ),
                SizedBox(height: 10),
                Text(
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
            child: SafeArea( // Asegura que no se corte en dispositivos con notch o barra de navegación
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

  Widget _buildGridOption(
      BuildContext context, String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
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

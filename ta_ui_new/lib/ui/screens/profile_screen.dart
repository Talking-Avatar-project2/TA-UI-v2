import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil de Usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Nombres:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            TextButton(onPressed: () {}, child: const Text("Agregar Nombres")),
            const Divider(),
            const Text("Correo Electrónico:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            TextButton(onPressed: () {}, child: const Text("Agregar Correo")),
            const Divider(),
            const Text("Contraseña:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            TextButton(
                onPressed: () {}, child: const Text("Cambiar Contraseña")),
          ],
        ),
      ),
    );
  }
}

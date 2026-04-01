// lib/ui/screens/camera_permission_screen.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionScreen extends StatelessWidget {
  const CameraPermissionScreen({Key? key}) : super(key: key);

  Future<void> _requestPermissions(BuildContext context) async {
    final camStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (camStatus.isGranted && micStatus.isGranted) {
      // Si ambos permisos son otorgados, redirige a la pantalla del avatar
      Navigator.pushReplacementNamed(context, '/avatar');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "La app necesita acceso a cámara y micrófono para usar el avatar.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activación de Cámara")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _requestPermissions(context),
          child: const Text("ACTIVAR CÁMARA Y MICRÓFONO"),
        ),
      ),
    );
  }
}

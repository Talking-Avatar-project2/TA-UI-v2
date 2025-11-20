import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionScreen extends StatelessWidget {
  const CameraPermissionScreen({super.key});

  Future<void> _requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Si el permiso es otorgado, redirige a la pantalla del avatar
      Navigator.pushReplacementNamed(context, '/avatar');
    } else {
      // Si el permiso es denegado, muestra un mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El permiso de cámara es necesario para usar el avatar."),
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
          onPressed: () => _requestCameraPermission(context),
          child: const Text("ACTIVAR CÁMARA"),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_endpoints.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _profileImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Carga la URL de la foto de perfil guardada
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('profile_image_url');
    if (savedUrl != null && mounted) {
      setState(() {
        _profileImageUrl = savedUrl;
      });
    }
  }

  /// Guarda la URL de la foto de perfil
  Future<void> _saveProfileImageUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_url', url);
  }

  /// Muestra opciones para seleccionar imagen
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir de Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar Foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Selecciona imagen de cámara o galería
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,  // Reducido de 800 a 512
        maxHeight: 512, // Reducido de 800 a 512
        imageQuality: 70, // Reducido de 85 a 70 (más compresión)
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        // Subir automáticamente
        await _uploadImage();
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  /// Sube la imagen al backend
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    if (!mounted) return; // Verificar si aún está montado

    setState(() {
      _isUploading = true;
    });

    try {
      // Crear multipart request
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/profile/upload-photo');
      final request = http.MultipartRequest('POST', uri);

      // Agregar headers
      request.headers['Content-Type'] = 'multipart/form-data';

      // Agregar la imagen
      if (kIsWeb) {
        // Para web, usar bytes
        final bytes = await _selectedImage!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: 'profile.jpg',
        ));
      } else {
        // Para móvil/desktop, usar path
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          _selectedImage!.path,
        ));
      }

      // Opcional: Agregar user_id (por ahora usuario por defecto)
      request.fields['user_id'] = 'default_user';

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['photo_url'] != null) {
          // Guardar URL de la foto
          final photoUrl = data['photo_url'];
          await _saveProfileImageUrl(photoUrl);

          if (mounted) {
            setState(() {
              _profileImageUrl = photoUrl;
              _selectedImage = null;
            });
          }

          _showSuccess('Foto de perfil actualizada');
        } else {
          throw Exception(data['error'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error al subir imagen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Elimina la foto de perfil
  Future<void> _removeProfileImage() async {
    try {
      // Llamar al backend para eliminar
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/profile/delete-photo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': 'default_user'}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('profile_image_url');

        if (mounted) {
          setState(() {
            _profileImageUrl = null;
            _selectedImage = null;
          });
        }
        _showSuccess('Foto de perfil eliminada');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error al eliminar imagen: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return; // No mostrar si el widget está desmontado

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return; // No mostrar si el widget está desmontado

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil de Usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto de perfil
            Center(
              child: Stack(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _getProfileImage(),
                      child: _isUploading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : null,
                    ),
                  ),
                  // Botón de editar
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _isUploading ? null : _showImageSourceDialog,
                        tooltip: 'Cambiar foto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Texto de ayuda
            Center(
              child: Text(
                'Toca la foto para cambiarla',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Resto de información del perfil
            const Text("Nombres:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () {},
              child: const Text("Agregar Nombres"),
            ),
            const Divider(),

            const Text("Correo Electrónico:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () {},
              child: const Text("Agregar Correo"),
            ),
            const Divider(),

            const Text("Contraseña:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () {},
              child: const Text("Cambiar Contraseña"),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtiene la imagen de perfil a mostrar
  ImageProvider _getProfileImage() {
    // 1. Si hay imagen seleccionada (preview local)
    if (_selectedImage != null && !kIsWeb) {
      return FileImage(File(_selectedImage!.path));
    }
    // 2. Si hay URL guardada (de Firebase)
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    // 3. Imagen por defecto
    return const AssetImage('assets/images/profile_placeholder.png');
  }
}

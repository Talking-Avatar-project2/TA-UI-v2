import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  XFile? _selectedImage;
  UserModel? _userProfile;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Carga el perfil del usuario desde Firestore
  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final profile = await _userService.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      print('Error al cargar perfil: $e');
      _showError('Error al cargar perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              if (_userProfile?.photoUrl != null)
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
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
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

  /// Sube la imagen al backend usando UserService
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Convertir XFile a File (solo para mobile)
      final File imageFile = File(_selectedImage!.path);

      // Subir foto usando el servicio (esto también actualiza Firestore)
      final photoUrl = await _userService.uploadProfilePhoto(
        imageFile,
        user.uid,
      );

      // Recargar perfil para obtener datos actualizados
      await _loadUserProfile();

      if (mounted) {
        setState(() {
          _selectedImage = null;
        });
        _showSuccess('Foto de perfil actualizada');
      }
    } catch (e) {
      print('Error al subir imagen: $e');
      _showError('Error al subir imagen: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Elimina la foto de perfil
  Future<void> _removeProfileImage() async {
    try {
      // Actualizar perfil sin foto
      await _userService.updateProfile(photoUrl: '');

      // Recargar perfil
      await _loadUserProfile();

      if (mounted) {
        setState(() {
          _selectedImage = null;
        });
        _showSuccess('Foto de perfil eliminada');
      }
    } catch (e) {
      _showError('Error al eliminar imagen: $e');
    }
  }

  /// Muestra diálogo para editar nombre
  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _userProfile?.fullName ?? '');

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Nombre'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              hintText: 'Ingresa tu nombre',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateName(controller.text);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Actualiza el nombre del usuario
  Future<void> _updateName(String newName) async {
    if (newName.trim().isEmpty) {
      _showError('El nombre no puede estar vacío');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _userService.updateProfile(fullName: newName);
      await _loadUserProfile();
      _showSuccess('Nombre actualizado');
    } catch (e) {
      _showError('Error al actualizar nombre: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Muestra diálogo para editar fecha de nacimiento
  Future<void> _showEditBirthDateDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _userProfile?.birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Selecciona tu fecha de nacimiento',
    );

    if (picked != null) {
      await _updateBirthDate(picked);
    }
  }

  /// Actualiza la fecha de nacimiento
  Future<void> _updateBirthDate(DateTime newDate) async {
    setState(() => _isLoading = true);

    try {
      await _userService.updateProfile(birthDate: newDate);
      await _loadUserProfile();
      _showSuccess('Fecha de nacimiento actualizada');
    } catch (e) {
      _showError('Error al actualizar fecha: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Cerrar sesión
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

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
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    )
                                  : _userProfile?.photoUrl == ''
                                      ? const Icon(Icons.person, size: 60)
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

                    // Información del perfil
                    _buildProfileCard(
                      icon: Icons.person,
                      title: 'Nombre Completo',
                      value: _userProfile?.fullName ?? 'Sin nombre',
                      onTap: _showEditNameDialog,
                    ),

                    const SizedBox(height: 12),

                    _buildProfileCard(
                      icon: Icons.email,
                      title: 'Correo Electrónico',
                      value: _userProfile?.email ?? 'Sin email',
                      onTap: null, // Email no se puede cambiar
                    ),

                    const SizedBox(height: 12),

                    _buildProfileCard(
                      icon: Icons.cake,
                      title: 'Fecha de Nacimiento',
                      value: _userProfile?.birthDate != null
                          ? _formatDate(_userProfile!.birthDate!)
                          : 'Sin fecha',
                      onTap: _showEditBirthDateDialog,
                    ),

                    const SizedBox(height: 12),

                    _buildProfileCard(
                      icon: Icons.calendar_today,
                      title: 'Miembro desde',
                      value: _userProfile?.createdAt != null
                          ? _formatDate(_userProfile!.createdAt!)
                          : 'N/A',
                      onTap: null,
                    ),

                    const SizedBox(height: 32),

                    // Botón de cerrar sesión
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar Sesión'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Construye una tarjeta de información del perfil
  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: onTap != null
            ? Icon(Icons.edit, color: Colors.grey[600])
            : null,
        onTap: onTap,
      ),
    );
  }

  /// Obtiene la imagen de perfil a mostrar
  ImageProvider? _getProfileImage() {
    // 1. Si hay imagen seleccionada (preview local)
    if (_selectedImage != null && !kIsWeb) {
      return FileImage(File(_selectedImage!.path));
    }
    // 2. Si hay URL guardada (de Firebase)
    if (_userProfile?.photoUrl != null && _userProfile!.photoUrl!.isNotEmpty) {
      return NetworkImage(_userProfile!.photoUrl!);
    }
    // 3. Sin imagen
    return null;
  }

  /// Formatea una fecha
  String _formatDate(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
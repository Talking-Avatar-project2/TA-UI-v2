import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class UserService {
  final Dio _dio = DioClient.instance;

  // CP020: Crear perfil en Firestore
  Future<UserModel> createProfile({
    required String fullName,
    required DateTime birthDate,
    String? photoUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/create-profile',
        data: {
          'full_name': fullName,
          'birth_date': _formatDate(birthDate),
          if (photoUrl != null) 'photo_url': photoUrl,
        },
      );

      if (response.data['success']) {
        return UserModel.fromJson(response.data['user']);
      }
      throw response.data['error'] ?? 'Error al crear perfil';
    } catch (e) {
      if (e is DioException) {
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }

  // Obtener perfil del usuario
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile');

      if (response.data['success']) {
        return UserModel.fromJson(response.data['user']);
      }
      throw response.data['error'] ?? 'Error al obtener perfil';
    } catch (e) {
      if (e is DioException) {
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }

  // CP023: Actualizar perfil
  Future<UserModel> updateProfile({
    String? fullName,
    DateTime? birthDate,
    String? photoUrl,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/profile',
        data: {
          if (fullName != null) 'full_name': fullName,
          if (birthDate != null) 'birth_date': _formatDate(birthDate),
          if (photoUrl != null) 'photo_url': photoUrl,
        },
      );

      if (response.data['success']) {
        return UserModel.fromJson(response.data['user']);
      }
      throw response.data['error'] ?? 'Error al actualizar perfil';
    } catch (e) {
      if (e is DioException) {
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }

  // CP022: Subir foto de perfil
  Future<String> uploadProfilePhoto(File imageFile, String userId) async {
    try {
      // Comprimir imagen
      final compressedImage = await _compressImage(imageFile);

      // Crear FormData
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          compressedImage.path,
          filename: 'profile_$userId.jpg',
        ),
        'user_id': userId,
      });

      final response = await _dio.post(
        '/profile/upload-photo',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.data['success']) {
        return response.data['photo_url'];
      }
      throw response.data['error'] ?? 'Error al subir foto';
    } catch (e) {
      if (e is DioException) {
        throw e.response?.data['error'] ?? 'Error de conexión';
      }
      rethrow;
    }
  }

  // Helper: Comprimir imagen
  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw 'No se pudo procesar la imagen';

    // Redimensionar a máximo 800x800
    final resized = img.copyResize(
      image,
      width: image.width > 800 ? 800 : image.width,
      height: image.height > 800 ? 800 : image.height,
    );

    // Comprimir como JPEG
    final compressed = img.encodeJpg(resized, quality: 85);

    // Guardar archivo comprimido
    final compressedFile = File('${file.path}_compressed.jpg');
    await compressedFile.writeAsBytes(compressed);

    return compressedFile;
  }

  // Helper: Formatear fecha
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
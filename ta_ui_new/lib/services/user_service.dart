import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dio_client.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

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
  Future<String> uploadProfilePhoto(XFile imageFile, String userId) async {
    try {
      String filename = 'profile_$userId.jpg';
      MultipartFile multipartFile;
      if (kIsWeb) {
        // Para web, leer bytes directamente
        Uint8List bytes = await imageFile.readAsBytes();
        Uint8List compressedBytes = _compressBytes(bytes);
        multipartFile = MultipartFile.fromBytes(
          compressedBytes,
          filename: filename,
        );
      } else {
        // Para celular, usar el sistema de archivos
        File fileMobile = File(imageFile.path);
        File compressed = await _compressFileMobile(fileMobile);
        multipartFile = await MultipartFile.fromFile(
          compressed.path,
          filename: filename,
        );
      }

      // Crear FormData
      final formData = FormData.fromMap({
        'photo': multipartFile,
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

  Uint8List _compressBytes(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    if (image.width > 800 || image.height > 800) {
      final resized = img.copyResize(
        image,
        width: image.width > 800 ? 800 : image.width,
        height: image.height > 800 ? 800 : image.height,
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }

  Future<File> _compressFileMobile(File file) async {
    final bytes = await file.readAsBytes();
    final compressedBytes = _compressBytes(bytes); // Reutilizamos la lógica de arriba
    final newPath = '${file.path}_compressed.jpg';
    final compressedFile = File(newPath);
    await compressedFile.writeAsBytes(compressedBytes);
    
    return compressedFile;
  }

  // Helper: Formatear fecha
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
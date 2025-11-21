import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _firebaseUser;
  UserModel? _userProfile;
  bool _isLoading = false;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user != null) {
      // Usuario logueado, obtener perfil de Firestore
      try {
        _userProfile = await _userService.getProfile();
      } catch (e) {
        print('Error al obtener perfil: $e');
      }
    } else {
      // Usuario deslogueado
      _userProfile = null;
    }

    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_firebaseUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      _userProfile = await _userService.getProfile();
    } catch (e) {
      print('Error al refrescar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}
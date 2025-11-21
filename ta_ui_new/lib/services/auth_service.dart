import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Obtener token JWT
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(true);
  }

  // CP020: Registro con email/password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // CP021: Email duplicado
      if (e.code == 'email-already-in-use') {
        throw 'Este correo ya está registrado';
      } else if (e.code == 'weak-password') {
        throw 'La contraseña es muy débil';
      } else if (e.code == 'invalid-email') {
        throw 'Correo inválido';
      }
      throw e.message ?? 'Error al registrarse';
    }
  }

  // CP015/CP016: Login
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw 'Credenciales incorrectas';
      } else if (e.code == 'invalid-email') {
        throw 'Correo inválido';
      } else if (e.code == 'user-disabled') {
        throw 'Usuario deshabilitado';
      }
      throw e.message ?? 'Error al iniciar sesión';
    }
  }

  // CP018: Recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No existe una cuenta con este correo');
        case 'invalid-email':
          throw Exception('Correo electrónico inválido');
        default:
          throw Exception('Error al enviar email: ${e.message}');
      }
    }
  }

  // CP019: Confirmar nueva contraseña
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'expired-action-code') {
        throw 'El código ha expirado';
      } else if (e.code == 'invalid-action-code') {
        throw 'Código inválido';
      } else if (e.code == 'weak-password') {
        throw 'La contraseña es muy débil';
      }
      throw e.message ?? 'Error al cambiar contraseña';
    }
  }

  // CP017: Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
import 'dart:math';
import 'package:corpmove_app/core/utils/user_role.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Simula registro con email/password
  Future<Map<String, dynamic>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simular creación de usuario
    final role = _getRoleFromEmail(email);
    return {
      'id': 'usr_${Random().nextInt(999999)}',
      'name': name,
      'email': email,
      'role': role,
    };
  }

  /// Simula inicio de sesión con email/password
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    // Validación simulada
    if (password.length < 6) {
      throw Exception('Contraseña incorrecta');
    }
    final role = _getRoleFromEmail(email);
    return {
      'id': 'usr_${email.hashCode}',
      'name': email.split('@').first,
      'email': email,
      'role': role,
    };
  }

  /// Simula autenticación con Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 2));
    // Simular datos de Google
    const email = 'usuario@gmail.com';
    final role = _getRoleFromEmail(email);
    return {
      'id': 'google_${Random().nextInt(999999)}',
      'name': 'Usuario Google',
      'email': email,
      'photoURL': 'https://i.pravatar.cc/150?img=7',
      'role': role,
    };
  }

  /// Simula restablecimiento de contraseña
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulación exitosa
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  UserRole _getRoleFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('owner') || lower.contains('ceo')) {
      return UserRole.owner;
    } else if (lower.contains('admin') || lower.contains('empresa')) {
      return UserRole.admin;
    } else if (lower.contains('driver') || lower.contains('conductor')) {
      return UserRole.driver;
    } else if (lower.contains('corp') || lower.contains('empleado')) {
      return UserRole.employee;
    } else {
      return UserRole.normal;
    }
  }
}
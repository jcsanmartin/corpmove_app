import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:corpmove_app/core/services/supabase_service.dart';
import 'package:corpmove_app/core/utils/user_role.dart';
import 'package:corpmove_app/features/admin/data/admin_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _saveUserToFirestore(user);
        // Sincronizar con Supabase
        await AdminRepository().upsertUser(
          firebaseUid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
      }
      return user;
    } catch (e) {
      throw Exception('Error en Google Sign-In: $e');
    }
  }

  Future<User?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await _saveUserToFirestore(user, name: name);
        // Sincronizar con Supabase
        await AdminRepository().upsertUser(
          firebaseUid: user.uid,
          email: email,
          displayName: name,
        );
      }
      return user;
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        // Sincronizar con Supabase en cada login
        await AdminRepository().upsertUser(
          firebaseUid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
      }
      return user;
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Error al desconectar Google: $e');
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> _saveUserToFirestore(User user, {String? name}) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();
    if (!doc.exists) {
      final role = _getRoleFromEmail(user.email ?? '');
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': name ?? user.displayName ?? user.email?.split('@').first,
        'photoURL': user.photoURL,
        'role': role.name,
        'estado_solicitud': 'ninguno',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Lee el rol del usuario desde Supabase (fuente de verdad única para roles).
  Future<UserRole> getUserRole(String uid) async {
    try {
      final profile = await AdminRepository().getUserProfile(uid);
      final roleStr = profile?['role'] as String? ?? 'normal';
      debugPrint('═══ ROL desde Supabase: $roleStr ═══');
      return _roleFromString(roleStr);
    } catch (e) {
      debugPrint('[AuthService] Error leyendo rol de Supabase: $e');
      return UserRole.normal;
    }
  }

  Future<UserRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return UserRole.normal;
    return getUserRole(user.uid);
  }

  Future<DocumentSnapshot> getCurrentUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');
    return await _firestore.collection('users').doc(user.uid).get();
  }

  Future<void> solicitarCambioRol({
    required UserRole rolSolicitado,
    required Map<String, dynamic> datosAdicionales,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');

    // 1. Actualizar en Firestore (Compatibilidad temporal)
    await _firestore.collection('users').doc(user.uid).update({
      'rol_solicitado': rolSolicitado.name,
      'estado_solicitud': 'pendiente',
      'fecha_solicitud': FieldValue.serverTimestamp(),
      ...datosAdicionales,
    });

    // 2. Actualizar en Supabase (Fuente de verdad para el nuevo Panel Admin)
    final repo = AdminRepository();
    await repo.syncUserProfile(
      firebaseUid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );

    // Actualizar campos específicos de la solicitud en Supabase.
    // Solo incluimos columnas que existen en la tabla 'users' del schema.
    // Nota: 'company_name' NO existe en Supabase (solo company_id como FK).
    final supabaseFields = <String, dynamic>{
      'rol_solicitado': rolSolicitado.name,
      'estado_solicitud': 'pendiente',
    };

    // Mapear solo los campos válidos del schema de Supabase
    const camposValidos = {
      'company_id', 'full_name', 'phone', 'position', 'photo_url', 'notas',
    };
    for (final entry in datosAdicionales.entries) {
      if (camposValidos.contains(entry.key)) {
        supabaseFields[entry.key] = entry.value;
      }
    }

    await SupabaseService.client
        .from('users')
        .update(supabaseFields)
        .eq('firebase_uid', user.uid);
  }

  Future<void> cancelarSolicitud() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');

    // Firestore: limpiar todos los campos de la solicitud
    await _firestore.collection('users').doc(user.uid).update({
      'estado_solicitud': 'ninguno',
      'rol_solicitado': FieldValue.delete(),
      'fecha_solicitud': FieldValue.delete(),
      'motivo_rechazo': FieldValue.delete(),
      'company_id': FieldValue.delete(),
      'company_name': FieldValue.delete(),
      'full_name': FieldValue.delete(),
      'phone': FieldValue.delete(),
      'position': FieldValue.delete(),
      'photo_url': FieldValue.delete(),
      'notas': FieldValue.delete(),
    });

    // Supabase: limpiar campos de la solicitud
    await SupabaseService.client.from('users').update({
      'estado_solicitud': 'ninguno',
      'rol_solicitado': null,
      'company_id': null,
      'full_name': null,
      'phone': null,
      'position': null,
      'notas': null,
    }).eq('firebase_uid', user.uid);
  }

  Stream<QuerySnapshot> getSolicitudesPendientes() {
    return _firestore
        .collection('users')
        .where('estado_solicitud', isEqualTo: 'pendiente')
        .snapshots();
  }

  Future<void> aprobarSolicitud(String uid, UserRole nuevoRol) async {
    await _firestore.collection('users').doc(uid).update({
      'role': nuevoRol.name,
      'estado_solicitud': 'aprobado',
      'rol_solicitado': FieldValue.delete(),
    });
  }

  Future<void> rechazarSolicitud(String uid, {String? motivo}) async {
    await _firestore.collection('users').doc(uid).update({
      'estado_solicitud': 'rechazado',
      'motivo_rechazo': motivo ?? 'No especificado',
    });
  }

  UserRole getRoleFromEmail(String email) => _getRoleFromEmail(email);

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

  UserRole _roleFromString(String role) {
    switch (role) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'driver':
        return UserRole.driver;
      case 'employee':
        return UserRole.employee;
      case 'normal':
        return UserRole.normal;
      case _:
        // Valor desconocido: tratar como usuario normal
        return UserRole.normal;
    }
  }
}

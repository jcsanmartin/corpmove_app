import 'dart:typed_data';
import 'package:corpmove_app/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  final SupabaseClient _db = SupabaseService.client;

  // ─────────────────────────────────────────────
  // EMPRESA
  // ─────────────────────────────────────────────

  /// Stream de todas las empresas (para que el usuario elija una).
  Stream<List<Map<String, dynamic>>> streamAllCompanies() {
    return _db
        .from('companies')
        .stream(primaryKey: ['id'])
        .order('company_name', ascending: true);
  }

  /// Stream en tiempo real de la configuración de la empresa.
  Stream<Map<String, dynamic>?> streamCompanyConfig(String companyId) {
    return _db
        .from('companies')
        .stream(primaryKey: ['id'])
        .eq('id', companyId)
        .map((rows) {
          if (rows.isEmpty) {
            debugPrint('[Supabase] No se encontró la empresa $companyId');
            return null;
          }
          return rows.first;
        });
  }

  /// Stream en tiempo real de los empleados de una empresa.
  Stream<List<Map<String, dynamic>>> streamCompanyEmployees(String companyId) {
    return _db
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('company_id', companyId)
        .map((rows) => rows);
  }

  /// Obtener el company_id del usuario actual (por firebase_uid).
  Future<String?> getUserCompanyId(String firebaseUid) async {
    try {
      final response = await _db
          .from('users')
          .select('company_id')
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();
      return response?['company_id'] as String?;
    } catch (e) {
      debugPrint('[Supabase] Error al obtener company_id: $e');
      return null;
    }
  }

  /// Actualizar cualquier campo de la tabla companies.
  Future<void> updateConfig(String companyId, String field, dynamic value) async {
    try {
      await _db
          .from('companies')
          .update({field: value})
          .eq('id', companyId);

      // El límite se lee directamente de la tabla companies en el cliente,
      // no es necesario (ni posible) propagarlo a la tabla users porque no tiene esa columna.
    } catch (e) {
      debugPrint('[Supabase] Error al actualizar $field: $e');
      throw Exception('Error al actualizar $field: $e');
    }
  }

  /// Crear una nueva empresa y asignarla al usuario administrador.
  Future<String> createCompany(String companyName, String firebaseUid) async {
    try {
      // 1. Crear la empresa
      final result = await _db
          .from('companies')
          .insert({
            'company_name': companyName,
            'corporate_limit': 0,
            'daily_trips_limit': 2,
            'allowed_schedules': ['06:00 - 22:00'],
          })
          .select('id')
          .single();

      final companyId = result['id'] as String;

      // 2. Upsert del usuario: si no existe en Supabase lo crea, si ya existe lo actualiza
      await _db.from('users').upsert({
        'firebase_uid': firebaseUid,
        'company_id': companyId,
        'role': 'admin',
        'estado_solicitud': 'ninguno',
      }, onConflict: 'firebase_uid');

      debugPrint('[Supabase] Empresa creada: $companyId y usuario vinculado.');
      return companyId;
    } catch (e) {
      debugPrint('[Supabase] Error al crear empresa: $e');
      throw Exception('Error al crear empresa: $e');
    }
  }

  // ─────────────────────────────────────────────
  // EMPLEADOS
  // ─────────────────────────────────────────────

  /// Cambiar estado activo/inactivo de un empleado.
  Future<void> updateEmployeeStatus(String userId, bool isActive) async {
    try {
      await _db
          .from('users')
          .update({'is_active': isActive})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  /// Agregar empleado manualmente (pre-aprobado por el admin).
  Future<void> addEmployee(String companyId, String name, String email) async {
    try {
      await _db.from('users').insert({
        'name': name,
        'email': email,
        'company_id': companyId,
        'is_active': true,
        'estado_solicitud': 'aprobado',
        'role': 'employee',
      });
    } catch (e) {
      throw Exception('Error al agregar empleado: $e');
    }
  }

  /// Editar nombre y correo de un empleado.
  Future<void> updateEmployeeInfo(String userId, String name, String email) async {
    try {
      await _db
          .from('users')
          .update({'name': name, 'email': email})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error al editar empleado: $e');
    }
  }

  /// Eliminar (desvincular) a un empleado.
  Future<void> deleteEmployee(String userId) async {
    try {
      await _db.from('users').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Error al eliminar empleado: $e');
    }
  }

  /// Aprobar solicitud de afiliación corporativa.
  Future<void> approveRequest(String userId) async {
    try {
      // Al aprobar, el company_id ya está guardado desde la solicitud.
      // Solo actualizamos el estado y el rol.
      await _db.from('users').update({
        'role': 'employee',
        'estado_solicitud': 'aprobado',
        'is_active': true,
        'rol_solicitado': null,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error al aprobar solicitud: $e');
    }
  }

  /// Rechazar solicitud de afiliación corporativa.
  Future<void> rejectRequest(String userId) async {
    try {
      // NO limpiamos company_id para mantener el historial en la lista.
      // Solo cambiamos el estado para que la UI lo refleje.
      await _db.from('users').update({
        'estado_solicitud': 'rechazado',
        'is_active': false,
        'rol_solicitado': null,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error al rechazar solicitud: $e');
    }
  }

  // ─────────────────────────────────────────────
  // USUARIO (sincronización Firebase UID → Supabase)
  // ─────────────────────────────────────────────

  /// Sincroniza el perfil del usuario con Supabase de forma segura:
  /// - Si el usuario NO existe: lo crea con rol 'normal'.
  /// - Si el usuario YA existe: solo actualiza email, foto y nombre.
  ///   El rol NUNCA se sobreescribe en logins posteriores.
  Future<void> syncUserProfile({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      // 1. Verificar si ya existe en Supabase
      final existing = await _db
          .from('users')
          .select('id, role')
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();

      if (existing == null) {
        // 2a. Usuario nuevo: crear con rol 'normal' por defecto
        debugPrint('[Supabase] Creando nuevo usuario: $email');
        await _db.from('users').insert({
          'firebase_uid': firebaseUid,
          'email': email,
          'display_name': displayName,
          'photo_url': photoUrl,
          'role': 'normal',
          'estado_solicitud': 'ninguno',
        });
      } else {
        // 2b. Usuario existente: actualizar solo campos de perfil (SIN tocar el rol)
        debugPrint('[Supabase] Actualizando perfil (rol preservado: ${existing['role']}): $email');
        await _db.from('users').update({
          'email': email,
          'display_name': displayName,
          'photo_url': photoUrl,
        }).eq('firebase_uid', firebaseUid);
      }
    } catch (e) {
      debugPrint('[Supabase] Error al sincronizar usuario: $e');
    }
  }

  /// @deprecated Usar syncUserProfile en su lugar.
  Future<void> upsertUser({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
    String role = 'normal',
  }) => syncUserProfile(
        firebaseUid: firebaseUid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

  /// Escuchar cambios en el perfil del usuario en tiempo real.
  Stream<Map<String, dynamic>?> streamUserProfile(String firebaseUid) {
    return _db
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('firebase_uid', firebaseUid)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Obtener el perfil completo del usuario por firebase_uid.
  Future<Map<String, dynamic>?> getUserProfile(String firebaseUid) async {
    try {
      return await _db
          .from('users')
          .select()
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();
    } catch (e) {
      debugPrint('[Supabase] Error al obtener perfil: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // STORAGE — Subida de imágenes
  // ─────────────────────────────────────────────

  /// Subir foto de perfil al bucket 'avatars' de Supabase Storage.
  /// Retorna la URL pública del archivo.
  Future<String?> uploadProfilePhoto(String userId, Uint8List bytes, {String extension = 'jpg'}) async {
    try {
      final path = 'avatars/$userId.$extension';
      await _db.storage
          .from('profile-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$extension', upsert: true),
          );
      final url = _db.storage.from('profile-photos').getPublicUrl(path);
      debugPrint('[Supabase Storage] Imagen subida: $url');
      return url;
    } catch (e) {
      debugPrint('[Supabase Storage] Error subiendo imagen: $e');
      return null;
    }
  }
}

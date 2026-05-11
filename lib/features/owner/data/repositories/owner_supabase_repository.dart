import 'package:corpmove_app/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerSupabaseRepository {
  final SupabaseClient _db = SupabaseService.client;

  // ─────────────────────────────────────────────
  // ESTADÍSTICAS DASHBOARD
  // ─────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    try {
      final companiesCount = await _db.from('companies').select('id').count(CountOption.exact);
      final usersCount = await _db.from('users').select('id').count(CountOption.exact);
      final driversCount = await _db.from('users').select('id').eq('role', 'driver').count(CountOption.exact);
      
      return {
        'companies': companiesCount.count,
        'users': usersCount.count,
        'drivers': driversCount.count,
      };
    } catch (e) {
      debugPrint('[Owner Repo] Error obteniendo estadísticas: $e');
      return {'companies': 0, 'users': 0, 'drivers': 0};
    }
  }

  // ─────────────────────────────────────────────
  // EMPRESAS (CONVENIOS)
  // ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamCompanies() {
    return _db.from('companies').stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  Future<void> createCompany(Map<String, dynamic> data) async {
    try {
      await _db.from('companies').insert({
        'company_name': data['name'],
        'corporate_limit': data['corporate_limit'] ?? 0,
        'daily_trips_limit': data['daily_trips_limit'] ?? 2,
        'allowed_schedules': ['06:00 - 22:00'],
      });
    } catch (e) {
      throw Exception('Error al crear empresa: $e');
    }
  }

  Future<void> updateCompany(String id, Map<String, dynamic> data) async {
    try {
      await _db.from('companies').update({
        'company_name': data['name'],
        'corporate_limit': data['corporate_limit'],
        'daily_trips_limit': data['daily_trips_limit']
      }).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar empresa: $e');
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      // Set users company_id to null before deleting
      await _db.from('users').update({'company_id': null}).eq('company_id', id);
      await _db.from('companies').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar empresa: $e');
    }
  }

  // ─────────────────────────────────────────────
  // USUARIOS Y CONDUCTORES
  // ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    // Left join para obtener el nombre de la empresa
    return _db.from('users')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);
  }

  Future<Map<String, String>> getCompanyNamesMap() async {
    try {
      final companies = await _db.from('companies').select('id, company_name');
      return {for (var c in companies) c['id'] as String: c['company_name'] as String};
    } catch (e) {
      return {};
    }
  }

  Future<void> approveDriverRequest(String userId) async {
    try {
      await _db.from('users').update({
        'role': 'driver',
        'estado_solicitud': 'aprobado',
        'rol_solicitado': null,
        'is_active': true,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error al aprobar conductor: $e');
    }
  }

  Future<void> rejectDriverRequest(String userId) async {
    try {
      await _db.from('users').update({
        'estado_solicitud': 'rechazado',
        'rol_solicitado': null,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error al rechazar conductor: $e');
    }
  }

  Future<void> toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      await _db.from('users').update({'is_active': isActive}).eq('id', userId);
    } catch (e) {
      throw Exception('Error al cambiar estado de usuario: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _db.from('users').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }
}

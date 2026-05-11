import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repositorio de viajes usando Supabase (CRUD + Realtime).
/// Adaptado al esquema real de la tabla `trips`:
///   id, user_id, company_id, cost, status, created_at,
///   driver_id, origin_text, destination_text,
///   origin_lat, origin_lng, dest_lat, dest_lng
class TripSupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ──────────────────────────────────────────────
  //  HELPER — Obtener UUID de Supabase desde Firebase UID
  // ──────────────────────────────────────────────

  /// Busca en la tabla `users` el UUID de Supabase a partir del firebase_uid.
  Future<String?> getSupabaseUserId(String firebaseUid) async {
    try {
      final data = await _client
          .from('users')
          .select('id')
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();
      return data?['id'] as String?;
    } catch (e) {
      debugPrint('Error obteniendo Supabase user ID: $e');
      return null;
    }
  }

  /// Busca el display_name del usuario por su UUID de Supabase.
  Future<String?> getUserDisplayName(String supabaseUserId) async {
    try {
      final data = await _client
          .from('users')
          .select('display_name')
          .eq('id', supabaseUserId)
          .maybeSingle();
      return data?['display_name'] as String?;
    } catch (e) {
      debugPrint('Error obteniendo display_name: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  //  PASSENGER — Crear viaje
  // ──────────────────────────────────────────────

  /// Inserta un nuevo viaje con status 'buscando'.
  /// [userId] debe ser el UUID de Supabase (NO el firebase_uid).
  Future<String> createTrip({
    required String userId,
    required double originLat,
    required double originLng,
    String? originText,
    required double destLat,
    required double destLng,
    required String destinationText,
    required double cost,
    String? companyId,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'status': 'buscando',
        'origin_lat': originLat,
        'origin_lng': originLng,
        'origin_text': originText,
        'destination_text': destinationText,
        'dest_lat': destLat,
        'dest_lng': destLng,
        'cost': cost,
        if (companyId != null) 'company_id': companyId,
      };

      final response = await _client
          .from('trips')
          .insert(data)
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error al crear viaje: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  PASSENGER — Escuchar cambios en MI viaje
  // ──────────────────────────────────────────────

  /// Stream Realtime que emite cada vez que un viaje específico cambia.
  Stream<Map<String, dynamic>> listenTripStatus(String tripId) {
    return _client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((list) => list.isNotEmpty ? list.first : <String, dynamic>{});
  }

  // ──────────────────────────────────────────────
  //  DRIVER — Escuchar viajes con status 'buscando'
  // ──────────────────────────────────────────────

  /// Stream Realtime de todos los viajes en estado 'buscando'.
  Stream<List<Map<String, dynamic>>> listenSearchingTrips() {
    return _client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('status', 'buscando')
        .order('created_at', ascending: false);
  }

  // ──────────────────────────────────────────────
  //  DRIVER — Aceptar viaje
  // ──────────────────────────────────────────────

  /// Actualiza el viaje: asigna driver_id (UUID Supabase) y cambia status a 'aceptado'.
  Future<void> acceptTrip({
    required String tripId,
    required String driverId,
  }) async {
    try {
      await _client.from('trips').update({
        'driver_id': driverId,
        'status': 'aceptado',
      }).eq('id', tripId);
    } catch (e) {
      throw Exception('Error al aceptar viaje: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  PASSENGER — Cancelar viaje
  // ──────────────────────────────────────────────

  Future<void> cancelTrip(String tripId) async {
    try {
      await _client.from('trips').update({
        'status': 'cancelado',
      }).eq('id', tripId);
    } catch (e) {
      throw Exception('Error al cancelar viaje: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  GENERAL — Actualizar estado del viaje
  // ──────────────────────────────────────────────

  Future<void> updateTripStatus(String tripId, String status) async {
    try {
      await _client.from('trips').update({
        'status': status,
      }).eq('id', tripId);
    } catch (e) {
      throw Exception('Error al actualizar estado del viaje: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  HELPER — Obtener Firebase UID desde Supabase UUID
  // ──────────────────────────────────────────────

  Future<String?> getFirebaseUid(String supabaseUserId) async {
    try {
      final data = await _client
          .from('users')
          .select('firebase_uid')
          .eq('id', supabaseUserId)
          .maybeSingle();
      return data?['firebase_uid'] as String?;
    } catch (e) {
      debugPrint('Error obteniendo Firebase UID: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  //  PASSENGER — Escuchar ubicación del conductor asignado
  // ──────────────────────────────────────────────

  Stream<Map<String, dynamic>> listenDriverLocation(String firebaseUid) {
    return _client
        .from('driver_locations')
        .stream(primaryKey: ['id'])
        .eq('driver_id', firebaseUid)
        .map((list) => list.isNotEmpty ? list.first : <String, dynamic>{});
  }

  // ──────────────────────────────────────────────
  //  DRIVER — Publicar / Actualizar ubicación
  // ──────────────────────────────────────────────

  /// Upsert en driver_locations (crea o actualiza).
  Future<void> updateDriverLocation({
    required String driverId,
    String? driverName,
    required double latitude,
    required double longitude,
    bool isActive = true,
  }) async {
    try {
      await _client.from('driver_locations').upsert({
        'driver_id': driverId,
        'driver_name': driverName,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'driver_id');
    } catch (e) {
      debugPrint('Error actualizando ubicación del conductor: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  PASSENGER — Obtener conductores cercanos activos
  // ──────────────────────────────────────────────

  /// Fetch de todos los conductores activos.
  Future<List<Map<String, dynamic>>> fetchActiveDrivers() async {
    try {
      final data = await _client
          .from('driver_locations')
          .select()
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error obteniendo conductores activos: $e');
      return [];
    }
  }

  /// Stream Realtime de conductores activos.
  Stream<List<Map<String, dynamic>>> listenActiveDrivers() {
    return _client
        .from('driver_locations')
        .stream(primaryKey: ['id'])
        .eq('is_active', true);
  }

  // ──────────────────────────────────────────────
  //  DRIVER — Historial de viajes completados
  // ──────────────────────────────────────────────

  /// Obtiene los viajes finalizados/completados de un conductor (por su UUID de Supabase).
  Future<List<Map<String, dynamic>>> fetchDriverCompletedTrips(String driverSupabaseId) async {
    try {
      final data = await _client
          .from('trips')
          .select()
          .eq('driver_id', driverSupabaseId)
          .inFilter('status', ['completado', 'finalizado'])
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error obteniendo historial de viajes: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────
  //  PASSENGER — Historial de viajes del pasajero
  // ──────────────────────────────────────────────

  /// Obtiene todos los viajes de un pasajero (por su UUID de Supabase).
  Future<List<Map<String, dynamic>>> fetchPassengerTrips(String passengerSupabaseId) async {
    try {
      final data = await _client
          .from('trips')
          .select()
          .eq('user_id', passengerSupabaseId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error obteniendo historial de pasajero: $e');
      return [];
    }
  }
}

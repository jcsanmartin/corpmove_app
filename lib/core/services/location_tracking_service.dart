import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de emisión de ubicación GPS en tiempo real.
///
/// Usa [Geolocator] con un `distanceFilter` de 10 metros para detectar
/// movimiento y actualiza la columna `position` (jsonb: {lat, lng})
/// de la tabla `users` en Supabase cada vez que el dispositivo se mueve.
///
/// Uso:
/// ```dart
/// final service = LocationTrackingService();
/// await service.startTracking('supabase-user-uuid');
/// // ...
/// service.stopTracking();
/// ```
class LocationTrackingService {
  final SupabaseClient _client = Supabase.instance.client;

  StreamSubscription<Position>? _positionSubscription;
  String? _currentUserId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Inicia el tracking GPS.
  ///
  /// [supabaseUserId] — UUID del usuario actual en la tabla `users`.
  /// Cada vez que el dispositivo detecte un movimiento >= 10 metros,
  /// se actualiza `users.position` con `{lat, lng}`.
  Future<void> startTracking(String supabaseUserId) async {
    if (_isTracking && _currentUserId == supabaseUserId) return;

    // Detener cualquier tracking anterior
    stopTracking();

    _currentUserId = supabaseUserId;

    // ── Verificar permisos ──
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationTracking] Servicio de ubicación deshabilitado');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[LocationTracking] Permiso de ubicación denegado');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationTracking] Permiso de ubicación denegado permanentemente');
      return;
    }

    // ── Publicar posición inicial ──
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _publishPosition(initialPosition.latitude, initialPosition.longitude);
    } catch (e) {
      debugPrint('[LocationTracking] Error obteniendo posición inicial: $e');
    }

    // ── Stream de posición con distanceFilter de 10m ──
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Solo emite si hay movimiento >= 10m
      ),
    ).listen(
      (Position position) {
        _publishPosition(position.latitude, position.longitude);
      },
      onError: (error) {
        debugPrint('[LocationTracking] Error en stream de posición: $error');
      },
    );

    _isTracking = true;
    debugPrint('[LocationTracking] Tracking iniciado para usuario: $supabaseUserId');
  }

  /// Detiene el tracking GPS y limpia recursos.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _currentUserId = null;
    debugPrint('[LocationTracking] Tracking detenido');
  }

  /// Publica la posición actual en `users.position` (jsonb).
  Future<void> _publishPosition(double lat, double lng) async {
    if (_currentUserId == null) return;

    try {
      await _client.from('users').update({
        'position': {'lat': lat, 'lng': lng},
      }).eq('id', _currentUserId!);
    } catch (e) {
      debugPrint('[LocationTracking] Error actualizando posición: $e');
    }
  }
}

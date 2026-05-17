import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/core/widgets/custom_map_mapbox.dart';
import 'package:corpmove_app/features/data/repositories/trip_supabase_repository.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:http/http.dart' as http;

const String _kMapboxToken =
    "pk.eyJ1IjoiamNzYW5tYXJ0aW4iLCJhIjoiY21vYWJsZmUzMDR5eTJ4cTA5MmFvbmJpbSJ9.OZtHCg1w7y-HUow9Cl9Vsw";

/// Pantalla de espera del pasajero después de solicitar un viaje.
/// Escucha Realtime de Supabase para detectar cuando un conductor acepta.
class WaitingDriverScreen extends StatefulWidget {
  final String tripId;
  final String destinationName;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final double proposedFare;

  const WaitingDriverScreen({
    super.key,
    required this.tripId,
    required this.destinationName,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.proposedFare,
  });

  @override
  State<WaitingDriverScreen> createState() => _WaitingDriverScreenState();
}

class _WaitingDriverScreenState extends State<WaitingDriverScreen>
    with SingleTickerProviderStateMixin {
  final TripSupabaseRepository _tripRepo = TripSupabaseRepository();
  StreamSubscription<Map<String, dynamic>>? _tripSubscription;

  // Estados del viaje
  bool _driverAccepted = false;
  String? _driverName;
  String _tripStatus = 'buscando';
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;
  mbx.MapboxMap? _mapController;

  // Animación del pulso
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _listenForTripChanges();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _driverLocationSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _listenForTripChanges() {
    _tripSubscription =
        _tripRepo.listenTripStatus(widget.tripId).listen((tripData) async {
      if (!mounted) return;

      final status = tripData['status'] as String?;
      if (status == null) return;
      
      setState(() {
        _tripStatus = status;
      });

      if (status == 'aceptado' && !_driverAccepted) {
        final driverId = tripData['driver_id'] as String?;
        String driverNameStr = 'Conductor';
        if (driverId != null) {
          final fetchedName = await _tripRepo.getUserDisplayName(driverId);
          if (fetchedName != null) driverNameStr = fetchedName;
          
          // Escuchar posición del conductor desde users.position (Supabase UUID)
          _startDriverTracking(driverId);
        }
        
        if (mounted) {
          setState(() {
            _driverAccepted = true;
            _driverName = driverNameStr;
          });
        }
      } else if (status == 'en_curso') {
        // Conductor llegó al punto de recogida → quitar el carro del mapa
        _driverLocationSub?.cancel();
        _driverLocationSub = null;
        await _removeDriverMarker();
      } else if (status == 'cancelado') {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viaje cancelado')),
          );
        }
      } else if (status == 'finalizado') {
        _showRatingDialog();
      }
    });
  }
  
  void _startDriverTracking(String driverSupabaseId) {
    _driverLocationSub?.cancel();
    // Stream Realtime de la tabla users filtrando por driver_id (UUID Supabase)
    _driverLocationSub = _tripRepo.listenUserPosition(driverSupabaseId).listen((userData) {
      if (!mounted || userData.isEmpty) return;
      final position = userData['position'];
      if (position == null) return;
      final lat = (position['lat'] as num?)?.toDouble();
      final lng = (position['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _updateDriverMarkerOnMap(lat, lng);
      }
    });
  }

  bool _carImageAdded = false;
  bool _driverSourceAdded = false;

  Future<void> _addCarImage() async {
    if (_mapController == null || _carImageAdded) return;
    try {
      // Load the PNG asset
      final byteData = await rootBundle.load('assets/images/carro_mapa.png');
      final pngBytes = byteData.buffer.asUint8List();
      
      // Decode PNG to raw RGBA pixel data
      final codec = await ui.instantiateImageCodec(
        pngBytes,
        targetWidth: 96,
        targetHeight: 96,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final rgbaData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      
      if (rgbaData == null) {
        debugPrint('Failed to decode car image to RGBA');
        return;
      }
      
      await _mapController!.style.addStyleImage(
        'car-icon',
        2.0, // pixel ratio for retina
        mbx.MbxImage(
          width: image.width,
          height: image.height,
          data: rgbaData.buffer.asUint8List(),
        ),
        false,
        [],
        [],
        null,
      );
      _carImageAdded = true;
    } catch (e) {
      debugPrint('Error adding car image: $e');
    }
  }


  Future<void> _updateDriverMarkerOnMap(double lat, double lng) async {
    if (_mapController == null) return;

    await _addCarImage();

    final geojsonString = jsonEncode({
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [lng, lat]
          },
          "properties": {}
        }
      ]
    });

    try {
      if (!_driverSourceAdded) {
        // Primera vez: crear source + layer
        await _mapController!.style.addSource(
          mbx.GeoJsonSource(id: "driver-source", data: geojsonString),
        );

        if (_carImageAdded) {
          await _mapController!.style.addLayer(mbx.SymbolLayer(
            id: "driver-layer",
            sourceId: "driver-source",
            iconImage: 'car-icon',
            iconSize: 0.6,
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
          ));
        } else {
          await _mapController!.style.addLayer(mbx.CircleLayer(
            id: "driver-layer",
            sourceId: "driver-source",
            circleRadius: 10.0,
            circleColor: Colors.deepPurpleAccent.value,
            circleStrokeColor: Colors.white.value,
            circleStrokeWidth: 3.0,
          ));
        }
        _driverSourceAdded = true;
      } else {
        // Optimización: solo actualizar los datos del GeoJsonSource existente
        // sin recrear el source ni el layer → evita parpadeos
        final source = await _mapController!.style.getSource("driver-source");
        if (source is mbx.GeoJsonSource) {
          await source.updateGeoJSON(geojsonString);
        }
      }
    } catch (e) {
      debugPrint('Error updating driver marker: $e');
    }
  }

  Future<void> _removeDriverMarker() async {
    if (_mapController == null) return;
    try {
      if (await _mapController!.style.styleLayerExists("driver-layer") == true) {
        await _mapController!.style.removeStyleLayer("driver-layer");
      }
      if (await _mapController!.style.styleSourceExists("driver-source") == true) {
        await _mapController!.style.removeStyleSource("driver-source");
      }
      _driverSourceAdded = false;
    } catch (e) {
      debugPrint('Error removing driver marker: $e');
    }
  }
  
  void _showRatingDialog() {
    int _rating = 5;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.scaffoldLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Viaje finalizado', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('¿Cómo estuvo tu viaje?', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () {
                          setDialogState(() => _rating = index + 1);
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      if (mounted) Navigator.pop(context); // Return to home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.textOnAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Finalizar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _cancelTrip() async {
    try {
      await _tripRepo.cancelTrip(widget.tripId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar: $e')),
        );
      }
    }
  }

  Future<void> _drawRoute(mbx.MapboxMap controller) async {
    final originLon = widget.pickupLng;
    final originLat = widget.pickupLat;
    final destLon = widget.destinationLng;
    final destLat = widget.destinationLat;

    final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/$originLon,$originLat;$destLon,$destLat?geometries=geojson&access_token=$_kMapboxToken');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final route = json['routes'][0];
        final geometry = route['geometry'];

        final feature = {
          "type": "Feature",
          "geometry": geometry,
          "properties": {}
        };
        final geojsonString = jsonEncode(feature);

        if (await controller.style.styleSourceExists("route-source") == true) {
          await controller.style.removeStyleLayer("route-layer");
          await controller.style.removeStyleSource("route-source");
        }

        await controller.style.addSource(
            mbx.GeoJsonSource(id: "route-source", data: geojsonString));
        await controller.style.addLayer(mbx.LineLayer(
          id: "route-layer",
          sourceId: "route-source",
          lineColor: AppColors.accentLime.value,
          lineWidth: 5.0,
          lineJoin: mbx.LineJoin.ROUND,
          lineCap: mbx.LineCap.ROUND,
        ));

        // Pines de origen y destino
        final pinsGeoJson = jsonEncode({
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [originLon, originLat]
              },
              "properties": {"isOrigin": true}
            },
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [destLon, destLat]
              },
              "properties": {"isOrigin": false}
            }
          ]
        });

        if (await controller.style.styleSourceExists("pins-source") == true) {
          await controller.style.removeStyleLayer("pins-layer");
          await controller.style.removeStyleSource("pins-source");
        }
        await controller.style.addSource(
            mbx.GeoJsonSource(id: "pins-source", data: pinsGeoJson));
        await controller.style.addLayer(mbx.CircleLayer(
          id: "pins-layer",
          sourceId: "pins-source",
          circleRadius: 8.0,
          circleColor: Colors.white.value,
          circleStrokeColor: AppColors.accentLime.value,
          circleStrokeWidth: 3.0,
        ));

        // Ajustar cámara
        double minLat = originLat < destLat ? originLat : destLat;
        double maxLat = originLat > destLat ? originLat : destLat;
        double minLon = originLon < destLon ? originLon : destLon;
        double maxLon = originLon > destLon ? originLon : destLon;

        final coords = geometry['coordinates'] as List;
        for (var coord in coords) {
          final lon = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          if (lat < minLat) minLat = lat;
          if (lat > maxLat) maxLat = lat;
          if (lon < minLon) minLon = lon;
          if (lon > maxLon) maxLon = lon;
        }

        final bounds = mbx.CoordinateBounds(
          southwest:
              mbx.Point(coordinates: mbx.Position(minLon, minLat)),
          northeast:
              mbx.Point(coordinates: mbx.Position(maxLon, maxLat)),
          infiniteBounds: false,
        );

        final cameraOptions = await controller.cameraForCoordinateBounds(
            bounds,
            mbx.MbxEdgeInsets(top: 120, left: 60, bottom: 350, right: 60),
            null,
            null,
            null,
            null);

        if (cameraOptions != null) {
          controller.setCamera(cameraOptions);
        }
      }
    } catch (e) {
      debugPrint('Error dibujando ruta en WaitingDriverScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      body: Stack(
        children: [
          // Mapa de fondo con la ruta
          Positioned.fill(
            child: CustomMapMapbox(
              initialLat: widget.pickupLat,
              initialLng: widget.pickupLng,
              onMapCreated: (controller) async {
                _mapController = controller;
                controller.location.updateSettings(
                    mbx.LocationComponentSettings(
                        enabled: true, pulsingEnabled: true));
                await _drawRoute(controller);
              },
            ),
          ),

          // Botón de volver
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary, size: 24),
                ),
              ),
            ),
          ),

          // Panel inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: double.infinity,
              decoration: AppDecorations.bottomSheet,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
              child: _driverAccepted
                  ? _buildDriverAcceptedContent()
                  : _buildSearchingContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grabber
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderAccent,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 28),

        // Icono de búsqueda animado
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentLime.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentLime.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: AppColors.accentLime,
                  size: 36,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        Text(
          'Buscando conductor...',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu solicitud fue enviada. Un conductor cercano la aceptará pronto.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),

        // Info del viaje
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.destinationName,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLime.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${widget.proposedFare.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: AppColors.accentLime,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Botón cancelar
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _cancelTrip,
            icon: const Icon(Icons.close_rounded, size: 20),
            label: Text(
              'Cancelar solicitud',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverAcceptedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grabber
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderAccent,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 28),

        // Icono de éxito
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          _tripStatus == 'en_curso' ? '🚙 A bordo' : '🚗 Conductor en camino',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tripStatus == 'en_curso' 
             ? 'El viaje está en progreso. Te diriges a tu destino.'
             : 'Tu conductor ha aceptado el viaje y se dirige a tu ubicación.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Tarjeta del conductor
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.success, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conductor asignado',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _driverName ?? 'Conductor',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Aceptado',
                  style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Info del viaje
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.destinationName,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '\$${widget.proposedFare.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: AppColors.accentLime,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/core/widgets/custom_map_mapbox.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:corpmove_app/features/data/repositories/trip_supabase_repository.dart';

const String MAPBOX_TOKEN = "pk.eyJ1IjoiamNzYW5tYXJ0aW4iLCJhIjoiY21vYWJsZmUzMDR5eTJ4cTA5MmFvbmJpbSJ9.OZtHCg1w7y-HUow9Cl9Vsw";

class ActiveTripScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const ActiveTripScreen({super.key, required this.tripData});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  mbx.MapboxMap? _mapController;
  mbx.CircleAnnotationManager? _circleAnnotationManager;
  mbx.CircleAnnotation? _destinationAnnotation;
  mbx.CircleAnnotation? _originAnnotation;

  StreamSubscription<Position>? _positionStream;
  mbx.Position? _currentPosition;

  // Fases: 'searching_passenger', 'in_progress', 'completed'
  String _currentPhase = 'searching_passenger'; 

  late double _pickupLat;
  late double _pickupLng;
  late double _dropoffLat;
  late double _dropoffLng;

  @override
  void initState() {
    super.initState();
    _pickupLat = widget.tripData['pickup_lat'] ?? 10.4503;
    _pickupLng = widget.tripData['pickup_lng'] ?? -73.2541;
    _dropoffLat = widget.tripData['dropoff_lat'] ?? 10.4762;
    _dropoffLng = widget.tripData['dropoff_lng'] ?? -73.2483;
    
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _currentPosition = mbx.Position(position.longitude, position.latitude);

    _startLocationStream();
  }

  bool _initialRouteDrawn = false;

  void _startLocationStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      final pos = mbx.Position(position.longitude, position.latitude);
      _currentPosition = pos;
      _updateDriverMarker(pos);

      if (!_initialRouteDrawn && _mapController != null && _currentPhase == 'searching_passenger') {
        _initialRouteDrawn = true;
        _drawRoute(pos, mbx.Position(_pickupLng, _pickupLat));
      }
    });
  }

  Future<void> _updateDriverMarker(mbx.Position pos) async {
    // Ya no centramos la cámara en el conductor constantemente
    // para permitir que el conductor vea la ruta completa y el destino.
  }

  Future<void> _onMapCreated(mbx.MapboxMap controller) async {
    _mapController = controller;
    _circleAnnotationManager = await _mapController?.annotations.createCircleAnnotationManager();
    
    _mapController?.location.updateSettings(mbx.LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
    ));

    if (_currentPosition != null && !_initialRouteDrawn && _currentPhase == 'searching_passenger') {
      _initialRouteDrawn = true;
      _mapController?.setCamera(mbx.CameraOptions(
        center: mbx.Point(coordinates: _currentPosition!),
        zoom: 15.0,
      ));
      await _drawRoute(_currentPosition!, mbx.Position(_pickupLng, _pickupLat));
    }
  }

  Future<void> _drawRoute(mbx.Position origin, mbx.Position destination) async {
    final originLon = origin.lng;
    final originLat = origin.lat;
    final destLon = destination.lng;
    final destLat = destination.lat;

    final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/$originLon,$originLat;$destLon,$destLat?geometries=geojson&access_token=$MAPBOX_TOKEN');

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

        // Dibujar ruta
        if (await _mapController?.style.styleSourceExists("route-source") == true) {
          await _mapController?.style.removeStyleLayer("route-layer");
          await _mapController?.style.removeStyleSource("route-source");
        }

        await _mapController?.style.addSource(mbx.GeoJsonSource(id: "route-source", data: geojsonString));
        await _mapController?.style.addLayer(mbx.LineLayer(
          id: "route-layer",
          sourceId: "route-source",
          lineColor: Colors.blue.value,
          lineWidth: 5.0,
          lineJoin: mbx.LineJoin.ROUND,
          lineCap: mbx.LineCap.ROUND,
        ));

        // Dibujar pines de origen y destino usando capas (layers)
        if (await _mapController?.style.styleSourceExists("pins-source") == true) {
          await _mapController?.style.removeStyleLayer("pins-layer");
          await _mapController?.style.removeStyleSource("pins-source");
        }

        final pinsGeoJson = jsonEncode({
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {"type": "Point", "coordinates": [originLon, originLat]},
              "properties": {"isOrigin": true}
            },
            {
              "type": "Feature",
              "geometry": {"type": "Point", "coordinates": [destLon, destLat]},
              "properties": {"isOrigin": false}
            }
          ]
        });

        await _mapController?.style.addSource(mbx.GeoJsonSource(id: "pins-source", data: pinsGeoJson));
        
        // Capa para los pines (usaremos un CircleLayer que cambia de color según la propiedad isOrigin)
        // Ya que Mapbox Flutter a veces requiere expresiones complejas para colores dinámicos,
        // lo haremos más sencillo agregando dos capas diferentes o colores fijos.
        // Para simplificar, crearemos una capa genérica de puntos grandes oscuros con borde blanco.
        await _mapController?.style.addLayer(mbx.CircleLayer(
          id: "pins-layer",
          sourceId: "pins-source",
          circleRadius: 8.0,
          circleColor: Colors.black87.value,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 3.0,
        ));

        // Ajustar la cámara para ver la ruta completa
        double minLat = (originLat < destLat ? originLat : destLat).toDouble();
        double maxLat = (originLat > destLat ? originLat : destLat).toDouble();
        double minLon = (originLon < destLon ? originLon : destLon).toDouble();
        double maxLon = (originLon > destLon ? originLon : destLon).toDouble();
        
        final bounds = mbx.CoordinateBounds(
          southwest: mbx.Point(coordinates: mbx.Position(minLon, minLat)),
          northeast: mbx.Point(coordinates: mbx.Position(maxLon, maxLat)),
          infiniteBounds: false,
        );
        
        final cameraOptions = await _mapController?.cameraForCoordinateBounds(
          bounds, 
          mbx.MbxEdgeInsets(top: 100, left: 50, bottom: 400, right: 50),
          null, null, null, null
        );

        if (cameraOptions != null) {
          _mapController?.setCamera(cameraOptions);
        }
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  Future<void> _updateTripStatus(String status) async {
    final tripId = widget.tripData['id'];
    if (tripId == null || tripId == 'mock-trip-123') return; 

    try {
      final tripRepo = TripSupabaseRepository();
      await tripRepo.updateTripStatus(tripId, status);
    } catch (e) {
      debugPrint('Error updating trip status: $e');
    }
  }

  void _onPhaseButtonPressed() async {
    if (_currentPhase == 'searching_passenger') {
      setState(() => _currentPhase = 'en_curso');
      await _updateTripStatus('en_curso');
      await _drawRoute(
        mbx.Position(_pickupLng, _pickupLat), 
        mbx.Position(_dropoffLng, _dropoffLat)
      );
    } else if (_currentPhase == 'en_curso') {
      setState(() => _currentPhase = 'finalizado');
      await _updateTripStatus('finalizado');
      if (mounted) {
        Navigator.pop(context); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = 'Llegué al punto de recogida';
    Color buttonColor = AppColors.accentLime;
    
    if (_currentPhase == 'en_curso') {
      buttonText = 'Finalizar Viaje';
      buttonColor = AppColors.info;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomMapMapbox(
              onMapCreated: _onMapCreated,
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                heroTag: 'backBtn',
                mini: true,
                backgroundColor: AppColors.surfaceLight,
                child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: AppDecorations.bottomSheet,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.borderAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.cardLight,
                        child: Icon(Icons.person, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tripData['client_name'] ?? 'Cliente',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _currentPhase == 'searching_passenger' ? 'En camino a recoger' : 'Viaje en progreso',
                              style: GoogleFonts.inter(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: AppColors.success),
                        onPressed: () {},
                        style: IconButton.styleFrom(backgroundColor: AppColors.success.withOpacity(0.2)),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onPhaseButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: AppColors.textOnAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        buttonText,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

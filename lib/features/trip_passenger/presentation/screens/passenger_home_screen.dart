import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/negotiation_radar_screen.dart';
import 'package:corpmove_app/core/widgets/custom_map_mapbox.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/dual_mode_selector.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/profile_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const String MAPBOX_TOKEN = "pk.eyJ1IjoiamNzYW5tYXJ0aW4iLCJhIjoiY21vYWJsZmUzMDR5eTJ4cTA5MmFvbmJpbSJ9.OZtHCg1w7y-HUow9Cl9Vsw";

class MapTapListener implements mbx.OnMapTapListener {
  final void Function(mbx.MapContentGestureContext) onTap;
  MapTapListener(this.onTap);

  @override
  void onMapTap(mbx.MapContentGestureContext context) {
    onTap(context);
  }
}

class PassengerHomeScreen extends StatefulWidget {
  final bool isCorporateEnabled;

  const PassengerHomeScreen({
    super.key,
    required this.isCorporateEnabled,
  });

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  late bool _isCorporateMode;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Variables dinámicas
  bool _isLoading = true;
  String _displayName = 'Usuario';
  String _userRole = 'normal';
  double _techoCobertura = 0.0;
  int _dailyTripsLimit = 0;
  int _tripsRemaining = 0;

  // Mapa y ubicaciones
  mbx.MapboxMap? _mapController;
  mbx.CircleAnnotationManager? _circleAnnotationManager;
  mbx.CircleAnnotation? _pickupAnnotation;

  StreamSubscription<Position>? _positionStream;
  bool _isManualLocation = false;
  mbx.Position? _pickupLocation;
  mbx.Position? _destinationLocation;
  String? _destinationName;

  @override
  void initState() {
    super.initState();
    _isCorporateMode = widget.isCorporateEnabled;
    _fetchUserData();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final userData = await supabase
          .from('users')
          .select()
          .eq('firebase_uid', user.uid)
          .maybeSingle();

      if (userData != null) {
        _displayName = userData['display_name'] ?? 'Usuario';
        _userRole = userData['role'] ?? 'normal';

        if (_userRole == 'corporativo') {
          _isCorporateMode = true; 
          final companyId = userData['company_id'];

          if (companyId != null) {
            final companyData = await supabase
                .from('companies')
                .select()
                .eq('id', companyId)
                .maybeSingle();

            if (companyData != null) {
              _techoCobertura = (companyData['corporate_limit'] as num?)?.toDouble() ?? 0.0;
              // Usamos el límite de la tabla users o de la tabla companies
              _dailyTripsLimit = (userData['daily_trips_limit'] as num?)?.toInt() ?? 
                                 (companyData['daily_trips_limit'] as num?)?.toInt() ?? 0;
            }

            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

            final tripsData = await supabase
                .from('trips')
                .select('id')
                .eq('user_id', user.uid)
                .gte('created_at', startOfDay);

            final tripsToday = tripsData.length;
            _tripsRemaining = (_dailyTripsLimit - tripsToday).clamp(0, _dailyTripsLimit);
          }
        } else {
          _isCorporateMode = false;
        }
      } else {
        _displayName = user.displayName ?? 'Usuario';
      }
    } catch (e) {
      debugPrint('Error obteniendo datos del usuario: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

    _startLocationStream();

    if (_mapController != null) {
      _centerMapOnUser(forceResetManual: false);
    }
  }

  Future<void> _startLocationStream() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (!_isManualLocation) {
        final pos = mbx.Position(position.longitude, position.latitude);
        _pickupLocation = pos;
        _updatePickupMarker(pos);
      }
    });
  }

  Future<void> _centerMapOnUser({bool forceResetManual = true}) async {
    try {
      if (forceResetManual) {
        setState(() {
          _isManualLocation = false;
        });
      }

      Position position = await Geolocator.getCurrentPosition();
      final pos = mbx.Position(position.longitude, position.latitude);
      
      if (!_isManualLocation) {
        _pickupLocation = pos;
        _updatePickupMarker(pos);
      }

      _mapController?.setCamera(mbx.CameraOptions(
        center: mbx.Point(coordinates: pos),
        zoom: 15.5,
      ));

      _mapController?.location.updateSettings(mbx.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ));
    } catch (e) {
      debugPrint('Error centrando el mapa: $e');
    }
  }

  Future<void> _updatePickupMarker(mbx.Position pos) async {
    if (_circleAnnotationManager == null) return;

    if (_pickupAnnotation != null) {
      _pickupAnnotation?.geometry = mbx.Point(coordinates: pos);
      await _circleAnnotationManager?.update(_pickupAnnotation!);
    } else {
      _pickupAnnotation = await _circleAnnotationManager?.create(mbx.CircleAnnotationOptions(
        geometry: mbx.Point(coordinates: pos),
        circleRadius: 8.0,
        circleColor: Colors.greenAccent.value,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 3.0,
      ));
    }
  }

  Future<void> _addDummyPickupPoints(mbx.Position center) async {
    final features = [
      {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [center.lng + 0.002, center.lat + 0.002]}
      },
      {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [center.lng - 0.002, center.lat + 0.001]}
      },
      {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [center.lng + 0.001, center.lat - 0.003]}
      }
    ];

    final geojson = jsonEncode({
      "type": "FeatureCollection",
      "features": features
    });

    if (await _mapController?.style.styleSourceExists("pickup-source") == true) return;

    await _mapController?.style.addSource(mbx.GeoJsonSource(id: "pickup-source", data: geojson));
    await _mapController?.style.addLayer(mbx.CircleLayer(
      id: "pickup-layer",
      sourceId: "pickup-source",
      circleColor: Colors.orangeAccent.value,
      circleRadius: 6.0,
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.white.value,
    ));
  }

  Future<void> _getRoute(mbx.Position destination) async {
    if (_pickupLocation == null) return;
    
    final originLon = _pickupLocation!.lng;
    final originLat = _pickupLocation!.lat;
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

        // Remover capas previas de ruta
        if (await _mapController?.style.styleSourceExists("route-source") == true) {
          await _mapController?.style.removeStyleLayer("route-layer");
          await _mapController?.style.removeStyleSource("route-source");
        }
        
        // Agregar origen de datos y capa de ruta
        await _mapController?.style.addSource(mbx.GeoJsonSource(id: "route-source", data: geojsonString));
        await _mapController?.style.addLayer(mbx.LineLayer(
          id: "route-layer",
          sourceId: "route-source",
          lineColor: Colors.blue.value,
          lineWidth: 5.0,
          lineJoin: mbx.LineJoin.ROUND,
          lineCap: mbx.LineCap.ROUND,
        ));

        // Calcular límites para enfocar ambos puntos y la ruta
        double minLat = originLat < destLat ? originLat : destLat;
        double maxLat = originLat > destLat ? originLat : destLat;
        double minLon = originLon < destLon ? originLon : destLon;
        double maxLon = originLon > destLon ? originLon : destLon;

        final coords = geometry['coordinates'] as List;
        for (var coord in coords) {
          final lon = coord[0];
          final lat = coord[1];
          if (lat < minLat) minLat = lat;
          if (lat > maxLat) maxLat = lat;
          if (lon < minLon) minLon = lon;
          if (lon > maxLon) maxLon = lon;
        }
        
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
      debugPrint('Error dibujando ruta: $e');
    }
  }

  void _openSearchBottomSheet() async {
    if (_pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación de origen no disponible. Espera un momento.')),
      );
      await _centerMapOnUser(forceResetManual: false);
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SearchLocationSheet(
          currentPosition: _pickupLocation!,
        );
      },
    );

    if (result != null) {
      final destPosition = result['destination'] as mbx.Position;
      setState(() {
        _destinationLocation = destPosition;
        _destinationName = result['placeName'];
      });
      await _getRoute(destPosition);
    }
  }

  late final List<Widget> _screens = [
    _buildHomeTab(),
    const _HistoryTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    _screens[0] = _buildHomeTab();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffoldLight,
      drawer: _buildDrawer(context),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surfaceLight,
        elevation: 16,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String defaultName = _isCorporateMode ? 'Empleado CorpMove' : 'Usuario';
    
    String displayName = _displayName;
    if (displayName.trim().isEmpty) {
      displayName = user?.email?.split('@').first ?? defaultName;
    }
    
    final String displayEmail = user?.email ?? 'correo@ejemplo.com';

    return Drawer(
      backgroundColor: AppColors.surfaceLight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.cardLight,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.accentLime,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.person_rounded, size: 36, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  displayEmail,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_rounded, color: AppColors.textPrimary),
            title: Text('Mi cuenta', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            title: Text('Configuración', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(color: AppColors.borderSubtle),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text('Cerrar sesión', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w500)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomMapMapbox(
            onMapCreated: (controller) async {
              _mapController = controller;
              _circleAnnotationManager = await _mapController?.annotations.createCircleAnnotationManager();
              
              _mapController?.gestures.addOnMapTapListener(MapTapListener((context) async {
                final pos = context.point.coordinates;
                setState(() {
                  _isManualLocation = true;
                  _pickupLocation = pos;
                });
                await _updatePickupMarker(pos);
                
                // Si el usuario ya había buscado un destino, redibujamos la ruta desde el nuevo punto libre
                if (_destinationLocation != null) {
                  await _getRoute(_destinationLocation!);
                }
              }));

              // Generar algunos puntos de recogida simulados al inicio si hay ubicación
              if (_pickupLocation != null) {
                await _addDummyPickupPoints(_pickupLocation!);
              }

              _centerMapOnUser(forceResetManual: false);
            },
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                    child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido,',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF0F0F0),
                            shadows: [Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 12)],
                          ),
                        ),
                        _isLoading
                            ? Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 100,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )
                            : Text(
                                _displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  shadows: [Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 12)],
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 16),
                child: FloatingActionButton(
                  heroTag: 'location',
                  backgroundColor: _isManualLocation ? AppColors.accentLime : AppColors.surfaceLight,
                  foregroundColor: _isManualLocation ? AppColors.textOnAccent : AppColors.textPrimary,
                  elevation: 4,
                  mini: true,
                  onPressed: () {
                    _centerMapOnUser(forceResetManual: true);
                    if (_destinationLocation != null) {
                       _getRoute(_destinationLocation!); // Redibuja ruta desde el GPS real
                    }
                  },
                  child: Icon(_isManualLocation ? Icons.gps_fixed : Icons.my_location_rounded),
                ),
              ),
              
              Container(
                width: double.infinity,
                decoration: AppDecorations.bottomSheet,
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 32),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppColors.accentLime),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mostrar el destino seleccionado o el botón de búsqueda
                          if (_destinationName != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _destinationName!,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                                  onPressed: () {
                                    setState(() {
                                      _destinationName = null;
                                      _destinationLocation = null;
                                    });
                                    _mapController?.style.removeStyleLayer("route-layer");
                                    _mapController?.style.removeStyleSource("route-source");
                                    _centerMapOnUser(forceResetManual: false);
                                  },
                                )
                              ],
                            ),
                            const Divider(color: AppColors.borderSubtle),
                          ],

                          if (_userRole == 'corporativo')
                            DualModeSelector(
                              isCorporateMode: _isCorporateMode,
                              onModeChanged: (value) => setState(() => _isCorporateMode = value),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Modo Personal',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _destinationName == null 
                                ? _openSearchBottomSheet 
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NegotiationRadarScreen(
                                          isCorporateMode: _isCorporateMode,
                                          techoCobertura: _isCorporateMode ? _techoCobertura : 0.0,
                                        ),
                                      ),
                                    );
                                  },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _destinationName == null ? AppColors.surfaceLight : AppColors.accentLime,
                                foregroundColor: _destinationName == null ? AppColors.textPrimary : AppColors.textOnAccent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: _destinationName == null ? const BorderSide(color: AppColors.borderSubtle) : BorderSide.none,
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_destinationName == null ? Icons.search : Icons.local_taxi, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _destinationName == null 
                                      ? '¿A dónde y por cuánto?' 
                                      : (_isCorporateMode ? 'Solicitar Viaje Corp' : 'Solicitar Viaje'),
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_isCorporateMode) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentLime.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.accentLime.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.monetization_on_outlined, color: AppColors.accentLime, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Techo: \$${_techoCobertura.toStringAsFixed(0)}',
                                            style: GoogleFonts.inter(
                                              color: AppColors.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.borderSubtle),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.directions_car_rounded, color: AppColors.textMuted, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Quedan $_tripsRemaining de $_dailyTripsLimit',
                                            style: GoogleFonts.inter(
                                              color: AppColors.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Historial de viajes',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Próximamente...',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// BOTTOM SHEET PARA BUSCAR DIRECCIÓN CON MAPBOX GEOCODING
// ----------------------------------------------------

class SearchLocationSheet extends StatefulWidget {
  final mbx.Position currentPosition;

  const SearchLocationSheet({
    required this.currentPosition,
    super.key,
  });

  @override
  State<SearchLocationSheet> createState() => _SearchLocationSheetState();
}

class _SearchLocationSheetState extends State<SearchLocationSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _places = [];
  bool _isSearching = false;

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _places = []);
      return;
    }

    setState(() => _isSearching = true);

    final lon = widget.currentPosition.lng;
    final lat = widget.currentPosition.lat;
    
    final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?proximity=$lon,$lat&access_token=$MAPBOX_TOKEN&language=es');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _places = json['features'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error en geocoding: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Grabber
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderAccent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                hintText: 'Buscar destino...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _searchPlaces('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.accentLime),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                final placeName = place['text'] ?? '';
                final placeAddress = place['place_name'] ?? '';
                
                return ListTile(
                  leading: const Icon(Icons.location_on, color: AppColors.textMuted),
                  title: Text(
                    placeName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    placeAddress,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    final coords = place['center']; // [longitude, latitude]
                    final dest = mbx.Position(coords[0], coords[1]);
                    Navigator.pop(context, {
                      'destination': dest,
                      'placeName': placeAddress,
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
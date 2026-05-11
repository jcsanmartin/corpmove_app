import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/negotiation_radar_screen.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/passenger_settings_screen.dart';
import 'package:corpmove_app/core/widgets/custom_map_mapbox.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/dual_mode_selector.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/profile_tab.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/qr_scanner_screen.dart';
import 'package:corpmove_app/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/waiting_driver_screen.dart';
import 'package:corpmove_app/features/data/repositories/trip_supabase_repository.dart';

const String MAPBOX_TOKEN = "pk.eyJ1IjoiamNzYW5tYXJ0aW4iLCJhIjoiY21vYWJsZmUzMDR5eTJ4cTA5MmFvbmJpbSJ9.OZtHCg1w7y-HUow9Cl9Vsw";



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
  final AuthService _authService = AuthService();

  // Variables dinámicas
  bool _isLoading = true;
  String _displayName = 'Usuario';
  String _userRole = 'normal';
  String? _companyId;
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

  // Precio propuesto y conductores cercanos
  final TextEditingController _fareController = TextEditingController();
  final TripSupabaseRepository _tripRepo = TripSupabaseRepository();
  List<Map<String, dynamic>> _nearbyDrivers = [];
  Timer? _driverRefreshTimer;
  bool _isCreatingTrip = false;

  // Estado local para las notificaciones simuladas
  List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': '1',
      'title': 'Bienvenido a CorpMove',
      'message': 'Tu cuenta ha sido configurada con éxito. Ya puedes solicitar viajes.',
      'time': 'Hace 2 horas',
      'icon': Icons.check_circle_rounded,
      'color': AppColors.success,
    },
    {
      'id': '2',
      'title': 'Viaje Corporativo',
      'message': 'Recuerda que para viajes corporativos debes seleccionar la opción en el selector.',
      'time': 'Hace 1 día',
      'icon': Icons.business_center_rounded,
      'color': AppColors.accentLime,
    },
    {
      'id': '3',
      'title': 'Seguridad',
      'message': 'Comparte tu viaje con personas de confianza desde la pantalla de viaje activo.',
      'time': 'Hace 3 días',
      'icon': Icons.security_rounded,
      'color': AppColors.info,
    },
  ];

  @override
  void initState() {
    super.initState();
    _isCorporateMode = widget.isCorporateEnabled;
    _fetchUserData();
    _requestLocationPermission();
    _startDriverRefreshTimer();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _driverRefreshTimer?.cancel();
    _fareController.dispose();
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

        if (_userRole == 'corporativo' || _userRole == 'employee') {
          _isCorporateMode = true; 
          _companyId = userData['company_id'];
          final supabaseUserId = userData['id']; // El UUID de Supabase

          if (_companyId != null) {
            final companyData = await supabase
                .from('companies')
                .select()
                .eq('id', _companyId!)
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
                .eq('user_id', supabaseUserId) 
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

    try {
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
    } catch (e) {
      debugPrint('Error updating pickup marker: $e');
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
        double originLatD = originLat.toDouble();
        double destLatD = destLat.toDouble();
        double originLonD = originLon.toDouble();
        double destLonD = destLon.toDouble();

        double minLat = originLatD < destLatD ? originLatD : destLatD;
        double maxLat = originLatD > destLatD ? originLatD : destLatD;
        double minLon = originLonD < destLonD ? originLonD : destLonD;
        double maxLon = originLonD > destLonD ? originLonD : destLonD;

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

  // ──── Conductores cercanos ────

  void _startDriverRefreshTimer() {
    _fetchAndDrawNearbyDrivers();
    _driverRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchAndDrawNearbyDrivers();
    });
  }

  Future<void> _fetchAndDrawNearbyDrivers() async {
    try {
      final drivers = await _tripRepo.fetchActiveDrivers();
      if (mounted) {
        setState(() => _nearbyDrivers = drivers);
        _drawDriverMarkers();
      }
    } catch (e) {
      debugPrint('Error fetching nearby drivers: $e');
    }
  }

  Future<void> _drawDriverMarkers() async {
    if (_mapController == null) return;
    try {
      if (await _mapController?.style.styleSourceExists("drivers-source") == true) {
        await _mapController?.style.removeStyleLayer("drivers-layer");
        await _mapController?.style.removeStyleSource("drivers-source");
      }
      if (_nearbyDrivers.isEmpty) return;

      final features = _nearbyDrivers.map((driver) => {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [driver['longitude'], driver['latitude']]
        },
        "properties": {"name": driver['driver_name'] ?? 'Conductor'}
      }).toList();

      final geojson = jsonEncode({"type": "FeatureCollection", "features": features});

      await _mapController?.style.addSource(mbx.GeoJsonSource(id: "drivers-source", data: geojson));
      await _mapController?.style.addLayer(mbx.CircleLayer(
        id: "drivers-layer",
        sourceId: "drivers-source",
        circleRadius: 9.0,
        circleColor: Colors.deepPurpleAccent.value,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 2.5,
      ));
    } catch (e) {
      debugPrint('Error drawing driver markers: $e');
    }
  }

  // ──── Crear viaje en Supabase ────

  Future<void> _createTripAndNavigate() async {
    final fareText = _fareController.text.trim();
    if (fareText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio para el viaje')),
      );
      return;
    }
    final fare = double.tryParse(fareText);
    if (fare == null || fare <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio válido')),
      );
      return;
    }
    if (_pickupLocation == null || _destinationLocation == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isCorporateMode && _companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes una empresa asignada para viajes corporativos.')),
      );
      return;
    }

    setState(() => _isCreatingTrip = true);

    try {
      // Obtener el UUID de Supabase a partir del Firebase UID
      final supabaseUserId = await _tripRepo.getSupabaseUserId(user.uid);
      if (supabaseUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: usuario no encontrado en Supabase')),
          );
        }
        return;
      }

      final tripId = await _tripRepo.createTrip(
        userId: supabaseUserId,
        originLat: _pickupLocation!.lat.toDouble(),
        originLng: _pickupLocation!.lng.toDouble(),
        originText: 'Ubicación actual',
        destLat: _destinationLocation!.lat.toDouble(),
        destLng: _destinationLocation!.lng.toDouble(),
        destinationText: _destinationName!,
        cost: fare,
        companyId: _isCorporateMode ? _companyId : null,
      );

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingDriverScreen(
              tripId: tripId,
              destinationName: _destinationName!,
              pickupLat: _pickupLocation!.lat.toDouble(),
              pickupLng: _pickupLocation!.lng.toDouble(),
              destinationLat: _destinationLocation!.lat.toDouble(),
              destinationLng: _destinationLocation!.lng.toDouble(),
              proposedFare: fare,
            ),
          ),
        );
        // Reset al volver
        if (mounted) {
          setState(() {
            _destinationName = null;
            _destinationLocation = null;
            _fareController.clear();
          });
          try {
            if (await _mapController?.style.styleSourceExists("route-source") == true) {
              await _mapController?.style.removeStyleLayer("route-layer");
              await _mapController?.style.removeStyleSource("route-source");
            }
          } catch (_) {}
          _centerMapOnUser(forceResetManual: false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al solicitar viaje: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingTrip = false);
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PassengerSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderSubtle),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text('Cerrar sesión', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w500)),
            onTap: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notificaciones',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_mockNotifications.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _mockNotifications.clear();
                              });
                            },
                            child: Text(
                              'Marcar como leídas',
                              style: GoogleFonts.inter(
                                color: AppColors.accentLime,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.borderSubtle),
                  Expanded(
                    child: _mockNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_off_rounded, size: 64, color: AppColors.borderSubtle),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes notificaciones nuevas',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _mockNotifications.length,
                            itemBuilder: (context, index) {
                              final notif = _mockNotifications[index];
                              return Dismissible(
                                key: Key(notif['id']),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  setModalState(() {
                                    _mockNotifications.removeAt(index);
                                  });
                                },
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildNotificationTile(
                                    title: notif['title'],
                                    message: notif['message'],
                                    time: notif['time'],
                                    icon: notif['icon'],
                                    color: notif['color'],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
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
              
              // Generar algunos puntos de recogida simulados al inicio si hay ubicación
              if (_pickupLocation != null) {
                await _addDummyPickupPoints(_pickupLocation!);
              }

              _centerMapOnUser(forceResetManual: false);
            },
            onTapListener: (context) async {
              final pos = context.point.coordinates;
              setState(() {
                _isManualLocation = true;
                _pickupLocation = pos;
              });
              await _updatePickupMarker(pos);
              
              if (_destinationLocation != null) {
                await _getRoute(_destinationLocation!);
              }
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
                GestureDetector(
                  onTap: () => _showNotifications(context),
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
                    child: const Icon(Icons.notifications_rounded, color: AppColors.textPrimary, size: 28),
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

                          if (_userRole == 'corporativo' || _userRole == 'employee')
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

                          // Botón de Check-in QR (Hackathon Reto 1)
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentLime),
                            label: const Text("Hacer Check-in con QR"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: const BorderSide(color: AppColors.borderSubtle),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Campo de precio (visible cuando hay destino seleccionado)
                          if (_destinationName != null) ...[
                            TextField(
                              controller: _fareController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Precio propuesto',
                                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                                prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.accentLime),
                                filled: true,
                                fillColor: AppColors.cardElevated,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.accentLime, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCreatingTrip
                                ? null
                                : (_destinationName == null
                                  ? _openSearchBottomSheet
                                  : _createTripAndNavigate),
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
                              child: _isCreatingTrip
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.textOnAccent,
                                    ),
                                  )
                                : Row(
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

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final TripSupabaseRepository _tripRepo = TripSupabaseRepository();
  List<Map<String, dynamic>>? _trips;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() { _error = 'No hay usuario autenticado'; _isLoading = false; });
        return;
      }
      final supabaseId = await _tripRepo.getSupabaseUserId(user.uid);
      if (supabaseId == null) {
        setState(() { _error = 'Usuario no encontrado'; _isLoading = false; });
        return;
      }
      final trips = await _tripRepo.fetchPassengerTrips(supabaseId);
      if (mounted) setState(() { _trips = trips; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completado': case 'finalizado': return const Color(0xFF4CAF50);
      case 'cancelado': return const Color(0xFFE53935);
      case 'en_progreso': case 'en_camino': case 'recogido': return const Color(0xFF2196F3);
      case 'buscando': return const Color(0xFFFF9800);
      default: return const Color(0xFF9E9E9E);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'completado': return 'Completado';
      case 'finalizado': return 'Finalizado';
      case 'cancelado': return 'Cancelado';
      case 'en_progreso': return 'En progreso';
      case 'en_camino': return 'En camino';
      case 'recogido': return 'Recogido';
      case 'buscando': return 'Buscando';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentLime));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(_error!, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _loadTrips, icon: const Icon(Icons.refresh_rounded), label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLime, foregroundColor: Colors.white)),
      ]));
    }
    if (_trips == null || _trips!.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text('Sin viajes aún', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Tus viajes aparecerán aquí', style: GoogleFonts.inter(color: AppColors.textMuted)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _loadTrips, color: AppColors.accentLime,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _trips!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
              const Icon(Icons.history_rounded, color: AppColors.accentLime, size: 22),
              const SizedBox(width: 10),
              Text('Historial de Viajes', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accentLime.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text('${_trips!.length}', style: GoogleFonts.inter(color: AppColors.accentLime, fontSize: 12, fontWeight: FontWeight.w700))),
            ]));
          }
          final t = _trips![index - 1];
          final origin = t['origin_text'] as String? ?? 'Origen';
          final dest = t['destination_text'] as String? ?? 'Destino';
          final cost = (t['cost'] as num?)?.toDouble() ?? 0;
          final status = t['status'] as String? ?? '';
          final createdAt = t['created_at'] as String?;
          final isB2b = t['company_id'] != null;
          String dateStr = '';
          String timeStr = '';
          if (createdAt != null) {
            try {
              final dt = DateTime.parse(createdAt).toLocal();
              dateStr = '${dt.day}/${dt.month}/${dt.year}';
              timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {}
          }
          final sColor = _statusColor(status);
          final done = status == 'completado' || status == 'finalizado';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('$dateStr  $timeStr', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(_statusLabel(status), style: GoogleFonts.inter(color: sColor, fontSize: 10, fontWeight: FontWeight.w700))),
                if (isB2b) ...[
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('Corp', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontSize: 10, fontWeight: FontWeight.w700))),
                ],
              ]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accentLime, shape: BoxShape.circle)),
                  Container(width: 2, height: 24, color: AppColors.borderSubtle),
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: done ? const Color(0xFF4CAF50) : AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(origin, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 14),
                  Text(dest, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.scaffoldLight, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.payments_rounded, size: 16, color: AppColors.accentLime),
                  const SizedBox(width: 8),
                  Text('Tarifa: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                  Text('\$${cost.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accentLime)),
                ])),
            ])),
          );
        },
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _places = []);
      return;
    }

    setState(() => _isSearching = true);

    final lon = widget.currentPosition.lng;
    final lat = widget.currentPosition.lat;
    
    // Bounding box dinámico de aprox ~22km a la redonda para limitar estrictamente a la ciudad actual
    final minLon = lon - 0.2;
    final minLat = lat - 0.2;
    final maxLon = lon + 0.2;
    final maxLat = lat + 0.2;
    
    final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
        '?proximity=$lon,$lat'
        '&bbox=$minLon,$minLat,$maxLon,$maxLat'
        '&types=poi,address,neighborhood'
        '&country=co'
        '&autocomplete=true'
        '&fuzzyMatch=true'
        '&access_token=$MAPBOX_TOKEN'
        '&language=es');

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
              onChanged: _onSearchChanged,
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
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

  mbx.MapboxMap? _mapController;

  @override
  void initState() {
    super.initState();
    _isCorporateMode = widget.isCorporateEnabled;
    _fetchUserData();
    _requestLocationPermission();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // 1. Obtener datos del usuario
      final userData = await supabase
          .from('users')
          .select()
          .eq('firebase_uid', user.uid)
          .maybeSingle();

      if (userData != null) {
        _displayName = userData['display_name'] ?? 'Usuario';
        _userRole = userData['role'] ?? 'normal';

        // Si su rol es corporativo, obtenemos los datos de la empresa y viajes
        if (_userRole == 'corporativo') {
          _isCorporateMode = true; // Forzamos vista si es verdaderamente corporativo
          final companyId = userData['company_id'];

          if (companyId != null) {
            // 2. Traer el límite corporativo
            final companyData = await supabase
                .from('companies')
                .select()
                .eq('id', companyId)
                .maybeSingle();

            if (companyData != null) {
              _techoCobertura = (companyData['corporate_limit'] as num?)?.toDouble() ?? 0.0;
              _dailyTripsLimit = (companyData['daily_trips_limit'] as num?)?.toInt() ?? 0;
            }

            // 3. Contar viajes de hoy
            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

            final tripsData = await supabase
                .from('trips')
                .select('id')
                .eq('user_id', user.uid)
                .gte('created_at', startOfDay);

            final tripsToday = tripsData.length;

            // 4. Calcular viajes restantes
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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Los servicios de ubicación están deshabilitados.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Los permisos de ubicación fueron denegados.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Los permisos de ubicación están denegados permanentemente.');
      return;
    }

    // Centrar mapa si ya cargó
    if (_mapController != null) {
      _centerMapOnUser();
    }
  }

  Future<void> _centerMapOnUser() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      
      _mapController?.setCamera(mbx.CameraOptions(
        center: mbx.Point(coordinates: mbx.Position(position.longitude, position.latitude)),
        zoom: 15.0,
      ));

      // Habilitar la visualización de la ubicación nativa
      _mapController?.location.updateSettings(mbx.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ));
    } catch (e) {
      debugPrint('Error centrando el mapa: $e');
    }
  }

  late final List<Widget> _screens = [
    _buildHomeTab(),
    const _HistoryTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Es posible que el setState asíncrono actualice las pantallas
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
        // Mapa al fondo
        Positioned.fill(
          child: CustomMapMapbox(
            onMapCreated: (controller) {
              _mapController = controller;
              // Si ya se dieron permisos, centramos de inmediato
              _centerMapOnUser();
            },
          ),
        ),

        // Top bar con menú y bienvenida flotante
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menú hamburgesa flotante
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
                // Texto de Bienvenida Dinámico
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
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 12),
                            ],
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
                                  shadows: [
                                    Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 12),
                                  ],
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

        // Bottom Sheet "Hacia dónde vas" y "Qué servicio deseas"
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Botón Mi ubicación flotante reubicado por encima de la tarjeta
              Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 16),
                child: FloatingActionButton(
                  heroTag: 'location',
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 4,
                  mini: true,
                  onPressed: () {
                    _centerMapOnUser();
                  },
                  child: const Icon(Icons.my_location_rounded),
                ),
              ),
              
              // Contenedor principal de la tarjeta negra
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
                          // Grabber
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            '¿Hacia a dónde vas?',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Selector de Modo (Personal / Corporativo) si tiene rol
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

                          // Botón principal "Solicitar Viaje"
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
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
                                backgroundColor: AppColors.accentLime,
                                foregroundColor: AppColors.textOnAccent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text(
                                _isCorporateMode ? 'Solicitar Viaje Corp' : 'Solicitar Viaje',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          // Avisos dinámicos para Corporativo
                          if (_isCorporateMode) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Techo cobertura
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
                                // Viajes restantes
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
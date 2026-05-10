import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/trip_driver/presentation/screens/driver_profile_screen.dart';
import 'package:corpmove_app/features/trip_driver/presentation/screens/driver_settings_screen.dart';
import 'package:corpmove_app/features/trip_driver/presentation/screens/active_trip_screen.dart';
import 'package:corpmove_app/features/data/repositories/trip_supabase_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;
  final TripSupabaseRepository _tripRepo = TripSupabaseRepository();

  // Publicación de ubicación
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _initLocationPublishing();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  // ──── Publicar ubicación cada 30s ────

  Future<void> _initLocationPublishing() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Obtener posición inicial
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _publishLocation();
    } catch (e) {
      debugPrint('Error getting initial position: $e');
    }

    // Stream de ubicación
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _lastPosition = position;
    });

    // Timer para publicar cada 30 segundos
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _publishLocation();
    });
  }

  Future<void> _publishLocation() async {
    if (_lastPosition == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _tripRepo.updateDriverLocation(
      driverId: user.uid,
      driverName: user.displayName ?? 'Conductor',
      latitude: _lastPosition!.latitude,
      longitude: _lastPosition!.longitude,
      isActive: true,
    );
  }

  // ──── Aceptar viaje ────

  Future<void> _acceptTrip(Map<String, dynamic> trip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final tripId = trip['id'] as String;

    try {
      // Obtener UUID de Supabase del conductor
      final supabaseDriverId = await _tripRepo.getSupabaseUserId(user.uid);
      if (supabaseDriverId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: conductor no encontrado en Supabase')),
          );
        }
        return;
      }

      await _tripRepo.acceptTrip(
        tripId: tripId,
        driverId: supabaseDriverId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveTripScreen(tripData: {
              'id': tripId,
              'pickup_lat': (trip['origin_lat'] as num?)?.toDouble() ?? 10.4503,
              'pickup_lng': (trip['origin_lng'] as num?)?.toDouble() ?? -73.2541,
              'dropoff_lat': (trip['dest_lat'] as num?)?.toDouble() ?? 10.4762,
              'dropoff_lng': (trip['dest_lng'] as num?)?.toDouble() ?? -73.2483,
              'status': 'aceptado',
              'client_name': 'Pasajero',
            }),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al aceptar viaje: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Conductor', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
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
                child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 24),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => setState(() => _selectedIndex = 1),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _selectedIndex == 0 ? _buildTripsTab() : _buildEarningsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
            );
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        selectedItemColor: AppColors.accentLime,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surfaceLight,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_rounded), label: 'Viajes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Ganancias'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                  decoration: const BoxDecoration(color: AppColors.accentLime, shape: BoxShape.circle),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.person_rounded, size: 36, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Conductor', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('conductor@corpmove.com', style: GoogleFonts.inter(color: AppColors.textMuted)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle, color: AppColors.textPrimary),
            title: Text('Mi perfil', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DriverProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.textPrimary),
            title: Text('Configuración', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverSettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  // ──── Tab de Viajes — Dinámico desde Supabase ────

  Widget _buildTripsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Viajes disponibles',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'En vivo',
                      style: GoogleFonts.inter(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _tripRepo.listenSearchingTrips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accentLime),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar viajes',
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final trips = snapshot.data ?? [];

              if (trips.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.cardElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Icon(
                          Icons.local_taxi_rounded,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sin viajes disponibles',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Esperando solicitudes de pasajeros...',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentLime,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  final isCorporate = trip['company_id'] != null;
                  final pickup = trip['origin_text'] as String? ?? 'Ubicación del pasajero';
                  final dropoff = trip['destination_text'] as String? ?? 'Destino';
                  final fare = (trip['cost'] as num?)?.toDouble() ?? 0;
                  final passengerName = 'Pasajero';

                  return _buildTripCard(
                    trip: trip,
                    isCorporate: isCorporate,
                    pickup: pickup,
                    dropoff: dropoff,
                    estimatedFare: fare,
                    passengerName: passengerName,
                    onAccept: () => _acceptTrip(trip),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: AppDecorations.cardElevated,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ganancias de hoy', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Text('\$85.000', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEarningChip('Efectivo', 35000, AppColors.success),
                      _buildEarningChip('B2B Garantizado', 50000, AppColors.warning),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Historial de pagos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: const [
                ListTile(title: Text('Viaje #1234'), trailing: Text('\$12.000')),
                ListTile(title: Text('Viaje #1235'), trailing: Text('\$18.500')),
                ListTile(title: Text('Viaje #1236'), trailing: Text('\$22.000')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningChip(String label, int amount, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text('\$$amount', style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTripCard({
    required Map<String, dynamic> trip,
    required bool isCorporate,
    required String pickup,
    required String dropoff,
    required double estimatedFare,
    required String passengerName,
    VoidCallback? onAccept,
  }) {
    return Container(
      decoration: AppDecorations.cardElevated,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pasajero y badge
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentLime.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.accentLime, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    passengerName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isCorporate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text('B2B', style: GoogleFonts.inter(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Pickup
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pickup,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                children: List.generate(3, (_) => Container(
                  width: 2,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  color: AppColors.borderAccent,
                )),
              ),
            ),
            // Dropoff
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dropoff,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarifa y botones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarifa propuesta',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                    ),
                    Text(
                      '\$${estimatedFare.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentLime,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        'Rechazar',
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        'Aceptar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCorporate ? AppColors.accentLime : AppColors.info,
                        foregroundColor: AppColors.textOnAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverProfileTab extends StatelessWidget {
  const _DriverProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Perfil del conductor', style: TextStyle(fontSize: 18)),
          Text('Próximamente...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
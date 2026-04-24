import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/trip_driver/presentation/screens/driver_profile_screen.dart';
import 'package:corpmove_app/features/trip_driver/presentation/screens/driver_settings_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    _buildTripsTab(),
    _buildEarningsTab(),
  ];

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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            // Perfil → pantalla completa
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

  Widget _buildTripsTab() {
    // Contenido original de la lista de viajes (simplificado)
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Viajes disponibles cerca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildTripCard(
          isCorporate: true,
          pickup: 'Calle 100 #19-21',
          dropoff: 'Calle 72 #9-55',
          distance: '5.2 km',
          estimatedFare: 22000,
        ),
        const SizedBox(height: 12),
        _buildTripCard(
          isCorporate: false,
          pickup: 'Carrera 15 #93-45',
          dropoff: 'Avenida Chile #72-10',
          distance: '3.8 km',
          estimatedFare: 14000,
        ),
        const SizedBox(height: 12),
        _buildTripCard(
          isCorporate: true,
          pickup: 'Calle 80 #14-22',
          dropoff: 'Calle 26 #5-90',
          distance: '8.1 km',
          estimatedFare: 31000,
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
    required bool isCorporate,
    required String pickup,
    required String dropoff,
    required String distance,
    required double estimatedFare,
  }) {
    return Container(
      decoration: AppDecorations.cardElevated,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(pickup, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
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
                        const Icon(Icons.security, size: 16, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text('B2B Garantizado', style: GoogleFonts.inter(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_off, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(child: Text(dropoff, style: GoogleFonts.inter(color: AppColors.textSecondary))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(distance, style: GoogleFonts.inter(color: AppColors.textPrimary)),
                  ],
                ),
                Text(
                  'Tarifa: \$${estimatedFare.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.accentLime),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Contraofertar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorporate ? AppColors.accentLime : AppColors.info,
                      foregroundColor: AppColors.textOnAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isCorporate ? 'Aceptar' : 'Tomar Viaje'),
                  ),
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
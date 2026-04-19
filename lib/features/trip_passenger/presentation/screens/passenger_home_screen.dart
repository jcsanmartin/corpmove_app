import 'package:flutter/material.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/negotiation_radar_screen.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/map_placeholder.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/dual_mode_selector.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/profile_tab.dart';

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
  final double _techoCobertura = 15000.0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _isCorporateMode = widget.isCorporateEnabled;
  }

  late final List<Widget> _screens = [
    _buildHomeTab(),
    const _HistoryTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCorporateEnabled ? 'CorpMove - Empleado' : 'CorpMove',
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones')),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF1A237E)),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isCorporateEnabled ? 'Empleado CorpMove' : 'Usuario',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const Text(
                  'correo@ejemplo.com',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Mi cuenta'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        const MapPlaceholder(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search, color: Color(0xFF1A237E), size: 22),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '¿A dónde vamos?',
                        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  if (widget.isCorporateEnabled)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_isCorporateMode),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isCorporateMode ? Colors.orange.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 18,
                              color: _isCorporateMode ? Colors.orange.shade700 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isCorporateMode ? '\$${_techoCobertura.toStringAsFixed(0)}' : 'Efectivo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isCorporateMode ? Colors.orange.shade800 : Colors.grey.shade700,
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
        ),
        Positioned(
          right: 20,
          bottom: 200,
          child: FloatingActionButton(
            heroTag: 'location',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A237E),
            elevation: 4,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Centrando ubicación...'), duration: Duration(seconds: 1)),
              );
            },
            child: const Icon(Icons.my_location),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isCorporateEnabled)
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
                        Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Modo Personal',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NegotiationRadarScreen(
                            isCorporateMode: widget.isCorporateEnabled && _isCorporateMode,
                            techoCobertura: widget.isCorporateEnabled ? _techoCobertura : 0.0,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search, size: 22),
                    label: Text(
                      widget.isCorporateEnabled && _isCorporateMode
                          ? 'Buscar viaje corporativo'
                          : 'Buscar viaje personal',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (widget.isCorporateEnabled && _isCorporateMode)
                          ? const Color(0xFF1A237E)
                          : const Color(0xFFFF6D00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),
                if (widget.isCorporateEnabled && _isCorporateMode) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Techo de cobertura: \$${_techoCobertura.toStringAsFixed(0)} por viaje',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Historial de viajes', style: TextStyle(fontSize: 18)),
          Text('Próximamente...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
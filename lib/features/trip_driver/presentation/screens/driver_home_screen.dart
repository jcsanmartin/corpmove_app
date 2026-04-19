import 'package:flutter/material.dart';

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
    const _DriverProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Conductor'),
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
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
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFFFF6D00),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Viajes'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Ganancias'),
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
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFFF6D00)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFFFF6D00)),
                ),
                SizedBox(height: 10),
                Text('Conductor', style: TextStyle(color: Colors.white, fontSize: 18)),
                Text('conductor@corpmove.com', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Mi perfil'),
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
          Card(
            color: const Color(0xFF1A237E),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ganancias de hoy', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('\$85.000', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEarningChip('Efectivo', 35000, Colors.greenAccent),
                      _buildEarningChip('B2B Garantizado', 50000, Colors.orangeAccent),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text('\$$amount', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red[400]),
                const SizedBox(width: 8),
                Expanded(child: Text(pickup, style: const TextStyle(fontWeight: FontWeight.w500))),
                if (isCorporate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('B2B Garantizado', style: TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_off, color: Colors.blue[400]),
                const SizedBox(width: 8),
                Expanded(child: Text(dropoff)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, size: 18),
                    const SizedBox(width: 4),
                    Text(distance),
                  ],
                ),
                Text(
                  'Tarifa: \$${estimatedFare.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Contraofertar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorporate ? const Color(0xFFFF6D00) : const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
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
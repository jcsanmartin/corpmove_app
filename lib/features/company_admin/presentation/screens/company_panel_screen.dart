import 'package:flutter/material.dart';

class CompanyPanelScreen extends StatelessWidget {
  const CompanyPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Corporativo'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CorpMove Business',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestión de empleados y convenios',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            // Tarjeta de resumen
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Empleados', '24', Icons.people),
                  _buildStatCard('Viajes hoy', '47', Icons.directions_car),
                  _buildStatCard('Ahorro', '\$320k', Icons.savings),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Empleados afiliados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildEmployeeTile('Carlos Martínez', 'carlos.m@corpmove.com', true, 15000),
                  _buildEmployeeTile('Ana Pérez', 'ana.p@corpmove.com', true, 15000),
                  _buildEmployeeTile('Luis Díaz', 'luis.d@corpmove.com', false, 0),
                  _buildEmployeeTile('Marta López', 'marta.l@corpmove.com', true, 20000),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuración de convenios en desarrollo')),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configurar techos de cobertura'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEmployeeTile(String name, String email, bool isActive, double techo) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade200,
        child: Icon(
          Icons.person,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(email),
      trailing: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Techo: \$${techo.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            )
          : TextButton(
              onPressed: () {},
              child: const Text('Afiliar'),
            ),
    );
  }
}
import 'package:flutter/material.dart';

class CompanyAdminScreen extends StatelessWidget {
  const CompanyAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Corporativo'),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Resumen de empleados
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Empleados afiliados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Activos', '24', Colors.green),
                      _buildStat('Pendientes', '3', Colors.orange),
                      _buildStat('Inactivos', '2', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Configuración de techos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuración de Convenio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildConfigItem('Techo por viaje', '\$15.000'),
                  const Divider(),
                  _buildConfigItem('Viajes diarios máximos', '2'),
                  const Divider(),
                  _buildConfigItem('Horario permitido', '6:00 - 22:00'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Lista de empleados recientes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Empleados recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildEmployeeTile('Ana Pérez', 'ana.perez@corpmove.com', true),
                  _buildEmployeeTile('Carlos Martínez', 'carlos.m@corpmove.com', true),
                  _buildEmployeeTile('Laura Gómez', 'laura.g@corpmove.com', false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Botón de reportes
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generando reporte de facturación...')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar reporte de facturación'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- Drawer del Administrador ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF1A237E),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.business, size: 40, color: Color(0xFF1A237E)),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Empresa',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  'admin@empresa.com',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Empleados'),
            onTap: () {
              Navigator.pop(context);
              // Aquí podrías navegar a una vista de gestión de empleados
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gestión de empleados')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración de convenio'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración de techos y horarios')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reportes'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Descargar reportes')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context);
              // Regresar al login
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTile(String name, String email, bool isActive) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade200,
        child: Icon(
          Icons.person,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(name),
      subtitle: Text(email),
      trailing: Switch(
        value: isActive,
        onChanged: (_) {},
        activeColor: const Color(0xFF1A237E),
      ),
    );
  }
}
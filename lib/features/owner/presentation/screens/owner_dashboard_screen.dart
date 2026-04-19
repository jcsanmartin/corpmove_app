import 'package:flutter/material.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Dueño - CorpMove'),
        backgroundColor: Colors.black87, // Color distintivo para el Owner
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones globales')),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Métricas Globales',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Empresas', '12'),
                      _buildMetric('Usuarios', '1,250'),
                      _buildMetric('Conductores', '85'),
                      _buildMetric('Viajes Hoy', '342'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Empresas Afiliadas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildCompanyTile('CorpMove S.A.', 'admin@corpmove.com', true),
                  _buildCompanyTile('Tech Solutions', 'admin@tech.com', true),
                  _buildCompanyTile('Logística Express', 'admin@logex.com', false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuración Global',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Modo mantenimiento'),
                    value: false,
                    onChanged: (_) {},
                    activeColor: Colors.black87,
                  ),
                  SwitchListTile(
                    title: const Text('Habilitar registro público'),
                    value: true,
                    onChanged: (_) {},
                    activeColor: Colors.black87,
                  ),
                  ListTile(
                    title: const Text('Comisión por viaje'),
                    trailing: const Text('10%'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Drawer del Dueño ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black87,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.black87),
                ),
                SizedBox(height: 10),
                Text(
                  'Dueño - CorpMove',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  'owner@corpmove.com',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Empresas'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gestión de empresas')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Usuarios'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gestión de usuarios')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración global'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración de la plataforma')),
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

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildCompanyTile(String name, String email, bool active) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: active ? Colors.green.shade100 : Colors.grey.shade200,
        child: Icon(Icons.business, color: active ? Colors.green : Colors.grey),
      ),
      title: Text(name),
      subtitle: Text(email),
      trailing: Switch(
        value: active,
        onChanged: (_) {},
        activeColor: Colors.black87,
      ),
    );
  }
}
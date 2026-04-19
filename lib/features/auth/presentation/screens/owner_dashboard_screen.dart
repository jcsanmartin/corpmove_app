import 'package:flutter/material.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Dueño - CorpMove'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
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
                    activeColor: const Color(0xFF1A237E),
                  ),
                  SwitchListTile(
                    title: const Text('Habilitar registro público'),
                    value: true,
                    onChanged: (_) {},
                    activeColor: const Color(0xFF1A237E),
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

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
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
        activeColor: const Color(0xFF1A237E),
      ),
    );
  }
}
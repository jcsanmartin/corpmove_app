import 'package:flutter/material.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con perfil y ganancias
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=7'),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Juan Camilo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('En línea', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text('4.92', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tarjeta de ganancias
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF283593)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ganancias de hoy', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        const Text('\$85.000', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
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
                ],
              ),
            ),
            // Lista de viajes
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Viajes disponibles cerca', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  _buildTripCard(
                    context: context,
                    isCorporate: true,
                    pickup: 'Calle 100 #19-21',
                    dropoff: 'Calle 72 #9-55',
                    distance: '5.2 km',
                    estimatedFare: 22000,
                  ),
                  const SizedBox(height: 16),
                  _buildTripCard(
                    context: context,
                    isCorporate: false,
                    pickup: 'Carrera 15 #93-45',
                    dropoff: 'Avenida Chile #72-10',
                    distance: '3.8 km',
                    estimatedFare: 14000,
                  ),
                  const SizedBox(height: 16),
                  _buildTripCard(
                    context: context,
                    isCorporate: true,
                    pickup: 'Calle 80 #14-22',
                    dropoff: 'Calle 26 #5-90',
                    distance: '8.1 km',
                    estimatedFare: 31000,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningChip(String label, int amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Text('\$$amount', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildTripCard({
    required BuildContext context,
    required bool isCorporate,
    required String pickup,
    required String dropoff,
    required String distance,
    required double estimatedFare,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
        border: isCorporate ? Border.all(color: const Color(0xFFFF6D00), width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(pickup, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
                if (isCorporate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Text('B2B Garantizado', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_off, color: Colors.blue.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(dropoff, style: TextStyle(color: Colors.grey.shade700))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Tarifa: \$${estimatedFare.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contraoferta enviada')),
                      );
                    },
                    icon: const Icon(Icons.attach_money, size: 18),
                    label: const Text('Contraofertar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Viaje aceptado. Dirígete al punto de recogida.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(isCorporate ? 'Aceptar B2B' : 'Tomar viaje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorporate ? const Color(0xFFFF6D00) : const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
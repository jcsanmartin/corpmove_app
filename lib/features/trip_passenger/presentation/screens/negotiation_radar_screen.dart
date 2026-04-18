import 'package:flutter/material.dart';

class NegotiationRadarScreen extends StatelessWidget {
  const NegotiationRadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Cabecera personalizada
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conductores cercanos',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Calle 100 #19-21', style: TextStyle(color: Colors.grey)),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                          SizedBox(width: 12),
                          Icon(Icons.location_off, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Calle 72 #9-55', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Indicador de búsqueda
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00))),
                ),
                const SizedBox(width: 12),
                const Text('Buscando las mejores ofertas...', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('3 conductores', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // Lista de ofertas
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOfferCard(
                  context: context,
                  driverName: 'Carlos Martínez',
                  rating: 4.9,
                  vehicle: 'Hyundai i10 - HJK234',
                  arrival: '3 min',
                  offerAmount: 18000,
                  isRecommended: true,
                ),
                const SizedBox(height: 16),
                _buildOfferCard(
                  context: context,
                  driverName: 'Ana Pérez',
                  rating: 4.8,
                  vehicle: 'Renault Logan - XYZ789',
                  arrival: '5 min',
                  offerAmount: 22000,
                ),
                const SizedBox(height: 16),
                _buildOfferCard(
                  context: context,
                  driverName: 'Luis Díaz',
                  rating: 5.0,
                  vehicle: 'Kia Picanto - ABC123',
                  arrival: '7 min',
                  offerAmount: 12000,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard({
    required BuildContext context,
    required String driverName,
    required double rating,
    required String vehicle,
    required String arrival,
    required double offerAmount,
    bool isRecommended = false,
  }) {
    const double techoCorporativo = 15000.0;
    final bool superaTecho = offerAmount > techoCorporativo;
    final double pagaEmpresa = superaTecho ? techoCorporativo : offerAmount;
    final double excedente = superaTecho ? offerAmount - techoCorporativo : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: isRecommended ? Border.all(color: const Color(0xFFFF6D00), width: 1.5) : null,
      ),
      child: Stack(
        children: [
          if (isRecommended)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFFF6D00), size: 14),
                    SizedBox(width: 4),
                    Text('Recomendado', style: TextStyle(color: Color(0xFFFF6D00), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 32, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 2),
                                    Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(vehicle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(arrival, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Precio y desglose
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tarifa total', style: TextStyle(fontSize: 16)),
                          Text(
                            '\$${offerAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1A237E)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.business, size: 18, color: Color(0xFF1A237E)),
                              SizedBox(width: 6),
                              Text('Cubre CorpMove'),
                            ],
                          ),
                          Text(
                            '\$${pagaEmpresa.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E), fontSize: 16),
                          ),
                        ],
                      ),
                      if (superaTecho) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.credit_card, size: 18, color: Colors.orange),
                                SizedBox(width: 6),
                                Text('Excedente (tú pagas)'),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '\$${excedente.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contraoferta enviada al conductor')),
                          );
                        },
                        icon: const Icon(Icons.attach_money, size: 20),
                        label: const Text('Contraofertar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
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
                              content: Text('✅ Viaje aceptado. Conductor en camino.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text('Aceptar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
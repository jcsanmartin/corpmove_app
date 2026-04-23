import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final List<Map<String, dynamic>> _drivers = [
    {'name': 'Andrés Morales', 'phone': '+57 300 123 4567', 'active': true, 'rating': 4.8, 'trips': 312, 'vehicle': 'Toyota Corolla 2022', 'plate': 'ABC-123'},
    {'name': 'Felipe Torres', 'phone': '+57 311 987 6543', 'active': true, 'rating': 4.5, 'trips': 189, 'vehicle': 'Kia Rio 2023', 'plate': 'DEF-456'},
    {'name': 'Santiago Rivera', 'phone': '+57 320 456 7890', 'active': false, 'rating': 3.9, 'trips': 45, 'vehicle': 'Chevrolet Onix 2021', 'plate': 'GHI-789'},
    {'name': 'Diego Castillo', 'phone': '+57 315 321 0987', 'active': true, 'rating': 4.9, 'trips': 520, 'vehicle': 'Mazda 3 2023', 'plate': 'JKL-012'},
    {'name': 'Camila Vargas', 'phone': '+57 318 654 3210', 'active': true, 'rating': 4.7, 'trips': 275, 'vehicle': 'Renault Logan 2022', 'plate': 'MNO-345'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: Text('Gestión de Conductores', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDriverDialog(),
        backgroundColor: AppColors.accentLime,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('Nuevo Conductor', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stats
          Container(
            decoration: AppDecorations.cardElevated,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Resumen', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Row(children: [
                _stat('Total', '${_drivers.length}', Icons.directions_car_rounded, AppColors.info),
                const SizedBox(width: 10),
                _stat('Activos', '${_drivers.where((d) => d['active']).length}', Icons.check_circle_outline, AppColors.success),
                const SizedBox(width: 10),
                _stat('Inactivos', '${_drivers.where((d) => !d['active']).length}', Icons.cancel_outlined, AppColors.error),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Conductores', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...List.generate(_drivers.length, (i) => _buildDriverCard(i)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      ]),
    ),
  );

  Widget _buildDriverCard(int index) {
    final d = _drivers[index];
    final bool active = d['active'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDriverDetails(index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentLime.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.accentLime),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['name'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(d['vehicle'], style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text('${d['rating']}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13)),
                  ]),
                  const SizedBox(height: 4),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.success : AppColors.error),
                  ),
                ]),
              ]),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _miniInfo('Placa', d['plate']),
                _miniInfo('Viajes', '${d['trips']}'),
                _miniInfo('Teléfono', d['phone'].toString().substring(4)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
  ]);

  void _showDriverDetails(int index) {
    final d = _drivers[index];
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: AppDecorations.bottomSheet,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            CircleAvatar(radius: 30, backgroundColor: AppColors.accentLime.withOpacity(0.12), child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.accentLime, size: 30)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name'], style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Row(children: [
                const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                const SizedBox(width: 4),
                Text('${d['rating']}', style: GoogleFonts.inter(color: AppColors.textMuted)),
              ]),
            ])),
          ]),
          const SizedBox(height: 20),
          _row('Teléfono', d['phone']),
          _row('Vehículo', d['vehicle']),
          _row('Placa', d['plate']),
          _row('Viajes Realizados', '${d['trips']}'),
          _row('Estado', d['active'] ? 'Activo' : 'Inactivo'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(ctx); _showDriverDialog(index: index); }, icon: const Icon(Icons.edit_rounded), label: const Text('Editar'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(
              onPressed: () { setState(() => _drivers[index]['active'] = !_drivers[index]['active']); Navigator.pop(ctx); },
              icon: Icon(d['active'] ? Icons.block : Icons.check_circle_outline),
              label: Text(d['active'] ? 'Suspender' : 'Activar'),
            )),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () { Navigator.pop(ctx); setState(() => _drivers.removeAt(index)); },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('Eliminar Conductor', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ]),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.inter(color: AppColors.textMuted)),
      Text(v, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]),
  );

  void _showDriverDialog({int? index}) {
    final e = index != null ? _drivers[index] : null;
    final nameC = TextEditingController(text: e?['name'] ?? '');
    final phoneC = TextEditingController(text: e?['phone'] ?? '');
    final vehicleC = TextEditingController(text: e?['vehicle'] ?? '');
    final plateC = TextEditingController(text: e?['plate'] ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(e != null ? 'Editar Conductor' : 'Nuevo Conductor', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: phoneC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 12),
        TextField(controller: vehicleC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Vehículo', prefixIcon: Icon(Icons.directions_car_outlined))),
        const SizedBox(height: 12),
        TextField(controller: plateC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Placa', prefixIcon: Icon(Icons.confirmation_number_outlined))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () {
          setState(() {
            final data = {'name': nameC.text.isEmpty ? 'Sin nombre' : nameC.text, 'phone': phoneC.text.isEmpty ? 'N/A' : phoneC.text, 'vehicle': vehicleC.text.isEmpty ? 'N/A' : vehicleC.text, 'plate': plateC.text.isEmpty ? 'N/A' : plateC.text, 'active': e?['active'] ?? true, 'rating': e?['rating'] ?? 5.0, 'trips': e?['trips'] ?? 0};
            if (index != null) { _drivers[index] = data; } else { _drivers.add(data); }
          });
          Navigator.pop(ctx);
        }, child: Text(index != null ? 'Guardar' : 'Crear')),
      ],
    ));
  }
}

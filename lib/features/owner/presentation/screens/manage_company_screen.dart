import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageCompanyScreen extends StatefulWidget {
  const ManageCompanyScreen({super.key});

  @override
  State<ManageCompanyScreen> createState() => _ManageCompanyScreenState();
}

class _ManageCompanyScreenState extends State<ManageCompanyScreen> {
  final List<Map<String, dynamic>> _companies = [
    {'name': 'CorpMove S.A.', 'contact': 'admin@corpmove.com', 'active': true, 'commission': 10.0, 'employees': 142, 'tripsMonth': 850},
    {'name': 'Tech Solutions', 'contact': 'admin@tech.com', 'active': true, 'commission': 12.0, 'employees': 85, 'tripsMonth': 420},
    {'name': 'Logística Express', 'contact': 'admin@logex.com', 'active': false, 'commission': 8.5, 'employees': 60, 'tripsMonth': 0},
    {'name': 'Innovación Digital', 'contact': 'rrhh@innovacion.com', 'active': true, 'commission': 11.0, 'employees': 210, 'tripsMonth': 1100},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: Text('Gestión de Empresas', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCompanyDialog(),
        backgroundColor: AppColors.accentLime,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.add_business_rounded),
        label: Text('Nuevo Convenio', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSummaryRow(),
          const SizedBox(height: 24),
          Text('Convenios Corporativos', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...List.generate(_companies.length, (i) => _buildCompanyCard(i)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Container(
      decoration: AppDecorations.cardElevated,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildChip('Total', '${_companies.length}', AppColors.info),
          const SizedBox(width: 12),
          _buildChip('Activas', '${_companies.where((c) => c['active'] == true).length}', AppColors.success),
          const SizedBox(width: 12),
          _buildChip('Inactivas', '${_companies.where((c) => c['active'] == false).length}', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _buildCompanyCard(int index) {
    final c = _companies[index];
    final bool active = c['active'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: (active ? AppColors.success : AppColors.error).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.business_rounded, color: active ? AppColors.success : AppColors.error),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['name'], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(c['contact'], style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (active ? AppColors.success : AppColors.error).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(active ? 'Activo' : 'Inactivo', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: active ? AppColors.success : AppColors.error)),
                ),
              ]),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _miniStat('Empleados', '${c['employees']}'),
                _miniStat('Viajes/Mes', '${c['tripsMonth']}'),
                _miniStat('Comisión', '${c['commission']}%'),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
  ]);

  void _showDetails(int index) {
    final c = _companies[index];
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: AppDecorations.bottomSheet,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
          Text(c['name'], style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(c['contact'], style: GoogleFonts.inter(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          _detailRow('Empleados', '${c['employees']}'),
          _detailRow('Viajes del Mes', '${c['tripsMonth']}'),
          _detailRow('Comisión', '${c['commission']}%'),
          _detailRow('Estado', c['active'] ? 'Activo' : 'Inactivo'),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(ctx); _showCompanyDialog(index: index); }, icon: const Icon(Icons.edit_rounded), label: const Text('Editar'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(
              onPressed: () { setState(() => _companies[index]['active'] = !_companies[index]['active']); Navigator.pop(ctx); },
              icon: Icon(c['active'] ? Icons.pause_circle_outline : Icons.play_circle_outline),
              label: Text(c['active'] ? 'Desactivar' : 'Activar'),
            )),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () { Navigator.pop(ctx); setState(() => _companies.removeAt(index)); },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ]),
      ),
    );
  }

  Widget _detailRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.inter(color: AppColors.textMuted)),
      Text(v, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]),
  );

  void _showCompanyDialog({int? index}) {
    final existing = index != null ? _companies[index] : null;
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final contactC = TextEditingController(text: existing?['contact'] ?? '');
    final commC = TextEditingController(text: existing?['commission']?.toString() ?? '10.0');
    final empC = TextEditingController(text: existing?['employees']?.toString() ?? '0');
    // Nuevos campos para límites
    final techoC = TextEditingController(text: existing?['corporate_limit']?.toString() ?? '0');
    final dailyC = TextEditingController(text: existing?['daily_trips_limit']?.toString() ?? '0');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(existing != null ? 'Editar Convenio' : 'Nuevo Convenio', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Nombre de la Empresa', prefixIcon: Icon(Icons.business))),
        const SizedBox(height: 14),
        TextField(controller: contactC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Correo de Contacto', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 14),
        TextField(controller: commC, style: const TextStyle(color: AppColors.textPrimary), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Comisión (%)', prefixIcon: Icon(Icons.percent))),
        const SizedBox(height: 14),
        TextField(controller: empC, style: const TextStyle(color: AppColors.textPrimary), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nº Empleados', prefixIcon: Icon(Icons.people_outline))),
        const SizedBox(height: 14),
        TextField(controller: techoC, style: const TextStyle(color: AppColors.textPrimary), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Techo por Viaje (\$)', prefixIcon: Icon(Icons.attach_money))),
        const SizedBox(height: 14),
        TextField(controller: dailyC, style: const TextStyle(color: AppColors.textPrimary), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Viajes Diarios Máximos', prefixIcon: Icon(Icons.directions_car))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            final data = {
              'id': existing?['id'], // Asumimos que id vendrá de DB pronto
              'name': nameC.text.isEmpty ? 'Sin nombre' : nameC.text, 
              'contact': contactC.text.isEmpty ? 'sin@email.com' : contactC.text, 
              'active': existing?['active'] ?? true, 
              'commission': double.tryParse(commC.text) ?? 10.0, 
              'employees': int.tryParse(empC.text) ?? 0, 
              'tripsMonth': existing?['tripsMonth'] ?? 0,
              'corporate_limit': double.tryParse(techoC.text) ?? 0.0,
              'daily_trips_limit': int.tryParse(dailyC.text) ?? 0,
            };

            // UPDATE real a Supabase (si tiene ID)
            if (data['id'] != null) {
              try {
                await Supabase.instance.client
                    .from('companies')
                    .update({
                      'corporate_limit': data['corporate_limit'],
                      'daily_trips_limit': data['daily_trips_limit']
                    })
                    .eq('id', data['id']);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Límites actualizados en Supabase exitosamente')),
                );
              } catch (e) {
                debugPrint('Error updating Supabase: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error actualizando Supabase: $e')),
                );
              }
            }

            setState(() {
              if (index != null) { _companies[index] = data; } else { _companies.add(data); }
            });
            Navigator.pop(ctx);
          }, 
          child: Text(index != null ? 'Guardar' : 'Crear')
        ),
      ],
    ));
  }
}

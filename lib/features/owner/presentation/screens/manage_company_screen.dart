import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/owner/data/repositories/owner_supabase_repository.dart';

class ManageCompanyScreen extends StatefulWidget {
  const ManageCompanyScreen({super.key});

  @override
  State<ManageCompanyScreen> createState() => _ManageCompanyScreenState();
}

class _ManageCompanyScreenState extends State<ManageCompanyScreen> {
  final OwnerSupabaseRepository _repo = OwnerSupabaseRepository();

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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repo.streamCompanies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentLime));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
          }

          final companies = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSummaryRow(companies),
              const SizedBox(height: 24),
              Text('Convenios Corporativos', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              if (companies.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('No hay convenios registrados', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  ),
                )
              else
                ...List.generate(companies.length, (i) => _buildCompanyCard(companies[i])),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSummaryRow(List<Map<String, dynamic>> companies) {
    return Container(
      decoration: AppDecorations.cardElevated,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildChip('Total', '${companies.length}', AppColors.info),
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

  Widget _buildCompanyCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(c),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.business_rounded, color: AppColors.success),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['company_name'] ?? 'Sin nombre', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Registrada: ${c['created_at'].toString().split('T')[0]}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                ])),
              ]),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _miniStat('Techo', '\$${c['corporate_limit'] ?? 0}'),
                _miniStat('Viajes Diarios', '${c['daily_trips_limit'] ?? 2}'),
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

  void _showDetails(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: AppDecorations.bottomSheet,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
          Text(c['company_name'] ?? 'Sin nombre', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _detailRow('Techo por viaje', '\$${c['corporate_limit'] ?? 0}'),
          _detailRow('Límite viajes diarios', '${c['daily_trips_limit'] ?? 2}'),
          _detailRow('Horarios Permitidos', (c['allowed_schedules'] as List<dynamic>?)?.join(', ') ?? 'No definido'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () { 
              Navigator.pop(ctx); 
              _showCompanyDialog(existing: c); 
            }, 
            icon: const Icon(Icons.edit_rounded), 
            label: const Text('Editar')
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async { 
              Navigator.pop(ctx); 
              await _repo.deleteCompany(c['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa eliminada')));
              }
            },
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

  void _showCompanyDialog({Map<String, dynamic>? existing}) {
    final nameC = TextEditingController(text: existing?['company_name'] ?? '');
    final techoC = TextEditingController(text: existing?['corporate_limit']?.toString() ?? '0');
    final dailyC = TextEditingController(text: existing?['daily_trips_limit']?.toString() ?? '2');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(existing != null ? 'Editar Convenio' : 'Nuevo Convenio', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Nombre de la Empresa', prefixIcon: Icon(Icons.business))),
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
              'name': nameC.text.isEmpty ? 'Sin nombre' : nameC.text, 
              'corporate_limit': double.tryParse(techoC.text) ?? 0.0,
              'daily_trips_limit': int.tryParse(dailyC.text) ?? 2,
            };

            try {
              if (existing != null) {
                await _repo.updateCompany(existing['id'], data);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Convenio actualizado')));
              } else {
                await _repo.createCompany(data);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Convenio creado')));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }

            if (mounted) Navigator.pop(ctx);
          }, 
          child: Text(existing != null ? 'Guardar' : 'Crear')
        ),
      ],
    ));
  }
}


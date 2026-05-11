import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/owner/data/repositories/owner_supabase_repository.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> with SingleTickerProviderStateMixin {
  final OwnerSupabaseRepository _repo = OwnerSupabaseRepository();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: Text('Gestión de Conductores', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentLime,
          labelColor: AppColors.accentLime,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Solicitudes'),
            Tab(icon: Icon(Icons.directions_car_rounded), text: 'Registrados'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repo.streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentLime));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
          }

          final allUsers = snapshot.data ?? [];
          
          final pendingRequests = allUsers.where((u) => 
            u['estado_solicitud'] == 'pendiente' && 
            (u['rol_solicitado'] == 'driver' || u['rol_solicitado'] == 'conductor')
          ).toList();
          
          final activeDrivers = allUsers.where((u) => u['role'] == 'driver').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsTab(pendingRequests),
              _buildDriversTab(activeDrivers),
            ],
          );
        }
      ),
    );
  }

  Widget _buildRequestsTab(List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Text('No hay solicitudes pendientes', style: GoogleFonts.inter(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final r = requests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppDecorations.card,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.info.withOpacity(0.2),
                      backgroundImage: r['photo_url'] != null ? NetworkImage(r['photo_url']) : null,
                      child: r['photo_url'] == null ? const Icon(Icons.person, color: AppColors.info) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['display_name'] ?? 'Sin nombre', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text(r['email'] ?? 'Sin correo', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('Pendiente', style: GoogleFonts.inter(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                if (r['phone'] != null || r['vehicle'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 12),
                  if (r['phone'] != null) _miniInfo('Teléfono', r['phone']),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleRequest(r['id'], false),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                        child: Text('Rechazar', style: GoogleFonts.inter(color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleRequest(r['id'], true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                        child: Text('Aprobar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriversTab(List<Map<String, dynamic>> drivers) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: AppDecorations.cardElevated,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Resumen', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(children: [
              _stat('Total', '${drivers.length}', Icons.directions_car_rounded, AppColors.info),
              const SizedBox(width: 10),
              _stat('Activos', '${drivers.where((d) => d['is_active'] == true).length}', Icons.check_circle_outline, AppColors.success),
              const SizedBox(width: 10),
              _stat('Inactivos', '${drivers.where((d) => d['is_active'] == false).length}', Icons.cancel_outlined, AppColors.error),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Conductores Registrados', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (drivers.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No hay conductores', style: GoogleFonts.inter(color: AppColors.textMuted))))
        else
          ...List.generate(drivers.length, (i) => _buildDriverCard(drivers[i])),
      ],
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

  Widget _buildDriverCard(Map<String, dynamic> d) {
    final bool active = d['is_active'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDriverDetails(d),
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
                  Text(d['display_name'] ?? 'Sin nombre', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(d['email'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
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
                _miniInfo('Teléfono', d['phone'] ?? 'N/A'),
                _miniInfo('Estado', active ? 'Activo' : 'Inactivo'),
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

  void _showDriverDetails(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: AppDecorations.bottomSheet,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            CircleAvatar(radius: 30, backgroundColor: AppColors.accentLime.withOpacity(0.12), backgroundImage: d['photo_url'] != null ? NetworkImage(d['photo_url']) : null, child: d['photo_url'] == null ? const Icon(Icons.directions_car_filled_rounded, color: AppColors.accentLime, size: 30) : null),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['display_name'] ?? 'Sin nombre', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(d['email'] ?? '', style: GoogleFonts.inter(color: AppColors.textMuted)),
            ])),
          ]),
          const SizedBox(height: 20),
          _row('Teléfono', d['phone'] ?? 'N/A'),
          _row('Estado', (d['is_active'] ?? true) ? 'Activo' : 'Inactivo'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final newState = !(d['is_active'] ?? true);
                Navigator.pop(ctx);
                await _repo.toggleUserActiveStatus(d['id'], newState);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newState ? 'Conductor activado' : 'Conductor suspendido')));
              },
              icon: Icon((d['is_active'] ?? true) ? Icons.block : Icons.check_circle_outline),
              label: Text((d['is_active'] ?? true) ? 'Suspender' : 'Activar'),
            )),
          ]),
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

  Future<void> _handleRequest(String userId, bool approve) async {
    try {
      if (approve) {
        await _repo.approveDriverRequest(userId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conductor aprobado exitosamente')));
      } else {
        await _repo.rejectDriverRequest(userId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud rechazada')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

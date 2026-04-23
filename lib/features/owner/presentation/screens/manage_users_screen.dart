import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _normalUsers = [
    {'name': 'Carlos Pérez', 'email': 'carlos@gmail.com', 'active': true, 'trips': 45},
    {'name': 'Ana García', 'email': 'ana@gmail.com', 'active': true, 'trips': 32},
    {'name': 'Luis Rodríguez', 'email': 'luis@hotmail.com', 'active': false, 'trips': 12},
    {'name': 'María López', 'email': 'maria@gmail.com', 'active': true, 'trips': 78},
  ];

  final List<Map<String, dynamic>> _corpUsers = [
    {'name': 'Pedro Martínez', 'email': 'pedro@corpmove.com', 'active': true, 'trips': 120, 'company': 'CorpMove S.A.'},
    {'name': 'Laura Sánchez', 'email': 'laura@tech.com', 'active': true, 'trips': 95, 'company': 'Tech Solutions'},
    {'name': 'Roberto Díaz', 'email': 'roberto@logex.com', 'active': false, 'trips': 8, 'company': 'Logística Express'},
    {'name': 'Sofía Hernández', 'email': 'sofia@corpmove.com', 'active': true, 'trips': 67, 'company': 'CorpMove S.A.'},
  ];

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
        title: Text('Gestión de Usuarios', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
            Tab(icon: Icon(Icons.person_outline), text: 'Normales'),
            Tab(icon: Icon(Icons.business_center_outlined), text: 'Corporativos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(_tabController.index == 1),
        backgroundColor: AppColors.accentLime,
        foregroundColor: AppColors.textOnAccent,
        child: const Icon(Icons.person_add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_normalUsers, false),
          _buildUserList(_corpUsers, true),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, bool isCorp) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: users.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: AppDecorations.cardElevated,
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                _statBadge('Total', '${users.length}', AppColors.info),
                const SizedBox(width: 12),
                _statBadge('Activos', '${users.where((u) => u['active'] == true).length}', AppColors.success),
                const SizedBox(width: 12),
                _statBadge('Inactivos', '${users.where((u) => u['active'] == false).length}', AppColors.error),
              ]),
            ),
          );
        }
        return _buildUserCard(users[index - 1], index - 1, isCorp, users);
      },
    );
  }

  Widget _statBadge(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      ]),
    ),
  );

  Widget _buildUserCard(Map<String, dynamic> user, int index, bool isCorp, List<Map<String, dynamic>> list) {
    final bool active = user['active'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserDetails(user, index, isCorp, list),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (isCorp ? AppColors.accentLime : AppColors.info).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isCorp ? Icons.badge_rounded : Icons.person_rounded, color: isCorp ? AppColors.accentLime : AppColors.info),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user['name'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(user['email'], style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                if (isCorp && user['company'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.accentLime.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(user['company'], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accentLime)),
                  ),
                ],
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.success : AppColors.error),
                ),
                const SizedBox(height: 6),
                Text('${user['trips']} viajes', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user, int index, bool isCorp, List<Map<String, dynamic>> list) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: AppDecorations.bottomSheet,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            CircleAvatar(radius: 28, backgroundColor: AppColors.accentLime.withOpacity(0.12), child: Icon(isCorp ? Icons.badge_rounded : Icons.person_rounded, color: AppColors.accentLime, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user['name'], style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(user['email'], style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
            ])),
          ]),
          const SizedBox(height: 20),
          _infoRow('Tipo', isCorp ? 'Corporativo' : 'Normal'),
          _infoRow('Estado', user['active'] ? 'Activo' : 'Inactivo'),
          _infoRow('Viajes', '${user['trips']}'),
          if (isCorp && user['company'] != null) _infoRow('Empresa', user['company']),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(ctx); _showUserDialog(isCorp, index: index, list: list); },
              icon: const Icon(Icons.edit_rounded), label: const Text('Editar'),
            )),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(
              onPressed: () { setState(() => list[index]['active'] = !list[index]['active']); Navigator.pop(ctx); },
              icon: Icon(user['active'] ? Icons.block : Icons.check_circle_outline),
              label: Text(user['active'] ? 'Desactivar' : 'Activar'),
            )),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () { Navigator.pop(ctx); setState(() => list.removeAt(index)); },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('Eliminar Usuario', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ]),
      ),
    );
  }

  Widget _infoRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.inter(color: AppColors.textMuted)),
      Text(v, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]),
  );

  void _showUserDialog(bool isCorp, {int? index, List<Map<String, dynamic>>? list}) {
    final targetList = list ?? (isCorp ? _corpUsers : _normalUsers);
    final existing = index != null ? targetList[index] : null;
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final emailC = TextEditingController(text: existing?['email'] ?? '');
    final compC = TextEditingController(text: existing?['company'] ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(existing != null ? 'Editar Usuario' : 'Nuevo Usuario', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 14),
        TextField(controller: emailC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined))),
        if (isCorp) ...[
          const SizedBox(height: 14),
          TextField(controller: compC, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Empresa', prefixIcon: Icon(Icons.business))),
        ],
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () {
          setState(() {
            final data = {'name': nameC.text.isEmpty ? 'Sin nombre' : nameC.text, 'email': emailC.text.isEmpty ? 'sin@email.com' : emailC.text, 'active': existing?['active'] ?? true, 'trips': existing?['trips'] ?? 0};
            if (isCorp) data['company'] = compC.text.isEmpty ? 'Sin empresa' : compC.text;
            if (index != null) { targetList[index] = data; } else { targetList.add(data); }
          });
          Navigator.pop(ctx);
        }, child: Text(index != null ? 'Guardar' : 'Crear')),
      ],
    ));
  }
}

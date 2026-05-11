import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/owner/data/repositories/owner_supabase_repository.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with SingleTickerProviderStateMixin {
  final OwnerSupabaseRepository _repo = OwnerSupabaseRepository();
  late TabController _tabController;
  Map<String, String> _companyNames = {};
  String? _selectedCompanyIdFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final names = await _repo.getCompanyNamesMap();
    if (mounted) {
      setState(() {
        _companyNames = names;
      });
    }
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
          
          final normalUsers = allUsers.where((u) => u['company_id'] == null && u['role'] != 'driver' && u['role'] != 'owner').toList();
          final corpUsers = allUsers.where((u) => u['company_id'] != null && u['role'] != 'driver' && u['role'] != 'owner').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildUserList(normalUsers, false),
              _buildCorpList(corpUsers),
            ],
          );
        }
      ),
    );
  }

  Widget _buildCorpList(List<Map<String, dynamic>> allCorpUsers) {
    // Aplicar filtro si existe
    final filteredUsers = _selectedCompanyIdFilter == null 
        ? allCorpUsers 
        : allCorpUsers.where((u) => u['company_id'] == _selectedCompanyIdFilter).toList();

    return Column(
      children: [
        // Filtro
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: AppColors.surfaceLight,
          child: Row(
            children: [
              const Icon(Icons.filter_list_rounded, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedCompanyIdFilter,
                    hint: Text('Filtrar por Empresa', style: GoogleFonts.inter(color: AppColors.textMuted)),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas las empresas'),
                      ),
                      ..._companyNames.entries.map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCompanyIdFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderSubtle),
        Expanded(child: _buildUserList(filteredUsers, true)),
      ],
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
                _statBadge('Activos', '${users.where((u) => (u['is_active'] ?? true) == true).length}', AppColors.success),
                const SizedBox(width: 12),
                _statBadge('Inactivos', '${users.where((u) => (u['is_active'] ?? true) == false).length}', AppColors.error),
              ]),
            ),
          );
        }
        
        final user = users[index - 1];
        if (isCorp && user['company_id'] != null && !_companyNames.containsKey(user['company_id'])) {
          _loadCompanies(); // recargar si hay nueva
        }
        
        return _buildUserCard(user, isCorp);
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

  Widget _buildUserCard(Map<String, dynamic> user, bool isCorp) {
    final bool active = user['is_active'] ?? true;
    final companyName = isCorp && user['company_id'] != null ? _companyNames[user['company_id']] ?? 'Cargando...' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserDetails(user, isCorp, companyName),
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
                Text(user['display_name'] ?? 'Sin nombre', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(user['email'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                if (isCorp && companyName != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.accentLime.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(companyName, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accentLime)),
                  ),
                ],
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.success : AppColors.error),
                ),
                const SizedBox(height: 6),
                Text(active ? 'Activo' : 'Inactivo', style: GoogleFonts.inter(fontSize: 11, color: active ? AppColors.success : AppColors.error)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user, bool isCorp, String? companyName) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: AppDecorations.bottomSheet,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            CircleAvatar(
              radius: 28, 
              backgroundColor: AppColors.accentLime.withOpacity(0.12), 
              backgroundImage: user['photo_url'] != null ? NetworkImage(user['photo_url']) : null,
              child: user['photo_url'] == null ? Icon(isCorp ? Icons.badge_rounded : Icons.person_rounded, color: AppColors.accentLime, size: 28) : null,
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user['display_name'] ?? 'Sin nombre', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(user['email'] ?? '', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
            ])),
          ]),
          const SizedBox(height: 20),
          _infoRow('Tipo', isCorp ? 'Corporativo' : 'Normal'),
          _infoRow('Estado', (user['is_active'] ?? true) ? 'Activo' : 'Inactivo'),
          if (isCorp && companyName != null) _infoRow('Empresa', companyName),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () async { 
                final newState = !(user['is_active'] ?? true);
                Navigator.pop(ctx);
                await _repo.toggleUserActiveStatus(user['id'], newState);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newState ? 'Usuario activado' : 'Usuario desactivado')));
              },
              icon: Icon((user['is_active'] ?? true) ? Icons.block : Icons.check_circle_outline),
              label: Text((user['is_active'] ?? true) ? 'Desactivar' : 'Activar'),
            )),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async { 
              Navigator.pop(ctx); 
              await _repo.deleteUser(user['id']);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
            },
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
}

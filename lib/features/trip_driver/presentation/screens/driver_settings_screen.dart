import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'es';
  String _displayName = '';
  String _email = '';

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  final Map<String, String> _languageLabels = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadSettings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    _notificationsEnabled = prefs.getBool('driver_notifications_enabled') ?? true;
    _selectedLanguage = prefs.getString('driver_app_language') ?? 'es';

    if (user != null) {
      _email = user.email ?? '';
      _displayName = user.displayName?.isNotEmpty == true
          ? user.displayName!
          : (_email.isNotEmpty ? _email.split('@').first : 'Conductor');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  // ── Notificaciones ──────────────────────────────────────
  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_notifications_enabled', value);
  }

  // ── Idioma ──────────────────────────────────────────────
  Future<void> _changeLanguage(String? lang) async {
    if (lang == null) return;
    setState(() => _selectedLanguage = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_app_language', lang);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Idioma cambiado a ${_languageLabels[lang]}'),
        backgroundColor: AppColors.info,
      ));
    }
  }

  // ── Editar nombre de cuenta ─────────────────────────────
  Future<void> _editAccountName() async {
    final ctrl = TextEditingController(text: _displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar nombre',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nombre de la cuenta',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Guardar',
                style: GoogleFonts.inter(
                    color: AppColors.accentLime,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _auth.currentUser?.updateDisplayName(result);
        setState(() => _displayName = result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Nombre actualizado'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }

  // ── Bottom sheets informativos ──────────────────────────
  void _openTerms() => _showInfoSheet(
        title: 'Términos y Condiciones',
        icon: Icons.gavel_rounded,
        sections: const [
          _InfoItem('1. Aceptación',
              'Al usar CorpMove como conductor aceptas los presentes términos.'),
          _InfoItem('2. Uso del servicio',
              'Debes cumplir con la normatividad de transporte vigente.'),
          _InfoItem('3. Comisiones',
              'CorpMove aplica una comisión sobre cada viaje completado.'),
          _InfoItem('4. Privacidad',
              'Tus datos se manejan según nuestra política de privacidad y legislación colombiana.'),
        ],
      );

  void _openSupport() => _showInfoSheet(
        title: 'Soporte',
        icon: Icons.support_agent_rounded,
        sections: const [
          _InfoItem('¿Problemas con un viaje?',
              'Escribe a soporte@corpmove.com con el número de viaje.'),
          _InfoItem('Horario de atención',
              'Lunes a viernes de 8:00 a.m. a 6:00 p.m.'),
          _InfoItem('Teléfono',
              '+57 300 000 0000'),
          _InfoItem('Chat en línea',
              'Disponible desde la app principal en la sección de ayuda.'),
        ],
      );

  void _openAbout() => _showInfoSheet(
        title: 'Acerca de CorpMove',
        icon: Icons.info_outline_rounded,
        sections: const [
          _InfoItem('Versión', '1.0.0 (build 1)'),
          _InfoItem('Empresa', 'CorpMove S.A.S.'),
          _InfoItem('Misión',
              'Conectar conductores y empresas para un transporte corporativo seguro y eficiente.'),
          _InfoItem('Contacto', 'info@corpmove.com'),
        ],
      );

  void _showInfoSheet({
    required String title,
    required IconData icon,
    required List<_InfoItem> sections,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.borderAccent,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Icon(icon, color: AppColors.accentLime, size: 26),
                const SizedBox(width: 12),
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 20),
              ...sections.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title,
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(s.body,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Eliminar cuenta ─────────────────────────────────────
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar cuenta?',
            style: GoogleFonts.inter(
                color: AppColors.error, fontWeight: FontWeight.w700)),
        content: Text(
          'Esta acción es irreversible. Se eliminarán todos tus datos y no podrás recuperar tu cuenta.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text('Eliminar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _auth.currentUser?.delete();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Para eliminar la cuenta vuelve a iniciar sesión e inténtalo de nuevo.'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Configuración',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentLime))
          : FadeTransition(
              opacity: _fadeIn,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // ── Cuenta ─────────────────────────
                  _sectionLabel('Cuenta'),
                  const SizedBox(height: 12),
                  _buildAccountTile(),
                  const SizedBox(height: 28),

                  // ── Preferencias ───────────────────
                  _sectionLabel('Preferencias'),
                  const SizedBox(height: 12),
                  _buildNotificationTile(),
                  const SizedBox(height: 10),
                  _buildLanguageTile(),
                  const SizedBox(height: 28),

                  // ── Información ────────────────────
                  _sectionLabel('Información'),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    icon: Icons.gavel_rounded,
                    iconColor: AppColors.info,
                    label: 'Términos y condiciones',
                    onTap: _openTerms,
                  ),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    icon: Icons.support_agent_rounded,
                    iconColor: AppColors.warning,
                    label: 'Soporte',
                    onTap: _openSupport,
                  ),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.textMuted,
                    label: 'Acerca de',
                    onTap: _openAbout,
                  ),
                  const SizedBox(height: 32),

                  // ── Zona peligrosa ─────────────────
                  _sectionLabel('Zona de peligro'),
                  const SizedBox(height: 12),
                  _buildDangerTile(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Widgets ────────────────────────────────────────────

  Widget _sectionLabel(String t) => Text(
        t.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.4),
      );

  Widget _buildAccountTile() {
    return Container(
      decoration: AppDecorations.card,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.accentLime.withOpacity(0.15),
          child: Text(
            _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.accentLime),
          ),
        ),
        title: Text(_displayName,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary)),
        subtitle: Text(_email,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textMuted)),
        trailing: IconButton(
          tooltip: 'Editar nombre',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accentLime.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_rounded,
                size: 16, color: AppColors.accentLime),
          ),
          onPressed: _editAccountName,
        ),
      ),
    );
  }

  Widget _buildNotificationTile() {
    return Container(
      decoration: AppDecorations.card,
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        activeColor: AppColors.accentLime,
        inactiveTrackColor: AppColors.borderAccent,
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accentLime.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _notificationsEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: AppColors.accentLime,
            size: 22,
          ),
        ),
        title: Text('Notificaciones',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text(
          _notificationsEnabled ? 'Activadas' : 'Desactivadas',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        value: _notificationsEnabled,
        onChanged: _toggleNotifications,
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      decoration: AppDecorations.card,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.language_rounded,
              color: AppColors.info, size: 22),
        ),
        title: Text('Idioma',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: AppColors.cardElevated,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textMuted, size: 20),
              items: _languageLabels.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: _changeLanguage,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppDecorations.card,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_forever_rounded,
              color: AppColors.error, size: 22),
        ),
        title: Text('Eliminar cuenta',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.error)),
        subtitle: Text('Esta acción no se puede deshacer',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.error.withOpacity(0.7))),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.error),
        onTap: _deleteAccount,
      ),
    );
  }
}

// ── Modelo de sección informativa ──────────────────────────
class _InfoItem {
  final String title;
  final String body;
  const _InfoItem(this.title, this.body);
}

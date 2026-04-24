import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class PassengerSettingsScreen extends StatefulWidget {
  const PassengerSettingsScreen({super.key});

  @override
  State<PassengerSettingsScreen> createState() =>
      _PassengerSettingsScreenState();
}

class _PassengerSettingsScreenState extends State<PassengerSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'es';
  String _displayName = 'Usuario';
  String _email = '';
  String? _photoUrl;

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
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
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

    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _selectedLanguage = prefs.getString('app_language') ?? 'es';

    if (user != null) {
      _email = user.email ?? '';
      _photoUrl = user.photoURL;

      try {
        final data = await _supabase
            .from('users')
            .select('display_name, photo_url')
            .eq('firebase_uid', user.uid)
            .maybeSingle();

        if (data != null) {
          _displayName = data['display_name'] ?? user.displayName ?? 'Usuario';
          _photoUrl = data['photo_url'] ?? _photoUrl;
        } else {
          _displayName = user.displayName ?? 'Usuario';
        }
      } catch (_) {
        _displayName = user.displayName ?? 'Usuario';
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  // ── Cambiar foto de perfil ───────────────────────────
  Future<void> _changeProfilePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fileBytes = await File(picked.path).readAsBytes();
      final filePath = 'avatars/${user.uid}.jpg';

      await _supabase.storage
          .from('profile-photos')
          .uploadBinary(filePath, fileBytes,
              fileOptions: const FileOptions(upsert: true));

      final publicUrl =
          _supabase.storage.from('profile-photos').getPublicUrl(filePath);

      await _supabase
          .from('users')
          .update({'photo_url': publicUrl}).eq('firebase_uid', user.uid);

      await user.updatePhotoURL(publicUrl);

      setState(() => _photoUrl = publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto de perfil actualizada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Notificaciones ───────────────────────────────────
  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  // ── Idioma ───────────────────────────────────────────
  Future<void> _changeLanguage(String? lang) async {
    if (lang == null) return;
    setState(() => _selectedLanguage = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Idioma cambiado a ${_languageLabels[lang]}'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  // ── Diálogos informativos ────────────────────────────
  void _openHelpCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        title: 'Centro de Ayuda',
        icon: Icons.support_agent_rounded,
        sections: const [
          _InfoSection(
            title: '¿Cómo solicitar un viaje?',
            body:
                'Desde la pantalla principal, toca "¿A dónde y por cuánto?" para buscar tu destino y solicitar un viaje.',
          ),
          _InfoSection(
            title: '¿Cómo cambio mi método de pago?',
            body:
                'Ve a tu perfil y selecciona "Métodos de pago" para añadir o modificar tarjetas.',
          ),
          _InfoSection(
            title: 'Contacto de soporte',
            body:
                'Envía un correo a soporte@corpmove.com o llama al +57 300 000 0000.',
          ),
        ],
      ),
    );
  }

  void _openTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        title: 'Términos y Condiciones',
        icon: Icons.gavel_rounded,
        sections: const [
          _InfoSection(
            title: '1. Aceptación de términos',
            body:
                'Al utilizar CorpMove, aceptas los presentes términos y condiciones que rigen el uso de la plataforma.',
          ),
          _InfoSection(
            title: '2. Uso del servicio',
            body:
                'El servicio está destinado exclusivamente al transporte de pasajeros dentro de las zonas habilitadas.',
          ),
          _InfoSection(
            title: '3. Privacidad',
            body:
                'Tus datos personales se manejan conforme a nuestra política de privacidad y la legislación colombiana vigente.',
          ),
          _InfoSection(
            title: '4. Responsabilidades',
            body:
                'CorpMove actúa como intermediario tecnológico entre conductores y pasajeros.',
          ),
        ],
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuración',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
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
                  // ── Avatar + info ──────────────────
                  _buildProfileHeader(),
                  const SizedBox(height: 32),

                  // ── Sección Preferencias ───────────
                  _sectionTitle('Preferencias'),
                  const SizedBox(height: 12),
                  _buildNotificationTile(),
                  const SizedBox(height: 10),
                  _buildLanguageTile(),
                  const SizedBox(height: 32),

                  // ── Sección Soporte ────────────────
                  _sectionTitle('Soporte'),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    icon: Icons.support_agent_rounded,
                    label: 'Centro de ayuda',
                    onTap: _openHelpCenter,
                  ),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    icon: Icons.gavel_rounded,
                    label: 'Términos y condiciones',
                    onTap: _openTermsAndConditions,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ── Widgets internos ─────────────────────────────────

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.cardElevated,
      child: Column(
        children: [
          GestureDetector(
            onTap: _changeProfilePhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.accentLime, AppColors.accentLimeDark],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage:
                        _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null
                        ? Text(
                            _displayName.isNotEmpty
                                ? _displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          )
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.accentLime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 18, color: AppColors.textOnAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _displayName,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _email,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
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
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textMuted),
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
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value)))
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
            color: AppColors.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.warning, size: 22),
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
}

// ══════════════════════════════════════════════════════════
//  Widgets auxiliares
// ══════════════════════════════════════════════════════════

class _PhotoSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cambiar foto de perfil',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded,
                color: AppColors.accentLime),
            title: Text('Tomar foto',
                style: GoogleFonts.inter(color: AppColors.textPrimary)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_library_rounded, color: AppColors.info),
            title: Text('Elegir de galería',
                style: GoogleFonts.inter(color: AppColors.textPrimary)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet informativo reutilizable ───────────────
class _InfoSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoSection> sections;

  const _InfoSheet({
    required this.title,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(icon, color: AppColors.accentLime, size: 28),
                const SizedBox(width: 12),
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 24),
            ...sections.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
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
    );
  }
}

class _InfoSection {
  final String title;
  final String body;
  const _InfoSection({required this.title, required this.body});
}

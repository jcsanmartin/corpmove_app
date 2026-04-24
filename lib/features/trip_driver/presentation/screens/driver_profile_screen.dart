import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _supabase = Supabase.instance.client;

  // ── Estado ─────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;  // ← controla modo lectura / edición

  String _displayName = '';
  String _email = '';
  String? _photoUrl;

  // Datos del conductor
  String _cedula = '';
  String _vehicleBrand = '';
  String _vehicleModel = '';
  String _licensePlate = '';

  // Controllers
  final _nameCtrl    = TextEditingController();
  final _cedulaCtrl  = TextEditingController();
  final _brandCtrl   = TextEditingController();
  final _modelCtrl   = TextEditingController();
  final _plateCtrl   = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cedulaCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Carga datos ────────────────────────────────────────
  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _email = user.email ?? '';
    _photoUrl = user.photoURL;

    try {
      final userData = await _supabase
          .from('users')
          .select('display_name, photo_url, cedula')
          .eq('firebase_uid', user.uid)
          .maybeSingle();

      if (userData != null) {
        _displayName = userData['display_name'] ?? user.displayName ?? '';
        _photoUrl    = userData['photo_url'] ?? _photoUrl;
        _cedula      = userData['cedula'] ?? '';
      } else {
        _displayName = user.displayName ?? '';
      }

      final driverData = await _supabase
          .from('drivers')
          .select('vehicle_brand, vehicle_model, license_plate')
          .eq('firebase_uid', user.uid)
          .maybeSingle();

      if (driverData != null) {
        _vehicleBrand = driverData['vehicle_brand'] ?? '';
        _vehicleModel = driverData['vehicle_model'] ?? '';
        _licensePlate = driverData['license_plate'] ?? '';
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }

    _syncControllers();
    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  void _syncControllers() {
    _nameCtrl.text   = _displayName;
    _cedulaCtrl.text = _cedula;
    _brandCtrl.text  = _vehicleBrand;
    _modelCtrl.text  = _vehicleModel;
    _plateCtrl.text  = _licensePlate;
  }

  // ── Activar / desactivar edición ───────────────────────
  void _startEditing() => setState(() => _isEditing = true);

  void _cancelEditing() {
    _syncControllers(); // restaura valores originales
    setState(() => _isEditing = false);
    FocusScope.of(context).unfocus();
  }

  // ── Cambiar foto (solo en modo edición) ────────────────
  Future<void> _changePhoto() async {
    if (!_isEditing) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final bytes    = await File(picked.path).readAsBytes();
      final filePath = 'avatars/driver_${user.uid}.jpg';

      await _supabase.storage
          .from('profile-photos')
          .uploadBinary(filePath, bytes,
              fileOptions: const FileOptions(upsert: true));

      final publicUrl =
          _supabase.storage.from('profile-photos').getPublicUrl(filePath);

      await _supabase
          .from('users')
          .update({'photo_url': publicUrl}).eq('firebase_uid', user.uid);

      await user.updatePhotoURL(publicUrl);
      setState(() => _photoUrl = publicUrl);
      _showSnack('✅ Foto actualizada', AppColors.success);
    } catch (e) {
      _showSnack('Error al subir foto: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Guardar cambios ────────────────────────────────────
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await _supabase.from('users').update({
        'display_name': _nameCtrl.text.trim(),
        'cedula':       _cedulaCtrl.text.trim(),
      }).eq('firebase_uid', user.uid);

      await _supabase.from('drivers').upsert({
        'firebase_uid':  user.uid,
        'vehicle_brand': _brandCtrl.text.trim(),
        'vehicle_model': _modelCtrl.text.trim(),
        'license_plate': _plateCtrl.text.trim().toUpperCase(),
      }, onConflict: 'firebase_uid');

      await user.updateDisplayName(_nameCtrl.text.trim());

      setState(() {
        _displayName  = _nameCtrl.text.trim();
        _cedula       = _cedulaCtrl.text.trim();
        _vehicleBrand = _brandCtrl.text.trim();
        _vehicleModel = _modelCtrl.text.trim();
        _licensePlate = _plateCtrl.text.trim().toUpperCase();
        _plateCtrl.text = _licensePlate;
        _isEditing = false;
      });

      _showSnack('✅ Perfil guardado correctamente', AppColors.success);
    } catch (e) {
      _showSnack('Error al guardar: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
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
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _isEditing) ...[
            // Cancelar
            TextButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: Text('Cancelar',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
            ),
            // Guardar
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accentLime),
                    )
                  : Text('Guardar',
                      style: GoogleFonts.inter(
                          color: AppColors.accentLime,
                          fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      // ── Botón flotante Editar (solo cuando NO está editando) ──
      floatingActionButton: (!_isLoading && !_isEditing)
          ? FloatingActionButton.extended(
              heroTag: 'edit_profile',
              onPressed: _startEditing,
              backgroundColor: AppColors.accentLime,
              foregroundColor: AppColors.textOnAccent,
              icon: const Icon(Icons.edit_rounded),
              label: Text('Editar perfil',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentLime))
          : FadeTransition(
              opacity: _fadeIn,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 32),

                  // ── Datos Personales ────────────────
                  _sectionLabel('Datos Personales'),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    label: 'Nombre completo',
                    icon: Icons.person_rounded,
                    controller: _nameCtrl,
                    value: _displayName,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTile(
                    label: 'Número de cédula',
                    icon: Icons.badge_rounded,
                    controller: _cedulaCtrl,
                    value: _cedula,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 10),
                  // Email siempre solo lectura
                  _buildReadonlyTile(
                    label: 'Correo electrónico',
                    icon: Icons.email_rounded,
                    value: _email,
                  ),
                  const SizedBox(height: 28),

                  // ── Vehículo ────────────────────────
                  _sectionLabel('Información del Vehículo'),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    label: 'Marca',
                    icon: Icons.directions_car_rounded,
                    controller: _brandCtrl,
                    value: _vehicleBrand,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTile(
                    label: 'Modelo',
                    icon: Icons.car_repair_rounded,
                    controller: _modelCtrl,
                    value: _vehicleModel,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTile(
                    label: 'Placa',
                    icon: Icons.pin_rounded,
                    controller: _plateCtrl,
                    value: _licensePlate,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(7),
                      _UpperCaseFormatter(),
                    ],
                  ),
                  // Espacio para que el FAB no tape contenido
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────
  Widget _buildAvatar() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _changePhoto : null,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isEditing
                          ? [AppColors.accentLime, AppColors.accentLimeDark]
                          : [AppColors.borderAccent, AppColors.borderSubtle],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage:
                        _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null
                        ? Text(
                            _displayName.isNotEmpty
                                ? _displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted),
                          )
                        : null,
                  ),
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                        color: AppColors.accentLime, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 18, color: AppColors.textOnAccent),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _displayName.isNotEmpty ? _displayName : 'Conductor',
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (_isEditing ? AppColors.accentLime : AppColors.warning)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: (_isEditing ? AppColors.accentLime : AppColors.warning)
                      .withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isEditing ? Icons.edit_rounded : Icons.verified_rounded,
                  size: 14,
                  color: _isEditing ? AppColors.accentLime : AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  _isEditing ? 'Editando perfil' : 'Conductor CorpMove',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isEditing
                          ? AppColors.accentLime
                          : AppColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Campo de información (lectura o edición según _isEditing) ──
  Widget _buildInfoTile({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String value,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> inputFormatters = const [],
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEditing ? AppColors.accentLime.withOpacity(0.5) : AppColors.borderSubtle,
          width: _isEditing ? 1.5 : 1,
        ),
      ),
      child: _isEditing
          // ── Modo edición: TextField ──────────────
          ? TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.inter(
                    color: AppColors.accentLime.withOpacity(0.8), fontSize: 13),
                prefixIcon:
                    Icon(icon, color: AppColors.accentLime, size: 20),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            )
          // ── Modo lectura: ListTile ───────────────
          : ListTile(
              leading: Icon(icon, color: AppColors.textMuted, size: 20),
              title: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textMuted)),
              subtitle: Text(
                value.isNotEmpty ? value : '—',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary),
              ),
            ),
    );
  }

  // ── Campo siempre solo lectura (email) ─────────────────
  Widget _buildReadonlyTile({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textMuted, size: 20),
        title: Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
        subtitle: Text(
          value.isNotEmpty ? value : '—',
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(8)),
          child: Text('Solo lectura',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.4),
    );
  }
}

// ── Formatter: placa en mayúsculas ─────────────────────────
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) =>
      newVal.copyWith(text: newVal.text.toUpperCase());
}

// ── Bottom sheet: fuente de imagen ─────────────────────────
class _PhotoSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24)),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.camera_alt_rounded,
                color: AppColors.accentLime),
            title: Text('Tomar foto',
                style: GoogleFonts.inter(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.photo_library_rounded,
                color: AppColors.info),
            title: Text('Elegir de galería',
                style: GoogleFonts.inter(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

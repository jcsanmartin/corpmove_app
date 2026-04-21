import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:corpmove_app/core/services/auth_service.dart';
import 'package:corpmove_app/core/utils/user_role.dart';

class CorporateRequestDialog extends StatefulWidget {
  const CorporateRequestDialog({super.key});

  @override
  State<CorporateRequestDialog> createState() => _CorporateRequestDialogState();
}

class _CorporateRequestDialogState extends State<CorporateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController(); // Cargo en la empresa

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  String? _selectedCompanyId;
  String? _selectedCompanyName;

  @override
  void initState() {
    super.initState();
    // Prellenar con el nombre actual si existe
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50,
        maxWidth: 300,
        maxHeight: 300,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('corporate_requests').child('$uid.jpg');
      UploadTask uploadTask;
      
      if (kIsWeb) {
        final bytes = await _imageFile!.readAsBytes();
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        uploadTask = ref.putFile(File(_imageFile!.path));
      }
      
      // Añadimos un timeout de 5 segundos para evitar que se congele (por ej. problemas de CORS en Web)
      final snapshot = await uploadTask.timeout(const Duration(seconds: 5));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      return null;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una foto de perfil.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una empresa.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      // 1. Subir la imagen (Intentará Storage primero, pero como no hay, fallará)
      String? photoUrl = await _uploadImage(user.uid);

      if (photoUrl == null && _imageFile != null) {
        // Solución Definitiva (Sin tarjeta de crédito): Convertir foto a Base64
        // Esto guarda la foto real directamente en la base de datos Firestore.
        final bytes = await _imageFile!.readAsBytes();
        final base64String = base64Encode(bytes);
        photoUrl = 'data:image/jpeg;base64,$base64String';
      }

      if (photoUrl == null) {
        throw Exception("No se pudo procesar la imagen.");
      }

      // 2. Enviar la solicitud a Firestore
      await _authService.solicitarCambioRol(
        rolSolicitado: UserRole.employee,
        datosAdicionales: {
          'company_id': _selectedCompanyId,
          'company_name': _selectedCompanyName,
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'position': _positionController.text.trim(),
          'photo_url': photoUrl,
          'notas': 'Solicitud de asociación corporativa',
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar solicitud: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, color: Color(0xFF0F172A), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Afiliación Corporativa',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa tus datos para solicitar el beneficio a tu empresa.',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),

                // 📸 Selector de Foto
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _imageFile != null 
                            ? (kIsWeb ? NetworkImage(_imageFile!.path) : FileImage(File(_imageFile!.path)) as ImageProvider)
                            : null,
                        child: _imageFile == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _isLoading ? null : _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB), // Blue 600
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🏢 Dropdown de Empresas (StreamBuilder)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('companies').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No hay empresas registradas.', style: TextStyle(color: Colors.red));
                    }

                    final companies = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Selecciona tu Empresa',
                        labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.apartment, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                      style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 15),
                      value: _selectedCompanyId,
                      isExpanded: true,
                      items: companies.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['company_name'] ?? 'Empresa sin nombre'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCompanyId = val;
                          final selectedDoc = companies.firstWhere((doc) => doc.id == val);
                          _selectedCompanyName = (selectedDoc.data() as Map<String, dynamic>)['company_name'];
                        });
                      },
                      validator: (value) => value == null ? 'Requerido' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 📝 Datos Básicos
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.badge, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _positionController,
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Cargo o Departamento',
                    labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.work, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),

                // 🚀 Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB), // Blue 600
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Enviar Solicitud', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}

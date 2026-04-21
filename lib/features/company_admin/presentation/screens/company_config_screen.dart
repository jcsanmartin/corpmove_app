import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/company_config_provider.dart';

class CompanyConfigScreen extends StatefulWidget {
  // Para la demo, podemos pasar un ID fijo o leerlo del auth real.
  final String companyId;

  const CompanyConfigScreen({super.key, this.companyId = 'demo_company_123'});

  @override
  State<CompanyConfigScreen> createState() => _CompanyConfigScreenState();
}

class _CompanyConfigScreenState extends State<CompanyConfigScreen> {
  final TextEditingController _limitController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompanyConfigProvider()..loadCompanyData(widget.companyId),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), // Fondo oscuro
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            'Panel de Administrador',
            style: GoogleFonts.inter(
                color: const Color(0xFF00C853), fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF00C853)),
          elevation: 0,
        ),
        body: Consumer<CompanyConfigProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00C853)));
            }

            final companyData = provider.companyData;
            if (companyData == null) {
              return Center(
                child: Text('No se encontró la información de la empresa.',
                    style: GoogleFonts.inter(color: Colors.white70)),
              );
            }

            // Inicializar el controlador solo si no tiene texto para no perder lo que digita el usuario
            if (_limitController.text.isEmpty) {
              _limitController.text =
                  companyData['corporate_limit']?.toString() ?? '0';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(companyData),
                  const SizedBox(height: 30),
                  _buildPolicyCard(context, provider),
                  const SizedBox(height: 30),
                  _buildEmployeesSection(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> companyData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración SaaS',
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          companyData['company_name'] ?? 'Empresa',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyCard(
      BuildContext context, CompanyConfigProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Negro más claro para tarjetas
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF00C853)),
              const SizedBox(width: 10),
              Text(
                'Políticas de Movilidad',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Techo de Cobertura por Viaje (COP)',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00C853),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: GoogleFonts.inter(
                      color: const Color(0xFF00C853),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.black,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: provider.isSaving
                    ? null
                    : () async {
                        final newLimit =
                            double.tryParse(_limitController.text) ?? 0.0;
                        await provider.updateCorporateLimit(newLimit);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Límite actualizado en tiempo real'),
                              backgroundColor: Color(0xFF00C853),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Guardar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesSection(CompanyConfigProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Empleados Vinculados (${provider.employees.length})',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (provider.employees.isEmpty)
          Text(
            'No hay empleados registrados en esta empresa.',
            style: GoogleFonts.inter(color: Colors.white54),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.employees.length,
            itemBuilder: (context, index) {
              final emp = provider.employees[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white54),
                  ),
                  title: Text(
                    emp['name'] ?? 'Usuario sin nombre',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  subtitle: Text(
                    emp['email'] ?? 'Sin correo',
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Activo',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF00C853),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

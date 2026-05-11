import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/admin/application/admin_provider.dart';

class CaReportsTab extends StatefulWidget {
  final AdminProvider provider;
  const CaReportsTab({super.key, required this.provider});

  @override
  State<CaReportsTab> createState() => _CaReportsTabState();
}

class _CaReportsTabState extends State<CaReportsTab> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.loadCompanyTrips();
    });
  }

  Future<void> _generatePdf() async {
    setState(() => _isGenerating = true);
    final p = widget.provider;
    final companyName = p.companyData?['company_name'] ?? 'Empresa';
    final trips = p.companyTrips;
    final now = DateTime.now();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1B5E20'), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Reporte Corporativo', style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(companyName, style: pw.TextStyle(color: PdfColors.grey300, fontSize: 12)),
              ]),
              pw.Text('${now.day}/${now.month}/${now.year}', style: pw.TextStyle(color: PdfColors.grey300, fontSize: 11)),
            ]),
          ),
          pw.SizedBox(height: 20),
          // Resumen
          pw.Row(children: [
            _pdfStat('Total viajes', '${trips.length}'),
            pw.SizedBox(width: 16),
            _pdfStat('Completados', '${p.completedTripsCount}'),
            pw.SizedBox(width: 16),
            _pdfStat('Gasto total', '\$${p.totalSpent.toStringAsFixed(0)}'),
          ]),
          pw.SizedBox(height: 20),
          pw.Text('Detalle de Viajes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          // Tabla
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1B5E20)),
                children: ['Origen', 'Destino', 'Costo', 'Estado'].map((h) =>
                  pw.Padding(padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)))
                ).toList(),
              ),
              ...trips.take(50).map((t) {
                final origin = (t['origin_text'] ?? 'N/A').toString();
                final dest = (t['destination_text'] ?? 'N/A').toString();
                final cost = '\$${((t['cost'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}';
                final status = (t['status'] ?? '').toString();
                return pw.TableRow(children: [origin, dest, cost, status].map((v) =>
                  pw.Padding(padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(v, style: const pw.TextStyle(fontSize: 9), maxLines: 1))
                ).toList());
              }),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('Generado automáticamente por CorpMove', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        ],
      ),
    );

    setState(() => _isGenerating = false);
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'reporte_${companyName.replaceAll(' ', '_')}.pdf');
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1B5E20'))),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final trips = p.companyTrips;
    final totalSpent = p.totalSpent;
    final completed = p.completedTripsCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── KPIs ──
        Row(children: [
          Expanded(child: _kpiCard('Total\nViajes', '${trips.length}', AppColors.info, Icons.directions_car_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _kpiCard('Completados', '$completed', AppColors.success, Icons.done_all_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _kpiCard('Gasto\nTotal', '\$${totalSpent.toStringAsFixed(0)}', AppColors.accentLime, Icons.payments_rounded)),
        ]),
        const SizedBox(height: 24),

        // ── Gasto por empleado ──
        _buildEmployeeSpendBars(p),
        const SizedBox(height: 24),

        // ── Tabla de viajes ──
        _buildTripsTable(trips),
        const SizedBox(height: 32),

        // ── Botón PDF ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generatePdf,
            icon: _isGenerating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_isGenerating ? 'Generando PDF...' : 'Descargar Reporte PDF', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, height: 1.3)),
      ]),
    );
  }

  Widget _buildEmployeeSpendBars(AdminProvider p) {
    final spend = p.spendPerEmployee;
    if (spend.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
        child: Center(child: Text('Sin datos de gasto por empleado', style: GoogleFonts.inter(color: AppColors.textMuted))),
      );
    }

    final maxSpend = spend.values.fold<double>(1, (a, b) => b > a ? b : a);
    final entries = spend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gasto por Empleado', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ...entries.take(8).map((e) {
          final pct = e.value / maxSpend;
          final empName = p.getEmployeeName(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(empName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('\$${e.value.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: AppColors.borderSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentLime),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildTripsTable(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
        child: Center(child: Column(children: [
          const Icon(Icons.analytics_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Sin viajes registrados', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Los viajes corporativos aparecerán aquí', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        ])),
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Icon(Icons.receipt_long_rounded, color: AppColors.accentLime, size: 18),
            const SizedBox(width: 8),
            Text('Detalle de Viajes', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            Text('${trips.length} registros', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trips.length > 20 ? 20 : trips.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
          itemBuilder: (_, i) {
            final t = trips[i];
            final dest = (t['destination_text'] ?? 'Destino').toString();
            final origin = (t['origin_text'] ?? 'Origen').toString();
            final cost = (t['cost'] as num?)?.toDouble() ?? 0;
            final status = (t['status'] ?? '').toString();
            final createdAt = t['created_at'] as String?;
            String date = '';
            if (createdAt != null) {
              try {
                final dt = DateTime.parse(createdAt).toLocal();
                date = '${dt.day}/${dt.month}/${dt.year}';
              } catch (_) {}
            }
            final statusOk = status == 'completado' || status == 'finalizado';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: statusOk ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusOk ? Icons.check_rounded : Icons.schedule_rounded, size: 16, color: statusOk ? AppColors.success : AppColors.warning),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dest, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Desde: $origin', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\$${cost.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.accentLime, fontSize: 14)),
                  Text(date, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                ]),
              ]),
            );
          },
        ),
        if (trips.length > 20) Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Muestra los últimos 20 de ${trips.length} viajes. Descarga el PDF para verlos todos.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
        ),
      ]),
    );
  }
}

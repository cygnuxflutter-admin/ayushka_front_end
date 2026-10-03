import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../app/core/utils/print_helper.dart';
import '../../../../app/core/values/app_colors.dart';
import '../../../../app/core/widgets/custom_snackbar.dart';
import '../../../data/models/treatment_model.dart';

/// Clean, professional dialog displaying printable veterinary case medical summary,
/// with full native browser / OS print preview and PDF export support.
class PrintTreatmentSummaryDialog extends StatefulWidget {
  final CowTreatmentModel treatment;

  const PrintTreatmentSummaryDialog({
    super.key,
    required this.treatment,
  });

  static void show(BuildContext context, {required CowTreatmentModel treatment}) {
    showDialog(
      context: context,
      builder: (ctx) => PrintTreatmentSummaryDialog(treatment: treatment),
    );
  }

  @override
  State<PrintTreatmentSummaryDialog> createState() => _PrintTreatmentSummaryDialogState();
}

class _PrintTreatmentSummaryDialogState extends State<PrintTreatmentSummaryDialog> {
  bool _isPrinting = false;

  CowTreatmentModel get treatment => widget.treatment;

  /// Generates the high-fidelity PDF document matching clinic summary specifications
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(
      title: 'Medical_Summary_${treatment.displayCowTag}_${treatment.treatmentNumber}',
      author: 'Ayushka Veterinary Clinic',
    );

    final brandPrimary = PdfColor.fromInt(0xFF384C28);
    final brandLight = PdfColor.fromInt(0xFFF9FAF7);
    final textDark = PdfColor.fromInt(0xFF223318);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Top Clinic Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AYUSHKA VETERINARY CLINIC',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: brandPrimary,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Comprehensive Livestock Healthcare & Multi-Dose Record',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'CASE: ${treatment.treatmentNumber.isNotEmpty ? treatment.treatmentNumber : treatment.id}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: brandPrimary),
                    ),
                    pw.Text(
                      'Date: ${treatment.createdAt != null ? DateFormat('dd MMM yyyy').format(treatment.createdAt!) : DateFormat('dd MMM yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1.2, color: brandPrimary),
            pw.SizedBox(height: 10),

            // Patient & Vet Details Grid
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PATIENT DETAILS',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Cow Tag ID: ${treatment.displayCowTag}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                      pw.Text('Calf Name: ${treatment.displayCowName}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Gender: ${treatment.cowIsFemale ? "Female" : "Male"}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Shed: ${treatment.cowShedName ?? "Not assigned"}', style: const pw.TextStyle(fontSize: 10)),
                      if (treatment.cowBreedName != null)
                        pw.Text('Breed: ${treatment.cowBreedName}', style: const pw.TextStyle(fontSize: 10)),
                      if (treatment.cowWeight != null && treatment.cowWeight! > 0)
                        pw.Text('Weight: ${treatment.cowWeight} kg', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CASE & ATTENDING VET',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Treating Vet: ${treatment.doctorName.isNotEmpty ? treatment.doctorName : "In-House Vet"}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5),
                      ),
                      pw.Text('Vet Type: ${treatment.doctorType.label}', style: const pw.TextStyle(fontSize: 10)),
                      if (treatment.doctorContact.isNotEmpty)
                        pw.Text('Contact: ${treatment.doctorContact}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        'Status: ${treatment.status.label}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                      ),
                      pw.Text(
                        'Severity: ${treatment.severity.label}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Clinical Diagnosis Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: brandLight,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Clinical Diagnosis: ${treatment.diseaseName}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: textDark),
                  ),
                  if (treatment.symptoms.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Symptoms Observed: ${treatment.symptoms.join(', ')}',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  ],
                  if (treatment.diagnosisNotes != null && treatment.diagnosisNotes!.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Clinical Remarks: ${treatment.diagnosisNotes}',
                      style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Timeline Audit Table
            pw.Text(
              'DOSE ADMINISTRATION & TIMELINE AUDIT',
              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: brandPrimary),
            ),
            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(2.0),
                2: pw.FlexColumnWidth(1.3),
                3: pw.FlexColumnWidth(1.8),
                4: pw.FlexColumnWidth(3.0),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Dose #', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Schedule / Admin Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Staff / Vet', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Medicines & Remarks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                    ),
                  ],
                ),
                ...treatment.doses.map((d) {
                  final dateStr = d.isGiven && d.administeredDate != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(d.administeredDate!)
                      : (d.scheduledDate != null ? DateFormat('dd MMM yyyy').format(d.scheduledDate!) : 'Immediate');
                  final medsStr = d.medicines.isNotEmpty
                      ? d.medicines.map((m) => '${m.medicineName} (${m.dosage} - ${m.route})').join(', ')
                      : 'Standard protocol';

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Dose ${d.doseNumber}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          d.status.label,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: d.isGiven ? PdfColors.green800 : PdfColors.orange800,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(d.administeredBy ?? treatment.doctorName, style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(medsStr, style: const pw.TextStyle(fontSize: 9)),
                            if (d.notes != null && d.notes!.isNotEmpty)
                              pw.Text(
                                'Note: ${d.notes}',
                                style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            if (treatment.recoveryNotes != null && treatment.recoveryNotes!.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.green300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Discharge & Final Recovery Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: PdfColors.green900)),
                    pw.SizedBox(height: 2),
                    pw.Text(treatment.recoveryNotes!, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 30),
            // Footer Signature & Verification Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ayushka Dairy & Livestock Management System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('Official Veterinary Clinical Treatment Record', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Veterinary Officer', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Signature & Clinic Seal', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Triggers native OS / browser print preview
  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      final docBytes = await _generatePdf(PdfPageFormat.a4);
      final docName = 'Treatment_Summary_${treatment.displayCowTag}_${treatment.treatmentNumber}';
      await PrintHelper.printPdf(docBytes, '$docName.pdf');
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Print Error',
        message: 'Could not open print preview: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  /// Downloads / saves PDF directly
  Future<void> _handleDownload() async {
    setState(() => _isPrinting = true);
    try {
      final docBytes = await _generatePdf(PdfPageFormat.a4);
      final docName = 'Treatment_Summary_${treatment.displayCowTag}_${treatment.treatmentNumber}.pdf';
      await PrintHelper.downloadPdf(docBytes, docName);
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Export Error',
        message: 'Could not download PDF: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 850),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.printer, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Veterinary Medical Case Summary',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Printable Document Sheet (Preview)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AYUSHKA VETERINARY CLINIC',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Comprehensive Livestock Healthcare & Multi-Dose Record',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'CASE: ${treatment.treatmentNumber.isNotEmpty ? treatment.treatmentNumber : treatment.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Date: ${treatment.createdAt != null ? DateFormat('dd MMM yyyy').format(treatment.createdAt!) : DateFormat('dd MMM yyyy').format(DateTime.now())}',
                                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1.2),

                      // Cow & Doctor Info Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PATIENT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text('Cow Tag ID: ${treatment.displayCowTag}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                Text('Calf Name: ${treatment.displayCowName}', style: const TextStyle(fontSize: 12.5)),
                                Text('Gender: ${treatment.cowIsFemale ? 'Female' : 'Male'}', style: const TextStyle(fontSize: 12.5)),
                                Text('Shed: ${treatment.cowShedName ?? "Not assigned"}', style: const TextStyle(fontSize: 12.5)),
                                if (treatment.cowBreedName != null) Text('Breed: ${treatment.cowBreedName}', style: const TextStyle(fontSize: 12.5)),
                                if (treatment.cowWeight != null && treatment.cowWeight! > 0)
                                  Text('Weight: ${treatment.cowWeight} kg', style: const TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CASE & ATTENDING VET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text('Treating Vet: ${treatment.doctorName.isNotEmpty ? treatment.doctorName : "In-House Vet"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                Text('Vet Type: ${treatment.doctorType.label}', style: const TextStyle(fontSize: 12.5)),
                                if (treatment.doctorContact.isNotEmpty) Text('Contact: ${treatment.doctorContact}', style: const TextStyle(fontSize: 12.5)),
                                Text('Status: ${treatment.status.label}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: treatment.status.color)),
                                Text('Severity: ${treatment.severity.label}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: treatment.severity.color)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Diagnosis & Symptoms
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAF7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clinical Diagnosis: ${treatment.diseaseName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (treatment.symptoms.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Symptoms Observed: ${treatment.symptoms.join(', ')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (treatment.diagnosisNotes != null && treatment.diagnosisNotes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Clinical Notes: ${treatment.diagnosisNotes}',
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dose Schedule & Administration History Table
                      const Text(
                        'DOSE ADMINISTRATION & TIMELINE AUDIT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),

                      Table(
                        border: TableBorder.all(
                          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(2.0),
                          2: FlexColumnWidth(1.4),
                          3: FlexColumnWidth(2.0),
                          4: FlexColumnWidth(3.0),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : const Color(0xFFF3F4F6),
                            ),
                            children: const [
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Dose #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Schedule / Admin Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Staff / Vet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Medicines & Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                            ],
                          ),
                          ...treatment.doses.map((d) {
                            final dateStr = d.isGiven && d.administeredDate != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(d.administeredDate!)
                                : (d.scheduledDate != null ? DateFormat('dd MMM yyyy').format(d.scheduledDate!) : 'Scheduled');

                            final medsStr = d.medicines.isNotEmpty
                                ? d.medicines.map((m) => '${m.medicineName} (${m.dosage})').join(', ')
                                : 'Standard treatment protocol';

                            return TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.all(8.0), child: Text('Dose ${d.doseNumber}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                                Padding(padding: const EdgeInsets.all(8.0), child: Text(dateStr, style: const TextStyle(fontSize: 11))),
                                Padding(padding: const EdgeInsets.all(8.0), child: Text(d.status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: d.status.color))),
                                Padding(padding: const EdgeInsets.all(8.0), child: Text(d.administeredBy ?? treatment.doctorName, style: const TextStyle(fontSize: 11))),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(medsStr, style: const TextStyle(fontSize: 11)),
                                      if (d.notes != null && d.notes!.isNotEmpty)
                                        Text('Notes: ${d.notes}', style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),

                      if (treatment.recoveryNotes != null && treatment.recoveryNotes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Discharge & Final Recovery Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
                              const SizedBox(height: 3),
                              Text(treatment.recoveryNotes!, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer / Print Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _isPrinting ? null : _handleDownload,
                    icon: const Icon(PhosphorIconsRegular.downloadSimple, size: 16),
                    label: const Text('Save PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _handlePrint,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(PhosphorIconsRegular.printer, size: 16),
                    label: Text(_isPrinting ? 'Preparing Print...' : 'Print Medical Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

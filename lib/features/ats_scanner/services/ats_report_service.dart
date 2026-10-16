import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ats_result.dart';

class AtsReportService {
  static Future<void> generateAndPrintReport(AtsResult result) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CV Helper - ATS Analysis Report',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on ${DateTime.now().toLocal().toString().split('.').first}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    'Match Score: ${result.matchScore}/100',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 12),

            pw.Text('Target job description', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
            pw.SizedBox(height: 6),
            pw.Text(result.jobDescription, style: const pw.TextStyle(fontSize: 10, lineSpacing: 2)),
            pw.SizedBox(height: 16),

            // File Info
            pw.Text('Analyzed Resume: ${result.fileName} (${result.fileSizeKb} KB)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 12),

            // Matched & Missing Keywords
            pw.Text('Keyword Analysis', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
            pw.SizedBox(height: 6),
            pw.Text('Matched Keywords: ${result.matchedKeywords.join(", ")}', style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text('Missing Keywords: ${result.missingKeywords.join(", ")}', style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),

            // Section Statuses
            pw.Text('Resume Section Verification', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
            pw.SizedBox(height: 6),
            ...result.sectionStatuses.entries.map((entry) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(entry.key, style: const pw.TextStyle(fontSize: 11)),
                      pw.Text(entry.value,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: entry.value == 'Found' ? PdfColors.green700 : PdfColors.orange800,
                          )),
                    ],
                  ),
                )),
            pw.SizedBox(height: 16),

            pw.Text('Readability checks', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
            pw.SizedBox(height: 6),
            ...result.readabilityChecks.entries.map((entry) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text(entry.key, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(entry.value ? 'Passed' : 'Review', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: entry.value ? PdfColors.green700 : PdfColors.orange800)),
                  ]),
                )),
            if (result.analysisWarnings.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Notes', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
              pw.SizedBox(height: 4),
              ...result.analysisWarnings.map((warning) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('• $warning', style: const pw.TextStyle(fontSize: 9)),
                  )),
            ],
            pw.SizedBox(height: 16),

            // Improvement Suggestions
            pw.Text('Actionable Improvement Suggestions',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
            pw.SizedBox(height: 6),
            ...result.improvementSuggestions.map((sug) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                      pw.Expanded(child: pw.Text(sug, style: const pw.TextStyle(fontSize: 11))),
                    ],
                  ),
                )),
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 12),

            // Disclaimer
            pw.Text(
              'Disclaimer: This ATS match score and analysis report is estimated locally on your device for informational purposes and does not represent an official employer ATS algorithm score.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    final safeName = result.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'ATS_Analysis_Report_$safeName.pdf');
  }
}

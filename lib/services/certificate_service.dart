import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class CertificateService {
  Future<File> generateCertificate({
    required String userName,
    required String language,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber, width: 10),
            ),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.amber, width: 2),
              ),
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'LUMAD LINGUA',
                    style: pw.TextStyle(
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Ancestral Language Preservation Project',
                    style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'CERTIFICATE OF COMPLETION',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'This is to certify that',
                    style: const pw.TextStyle(fontSize: 18),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    userName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'has successfully reached the Peak of Wisdom in',
                    style: const pw.TextStyle(fontSize: 18),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    language.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber900,
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 150,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                            ),
                          ),
                          pw.Text('Tribal Council Advisor'),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(dateStr),
                          pw.Container(
                            width: 150,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                            ),
                          ),
                          pw.Text('Date Issued'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/certificate_${language.toLowerCase()}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

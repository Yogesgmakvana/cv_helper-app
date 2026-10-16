import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfFileResult {
  final String fileName;
  final int fileSizeKb;
  final String extractedText;
  final bool isSuccess;
  final String? errorMessage;

  const PdfFileResult({
    required this.fileName,
    required this.fileSizeKb,
    required this.extractedText,
    required this.isSuccess,
    this.errorMessage,
  });
}

class ResumeTextExtractor {
  static const int _maxFileBytes = 15 * 1024 * 1024;

  static Future<PdfFileResult> pickAndExtractPdf() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'txt'],
      );

      if (files.isEmpty) {
        return const PdfFileResult(
          fileName: '',
          fileSizeKb: 0,
          extractedText: '',
          isSuccess: false,
          errorMessage: 'File selection cancelled.',
        );
      }

      final file = files.first;
      final size = await file.length() ?? file.lengthSync() ?? 0;
      if (size == 0) {
        return _failure(file.name, 0, 'The selected file is empty.');
      }
      if (size > _maxFileBytes) {
        return _failure(file.name, (size / 1024).ceil(), 'Choose a file smaller than 15 MB.');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return _failure(file.name, (size / 1024).ceil(), 'The selected file could not be read. Please try another file.');
      }

      final extension = file.extension?.toLowerCase();
      final text = switch (extension) {
        'txt' => utf8.decode(bytes, allowMalformed: true).trim(),
        'pdf' => _extractPdfText(bytes),
        _ => '',
      };

      if (text.trim().length < 20) {
        return _failure(
          file.name,
          (size / 1024).ceil(),
          'No readable text was found. Scanned/image-only PDFs are not supported yet; use a text-based PDF or TXT file.',
        );
      }

      return PdfFileResult(
        fileName: file.name,
        fileSizeKb: (size / 1024).ceil(),
        extractedText: text,
        isSuccess: true,
      );
    } catch (error) {
      return _failure('', 0, 'Could not read that file. Try a text-based PDF or TXT file. ($error)');
    }
  }

  static String _extractPdfText(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText().trim();
    } finally {
      document.dispose();
    }
  }

  static PdfFileResult _failure(String fileName, int fileSizeKb, String message) =>
      PdfFileResult(
        fileName: fileName,
        fileSizeKb: fileSizeKb,
        extractedText: '',
        isSuccess: false,
        errorMessage: message,
      );
}

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../services/resume_text_extractor.dart';
import 'ats_analyzing_screen.dart';

class AtsScannerScreen extends StatefulWidget {
  const AtsScannerScreen({super.key});

  @override
  State<AtsScannerScreen> createState() => _AtsScannerScreenState();
}

class _AtsScannerScreenState extends State<AtsScannerScreen> {
  final TextEditingController _jdController = TextEditingController();
  PdfFileResult? _selectedFile;
  bool _isLoadingFile = false;

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  Future<void> _pickResumePdf() async {
    setState(() => _isLoadingFile = true);
    final result = await ResumeTextExtractor.pickAndExtractPdf();
    if (!mounted) return;
    setState(() {
      _isLoadingFile = false;
      if (result.isSuccess) {
        _selectedFile = result;
      } else {
        if (result.errorMessage != null && !result.errorMessage!.contains('cancelled')) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text('Error'),
            description: Text(result.errorMessage!),
            alignment: Alignment.topCenter,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    });
  }

  void _startAnalysis() {
    if (_selectedFile == null || _jdController.text.trim().length < 40) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flatColored,
        title: const Text('Invalid Input'),
        description: const Text('Add a job description with at least 40 characters to analyze your match.'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AtsAnalyzingScreen(
          fileName: _selectedFile!.fileName,
          fileSizeKb: _selectedFile!.fileSizeKb,
          resumeText: _selectedFile!.extractedText,
          jobDescription: _jdController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canAnalyze = _selectedFile != null && _jdController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    'ATS Resume Scanner',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1E)),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),

              // Subtitle
              const Text(
                'Make your resume job-ready.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1E)),
              ),
              const SizedBox(height: 4),
              Text(
                'Analyze your resume compatibility with any job description instantly.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Upload Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(
                    color: _selectedFile != null ? const Color(0xFF27AE60) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _selectedFile != null ? const Color(0xFFE8F8F0) : const Color(0xFFEFEBFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _selectedFile != null ? Icons.check_circle_rounded : Icons.picture_as_pdf_rounded,
                        color: _selectedFile != null ? const Color(0xFF27AE60) : const Color(0xFF6C5CE7),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null ? _selectedFile!.fileName : 'Upload Resume (PDF or TXT)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1E)),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFile != null
                          ? '${_selectedFile!.fileSizeKb} KB • Ready for analysis'
                          : 'Select resume file from your device storage',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isLoadingFile ? null : _pickResumePdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedFile != null ? const Color(0xFF1A1A1E) : const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        child: _isLoadingFile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : Text(
                                _selectedFile != null ? 'Change Resume' : 'Choose Resume',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Job Description Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Paste Job Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1E)),
                  ),
                  if (_jdController.text.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _jdController.clear()),
                      child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _jdController,
                maxLines: 6,
                maxLength: 10000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Paste the target job description or requirements here...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _jdController.text.trim().length < 40
                    ? 'Enter at least 40 characters (${_jdController.text.trim().length}/40)'
                    : 'Character count: ${_jdController.text.length}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),

              // Analyze Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canAnalyze && _jdController.text.trim().length >= 40 ? _startAnalysis : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey[500],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Analyze Resume ✨',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Notice
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Your resume is analyzed securely on your device.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

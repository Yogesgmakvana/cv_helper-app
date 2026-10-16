import 'package:flutter/material.dart';
import '../models/ats_result.dart';
import '../services/ats_scanner_service.dart';
import '../widgets/analysis_stage_tile.dart';
import 'ats_result_screen.dart';

class AtsAnalyzingScreen extends StatefulWidget {
  final String fileName;
  final int fileSizeKb;
  final String resumeText;
  final String jobDescription;

  const AtsAnalyzingScreen({
    super.key,
    required this.fileName,
    required this.fileSizeKb,
    required this.resumeText,
    required this.jobDescription,
  });

  @override
  State<AtsAnalyzingScreen> createState() => _AtsAnalyzingScreenState();
}

class _AtsAnalyzingScreenState extends State<AtsAnalyzingScreen> with TickerProviderStateMixin {
  int _currentStageIndex = 0;
  double _progressValue = 0.0;

  final List<String> _stages = [
    'Opening your resume...',
    'Extracting resume text...',
    'Reading job requirements...',
    'Identifying important skills...',
    'Matching resume keywords...',
    'Checking resume sections...',
    'Evaluating document readability...',
    'Preparing your ATS report...',
  ];

  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _runAnalysisPipeline();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysisPipeline() async {
    for (int i = 0; i < _stages.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentStageIndex = i;
        _progressValue = (i + 1) / _stages.length;
      });
      await Future.delayed(const Duration(milliseconds: 350));
    }

    // Perform actual analysis
    AtsResult result = await AtsScannerService.analyzeResume(
      fileName: widget.fileName,
      fileSizeKb: widget.fileSizeKb,
      resumeText: widget.resumeText,
      jobDescription: widget.jobDescription,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AtsResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int percent = (_progressValue * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Checking your resume',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1E)),
              ),
              const SizedBox(height: 6),
              Text(
                'Analyzing ${widget.fileName}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 36),

              // Animated Document Illustration with Scanning Line & Circular Progress
              Center(
                child: SizedBox(
                  width: 140,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Circular Progress
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _progressValue,
                          backgroundColor: const Color(0xFFEFEBFF),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                          strokeWidth: 6,
                        ),
                      ),
                      // Document Icon Container
                      Container(
                        width: 110,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 40, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
                                  const SizedBox(height: 8),
                                  Container(width: 65, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(height: 4),
                                  Container(width: 55, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(height: 12),
                                  Container(width: 30, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
                                  const SizedBox(height: 8),
                                  Container(width: 70, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
                                ],
                              ),
                            ),
                            // Scanning Glow Line
                            AnimatedBuilder(
                              animation: _scanController,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanController.value * 110,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C5CE7),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.8), blurRadius: 8, spreadRadius: 2),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Percentage Text Overlay
                      Positioned(
                        bottom: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$percent%',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Stages Checklist Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListView.builder(
                    itemCount: _stages.length,
                    itemBuilder: (context, index) {
                      bool isCompleted = index < _currentStageIndex;
                      bool isActive = index == _currentStageIndex;
                      return AnalysisStageTile(
                        title: _stages[index],
                        isCompleted: isCompleted,
                        isActive: isActive,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Indicator
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Analysis performed locally on your device.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

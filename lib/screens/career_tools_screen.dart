import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';
import '../features/ats_scanner/screens/ats_scanner_screen.dart';
import '../services/interview_speech_service.dart';
import '../services/toast_service.dart';

class CareerToolsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const CareerToolsScreen({super.key, required this.onBack});

  Future<void> _onToolTapped(BuildContext context, String toolName) async {
    if (toolName == 'ATS Resume Checker') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AtsScannerScreen()),
      );
      return;
    }

    final Widget? featureSheet = switch (toolName) {
      'Interview Practice' => const InterviewPracticeSheet(),
      'Salary Insight' => const SalaryInsightSheet(),
      'Career Roadmap' => const CareerRoadmapSheet(),
      _ => null,
    };
    if (featureSheet != null) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => featureSheet,
      );
      return;
    }

    final inputController = TextEditingController();
    var generatedText = '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEBFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF6C5CE7),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toolName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Private, on-device career tools',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _toolPrompt(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: inputController,
                  maxLines: 4,
                  maxLength: 3000,
                  decoration: InputDecoration(
                    hintText: _toolHint(),
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF6C5CE7),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (generatedText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SelectableText(
                      generatedText,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF1A1A1E),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: generatedText),
                        );
                        if (context.mounted) {
                          showAppToast(context, 'Draft copied to clipboard.');
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy draft'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final input = inputController.text.trim();
                      if (input.isEmpty) {
                        showAppToast(context, 'Add a job title or details first.', isError: true);
                        return;
                      }
                      setSheetState(
                        () => generatedText = _generateToolOutput(input),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      generatedText.isEmpty
                          ? _toolAction()
                          : 'Regenerate draft',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    inputController.dispose();
  }

  String _toolPrompt() =>
      'Add the role and company, plus any details from the job posting you want to highlight.';

  String _toolHint() =>
      'e.g. Product Designer at Acme; emphasize design systems and research...';

  String _toolAction() => 'Create cover letter draft';

  String _generateToolOutput(String input) {
    final profile = appState.userSummary.trim();
    return '''Dear Hiring Manager,

I am writing to apply for $input. ${profile.isEmpty ? 'My experience and skills make me interested in contributing to your team.' : profile}

I would welcome the opportunity to discuss how my background can support your team's goals. Thank you for your time and consideration.

Sincerely,
${appState.userName}''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar
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
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87,
                        size: 18,
                      ),
                      onPressed: onBack,
                    ),
                  ),
                  const Text(
                    'Career Tools',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1E),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('About these tools'),
                            content: const Text(
                              'Interview practice, roadmap progress, and career drafts stay on this device. Salary Insight calculates from the market range you provide; it does not use live salary data.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBFF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tools for\nYour Career',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1E),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Practical, private tools to plan your next career move',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9B88FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.work_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF27AE60),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tools List Items
              _buildToolItem(
                context,
                icon: Icons.check_circle_outline_rounded,
                title: 'ATS Resume Checker',
                subtitle:
                    'Scan your resume and get ATS Score with detailed feedback',
                trailing: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              _buildToolItem(
                context,
                icon: Icons.mail_outline_rounded,
                title: 'Cover Letter Generator',
                subtitle: 'Create and copy a tailored cover letter draft.',
                trailing: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              _buildToolItem(
                context,
                icon: Icons.mic_none_rounded,
                title: 'Interview Practice',
                subtitle:
                    'Answer 12 role-based questions and get feedback out of 10',
                trailing: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              _buildToolItem(
                context,
                icon: Icons.show_chart_rounded,
                title: 'Salary Insight',
                subtitle: 'Estimate a range from your experience and a market benchmark',
                trailing: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              _buildToolItem(
                context,
                icon: Icons.flag_outlined,
                title: 'Career Roadmap',
                subtitle: 'Follow a personalized 12-step career plan',
                trailing: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 100), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return GestureDetector(
      onTap: () => _onToolTapped(context, title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEBFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF6C5CE7), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _CareerFeatureSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _CareerFeatureSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = (media.size.height * .86 - media.viewInsets.bottom).clamp(
      320.0,
      760.0,
    );
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E0E8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBFF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: const Color(0xFF6C5CE7)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777582),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0EFF3)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                18,
                22,
                24 + media.viewInsets.bottom,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class InterviewPracticeSheet extends StatefulWidget {
  const InterviewPracticeSheet({super.key});

  @override
  State<InterviewPracticeSheet> createState() => _InterviewPracticeSheetState();
}

class _InterviewPracticeSheetState extends State<InterviewPracticeSheet> {
  final _roleController = TextEditingController(text: appState.userRole);
  final _answerController = TextEditingController();
  String _role = '';
  String _speechBaseText = '';
  int _questionIndex = 0;
  bool _started = false;
  bool _finished = false;
  _InterviewScore? _currentScore;
  final List<_InterviewScore> _scores = [];

  bool get _speechAvailable => interviewSpeechService.available;
  bool get _isListening => interviewSpeechService.listening;
  String get _speechError => interviewSpeechService.error;

  List<String> get _questions => [
    'Tell me about yourself and how your experience prepared you for a $_role role.',
    'What is one achievement that best shows the value you could bring as a $_role?',
    'Describe a difficult problem you faced at work. How did you approach it?',
    'Tell me about a time you had to work through a disagreement with a teammate.',
    'How do you prioritize when several important tasks have the same deadline?',
    'Describe a time you received difficult feedback. What did you change afterward?',
    'Tell me about a mistake or setback and what you learned from it.',
    'How do you measure whether your work is successful?',
    'Explain a complex idea or project to someone outside your area of expertise.',
    'Tell me about a time you took ownership beyond your assigned responsibilities.',
    'Why are you interested in this $_role position and this kind of work?',
    'What would you focus on during your first 90 days in a new $_role position?',
  ];

  @override
  void initState() {
    super.initState();
    interviewSpeechService.addListener(_onSpeechStateChanged);
  }

  void _onSpeechStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    interviewSpeechService.removeListener(_onSpeechStateChanged);
    if (_isListening) interviewSpeechService.speech.stop();
    _roleController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    await interviewSpeechService.initialize();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await interviewSpeechService.speech.stop();
      return;
    }
    if (!_speechAvailable) await _initializeSpeech();
    if (!_speechAvailable || !mounted) return;

    _speechBaseText = _answerController.text.trim();
    interviewSpeechService.clearError();
    try {
      await interviewSpeechService.speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final spoken = result.recognizedWords.trim();
          final transcript = [
            _speechBaseText,
            spoken,
          ].where((part) => part.isNotEmpty).join(' ');
          setState(() {
            _answerController.value = TextEditingValue(
              text: transcript,
              selection: TextSelection.collapsed(offset: transcript.length),
            );
          });
        },
      );
    } catch (_) {
      if (mounted) {
        interviewSpeechService.setError(
          'Could not start the microphone. Check app permissions.',
        );
      }
    }
  }

  void _start() {
    final role = _roleController.text.trim();
    if (role.isEmpty) return;
    setState(() {
      _role = role;
      _started = true;
    });
  }

  Future<void> _score() async {
    if (_isListening) {
      await interviewSpeechService.speech.stop();
    }
    if (!mounted) return;
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      showAppToast(context, 'Speak your answer before scoring it.', isError: true);
      return;
    }
    setState(() => _currentScore = _evaluateInterviewAnswer(answer));
  }

  void _next() {
    final score = _currentScore;
    if (score == null) return;
    _scores.add(score);
    if (_questionIndex == _questions.length - 1) {
      setState(() => _finished = true);
      return;
    }
    interviewSpeechService.clearError();
    setState(() {
      _questionIndex++;
      _currentScore = null;
      _answerController.clear();
    });
  }

  void _restart() {
    interviewSpeechService.clearError();
    setState(() {
      _questionIndex = 0;
      _scores.clear();
      _currentScore = null;
      _finished = false;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CareerFeatureSheet(
      title: 'Interview practice',
      subtitle: '12 questions · private on this device',
      icon: Icons.record_voice_over_rounded,
      child: !_started
          ? _buildSetup()
          : _finished
          ? _buildResults()
          : _buildQuestion(),
    );
  }

  Widget _buildSetup() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _InfoPanel(
        icon: Icons.lightbulb_outline_rounded,
        text: 'Speak your answer one question at a time. Your device will turn your speech into text, then score each response out of 10.',
      ),
      const SizedBox(height: 20),
      _FieldLabel('Target role'),
      TextField(
        controller: _roleController,
        textCapitalization: TextCapitalization.words,
        decoration: _fieldDecoration('e.g. Product Designer'),
        onSubmitted: (_) => _start(),
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: 'Start 12-question practice',
        icon: Icons.play_arrow_rounded,
        onPressed: _start,
      ),
    ],
  );

  Widget _buildQuestion() {
    final question = _questions[_questionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'QUESTION ${_questionIndex + 1} OF ${_questions.length}',
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${(_questionIndex / _questions.length * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFF777582),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value:
                (_questionIndex + (_currentScore == null ? 0 : 1)) /
                _questions.length,
            minHeight: 6,
            backgroundColor: const Color(0xFFEFEBFF),
            color: const Color(0xFF6C5CE7),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEBF5)),
          ),
          child: Text(
            question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: Color(0xFF22212A),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: _FieldLabel('Your spoken answer')),
            if (_answerController.text.isNotEmpty &&
                _currentScore == null &&
                !_isListening)
              TextButton.icon(
                onPressed: () {
                  interviewSpeechService.clearError();
                  setState(() {
                    _answerController.clear();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Clear'),
              ),
          ],
        ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isListening
                  ? const Color(0xFF6C5CE7)
                  : const Color(0xFFE9E7EF),
              width: _isListening ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _answerController.text.isEmpty
                    ? 'Your recognized speech will appear here.'
                    : _answerController.text,
                style: TextStyle(
                  color: _answerController.text.isEmpty
                      ? const Color(0xFFA6A4AE)
                      : const Color(0xFF30303A),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (_isListening) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Listening…',
                      style: TextStyle(color: Color(0xFF6C5CE7)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _currentScore == null ? _toggleListening : null,
            icon: Icon(
              _isListening ? Icons.stop_circle_outlined : Icons.mic_rounded,
            ),
            label: Text(_isListening ? 'Stop speaking' : 'Tap to speak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isListening
                  ? const Color(0xFFB42318)
                  : const Color(0xFF6C5CE7),
              side: BorderSide(
                color: _isListening
                    ? const Color(0xFFF2B8B5)
                    : const Color(0xFFDCD6FF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (_speechAvailable &&
            !_isListening &&
            _answerController.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Paused after a short silence? Tap the microphone to continue speaking.',
              style: TextStyle(fontSize: 11, color: Color(0xFF85838F)),
            ),
          ),
        if (_speechError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _speechError,
            style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
          ),
        ],
        if (_currentScore case final score?) ...[
          const SizedBox(height: 14),
          _ScorePanel(score: score),
        ],
        const SizedBox(height: 18),
        _PrimaryButton(
          label: _currentScore == null
              ? 'Score my spoken answer'
              : _questionIndex == _questions.length - 1
              ? 'View practice results'
              : 'Next question',
          icon: _currentScore == null
              ? Icons.auto_graph_rounded
              : Icons.arrow_forward_rounded,
          onPressed: _currentScore == null ? _score : _next,
        ),
        const SizedBox(height: 10),
        const Text(
          'Scores assess answer structure and detail, not factual accuracy.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(0xFF85838F)),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final average = _scores.isEmpty
        ? 0.0
        : _scores.fold<int>(0, (sum, score) => sum + score.value) /
              _scores.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEBFF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Average practice score out of 10',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),
        ..._scores.asMap().entries.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFEBFF),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.value.value}',
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${entry.key + 1}. ${_questions[entry.key]}\n\n${entry.value.answer}',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF30303A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _PrimaryButton(
          label: 'Practice again',
          icon: Icons.replay_rounded,
          onPressed: _restart,
        ),
      ],
    );
  }
}

class _InterviewScore {
  final int value;
  final List<String> feedback;
  final String answer;
  const _InterviewScore(this.value, this.feedback, this.answer);
}

_InterviewScore _evaluateInterviewAnswer(String answer) {
  final text = answer.toLowerCase();
  final words = text
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
  var score = words < 12
      ? 1
      : words < 30
      ? 2
      : 3;
  final feedback = <String>[];
  final actionWords = RegExp(
    r'\b(led|built|created|analyzed|implemented|improved|resolved|planned|owned|designed|delivered|coordinated|launched|managed|developed)\b',
  );
  final resultWords = RegExp(
    r'\b(result|increased|reduced|saved|achieved|improved|measured|reached|delivered|percent|users|revenue)\b|\d+%?',
  );
  final contextWords = RegExp(
    r'\b(when|because|challenge|goal|needed|context|situation|task)\b',
  );
  final taskWords = RegExp(
    r'\b(responsible|assigned|objective|requirement|deadline|customer|client|project)\b',
  );
  final evidenceWords = RegExp(r'\b(i|my|we|team|users|product)\b|\d+');
  final actionCount = actionWords.allMatches(text).length;
  final hasResult = resultWords.hasMatch(text);
  final hasContext = contextWords.hasMatch(text);
  final hasTask = taskWords.hasMatch(text);
  final hasEvidence = evidenceWords.hasMatch(text);
  score += actionCount == 0
      ? 0
      : actionCount == 1
      ? 1
      : 2;
  score += hasResult ? 2 : 0;
  score += (hasContext ? 1 : 0) + (hasTask ? 1 : 0);
  score += hasEvidence ? 1 : 0;
  if (words < 30) {
    feedback.add('Add more context so the example is easy to understand.');
  }
  if (actionCount == 0) {
    feedback.add('Make your personal actions clear with specific verbs.');
  }
  if (!hasResult) {
    feedback.add('Close with the outcome, impact, or what you learned.');
  }
  if (!hasContext) {
    feedback.add('Briefly explain the situation or goal first.');
  }
  if (feedback.isEmpty) {
    feedback.add(
      'Strong structure. Keep the example concise and be ready to explain your result.',
    );
  }
  return _InterviewScore(score.clamp(1, 10), feedback, answer.trim());
}

class SalaryInsightSheet extends StatefulWidget {
  const SalaryInsightSheet({super.key});

  @override
  State<SalaryInsightSheet> createState() => _SalaryInsightSheetState();
}

class _SalaryInsightSheetState extends State<SalaryInsightSheet> {
  final _roleController = TextEditingController(text: appState.userRole);
  final _locationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _lowController = TextEditingController();
  final _highController = TextEditingController();
  final _sourceController = TextEditingController();
  String _currency = 'INR';
  String _period = 'Annual';
  bool _showEstimate = false;
  double _low = 0;
  double _high = 0;
  int _years = 0;

  @override
  void dispose() {
    _roleController.dispose();
    _locationController.dispose();
    _experienceController.dispose();
    _lowController.dispose();
    _highController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  String get _experienceLevel => switch (_years) {
    < 2 => 'Early career',
    < 5 => 'Developing professional',
    < 9 => 'Experienced professional',
    _ => 'Senior professional',
  };

  void _calculate() {
    final role = _roleController.text.trim();
    final location = _locationController.text.trim();
    final years = int.tryParse(_experienceController.text.trim());
    final low = double.tryParse(_lowController.text.replaceAll(',', '').trim());
    final high = double.tryParse(
      _highController.text.replaceAll(',', '').trim(),
    );
    if (role.isEmpty ||
        location.isEmpty ||
        years == null ||
        years < 0 ||
        years > 60) {
      _message('Enter a role, location, and valid years of experience.');
      return;
    }
    if (low == null || high == null || low <= 0 || high <= low) {
      _message('Enter a valid salary range from a recent job post or report.');
      return;
    }
    setState(() {
      _years = years;
      _low = low;
      _high = high;
      _showEstimate = true;
    });
  }

  void _message(String text) {
    showAppToast(context, text);
  }

  String _money(double value) => NumberFormat.currency(
    name: _currency,
    locale: _currency == 'INR' ? 'en_IN' : 'en_US',
    decimalDigits: 0,
  ).format(value);

  String get _experienceAdvice => switch (_years) {
    < 2 => 'Compare entry-level roles and show practical projects or training.',
    < 5 =>
      'Compare roles that expect independent delivery and consistent results.',
    < 9 => 'Compare senior roles using your ownership, specialization, and outcomes.',
    _ => 'Compare leadership scope, business impact, and specialist expertise.',
  };

  @override
  Widget build(BuildContext context) => _CareerFeatureSheet(
    title: 'Salary insight',
    subtitle: 'Personalized using your experience and market range',
    icon: Icons.payments_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoPanel(
          icon: Icons.info_outline_rounded,
          text: 'There is no live salary database connected. Add a recent salary range from a job posting or trusted report; the app will show the range and a midpoint for your experience level without inventing market data.',
        ),
        const SizedBox(height: 20),
        _FieldLabel('Target role'),
        TextField(
          controller: _roleController,
          textCapitalization: TextCapitalization.words,
          decoration: _fieldDecoration('e.g. Senior Flutter Developer'),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Location'),
        TextField(
          controller: _locationController,
          textCapitalization: TextCapitalization.words,
          decoration: _fieldDecoration('City, region, or country'),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Years of relevant experience'),
        TextField(
          controller: _experienceController,
          keyboardType: TextInputType.number,
          decoration: _fieldDecoration('e.g. 5'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: _fieldDecoration('Currency'),
                items: const [
                  DropdownMenuItem(value: 'INR', child: Text('INR ₹')),
                  DropdownMenuItem(value: 'USD', child: Text('USD \$')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP £')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR €')),
                ],
                onChanged: (value) => setState(() {
                  if (value != _currency) {
                    _lowController.clear();
                    _highController.clear();
                    _showEstimate = false;
                  }
                  _currency = value ?? 'USD';
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: _fieldDecoration('Pay period'),
                items: const [
                  DropdownMenuItem(value: 'Annual', child: Text('Annual')),
                  DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                ],
                onChanged: (value) => setState(() {
                  if (value != _period) {
                    _lowController.clear();
                    _highController.clear();
                    _showEstimate = false;
                  }
                  _period = value ?? 'Annual';
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _FieldLabel('Market range from a recent source'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lowController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _fieldDecoration('Low'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('to', style: TextStyle(color: Color(0xFF777582))),
            ),
            Expanded(
              child: TextField(
                controller: _highController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _fieldDecoration('High'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Use the same currency and pay period for both values.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        _FieldLabel('Source note (optional)'),
        TextField(
          controller: _sourceController,
          decoration: _fieldDecoration('Company, report, or source link'),
        ),
        if (_showEstimate) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEBFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDDD6FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_roleController.text.trim()} · ${_locationController.text.trim()}',
                  style: const TextStyle(
                    color: Color(0xFF302A54),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Market range: ${_money(_low)} – ${_money(_high)} / ${_period.toLowerCase()}',
                  style: const TextStyle(
                    color: Color(0xFF49445F),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Midpoint: ${_money((_low + _high) / 2)} / ${_period.toLowerCase()}',
                  style: const TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_years years · $_experienceLevel. $_experienceAdvice',
                  style: const TextStyle(
                    color: Color(0xFF49445F),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                if (_sourceController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${_sourceController.text.trim()}',
                    style: const TextStyle(
                      color: Color(0xFF777582),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                const Text(
                  'The range and midpoint come from your source values, not a live salary lookup.',
                  style: TextStyle(
                    color: Color(0xFF777582),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        _PrimaryButton(
          label: _showEstimate
              ? 'Update salary insight'
              : 'Calculate salary insight',
          icon: Icons.calculate_outlined,
          onPressed: _calculate,
        ),
      ],
    ),
  );
}

class CareerRoadmapSheet extends StatefulWidget {
  const CareerRoadmapSheet({super.key});

  @override
  State<CareerRoadmapSheet> createState() => _CareerRoadmapSheetState();
}

class _CareerRoadmapSheetState extends State<CareerRoadmapSheet> {
  final _roleController = TextEditingController(text: appState.userRole);
  final _experienceController = TextEditingController();
  String? _role;
  int _years = 0;
  final Set<int> _completed = {};

  String get _progressKey =>
      'cv_helper_roadmap_${_years}_${_role?.toLowerCase().replaceAll(RegExp(r'\W+'), '_')}';

  @override
  void dispose() {
    _roleController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _createRoadmap() async {
    final role = _roleController.text.trim();
    final years = int.tryParse(_experienceController.text.trim());
    if (role.isEmpty || years == null || years < 0 || years > 60) {
      showAppToast(context, 'Enter a career goal and valid experience years.', isError: true);
      return;
    }
    setState(() {
      _role = role;
      _years = years;
      _completed.clear();
    });
    await _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_progressKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _completed
        ..clear()
        ..addAll(saved.map(int.tryParse).whereType<int>());
    });
  }

  Future<void> _saveProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _progressKey,
      _completed.map((index) => index.toString()).toList(),
    );
  }

  List<_RoadmapStep> _steps() {
    final role = _role ?? 'your target role';
    final advanced = _years >= 7;
    return [
      _RoadmapStep(
        'Define the target',
        'Write a clear description of the $role work you want, including level, industry, and preferred environment.',
        'Week 1',
      ),
      _RoadmapStep(
        'Review real role requirements',
        'Collect 5–8 recent $role postings and note repeated responsibilities, tools, and qualifications.',
        'Week 1',
      ),
      _RoadmapStep(
        'Map your current strengths',
        'Match your experience to the requirements. List evidence and outcomes for each strength.',
        'Week 2',
      ),
      _RoadmapStep(
        'Choose the highest-value gap',
        advanced
            ? 'Identify one advanced specialization or leadership gap that appears across target postings.'
            : 'Choose the most common skill gap and break it into small learning goals.',
        'Week 2',
      ),
      _RoadmapStep(
        'Build a focused learning plan',
        'Choose a course, book, mentor, or guided project that directly addresses the $role skill gap.',
        'Weeks 3–4',
      ),
      _RoadmapStep(
        'Practice the core skill',
        'Complete short exercises and keep notes on what you can now do independently.',
        'Month 2',
      ),
      _RoadmapStep(
        'Create a relevant project',
        'Build a realistic $role work sample. Explain the problem, your decisions, and the result.',
        'Month 2',
      ),
      _RoadmapStep(
        'Get informed feedback',
        'Ask a peer or experienced professional to review the project against the requirements you collected.',
        'Month 2',
      ),
      _RoadmapStep(
        'Improve and document impact',
        'Apply feedback, refine the work, and record measurable results or lessons learned.',
        'Month 3',
      ),
      _RoadmapStep(
        'Refresh your application materials',
        'Tailor your resume and portfolio to the $role. Use specific, truthful evidence instead of generic claims.',
        'Month 3',
      ),
      _RoadmapStep(
        'Prepare for interviews',
        'Practice examples about ownership, problem solving, collaboration, and outcomes for the $role.',
        'Month 3',
      ),
      _RoadmapStep(
        'Apply and adjust',
        'Apply to suitable roles, track responses, request feedback, and adjust your plan based on what employers ask for.',
        'Month 4',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => _CareerFeatureSheet(
    title: 'Career roadmap',
    subtitle: 'A personalized 12-step plan you can track',
    icon: Icons.flag_outlined,
    child: _role == null ? _buildSetup() : _buildRoadmap(),
  );

  Widget _buildSetup() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _InfoPanel(
        icon: Icons.route_rounded,
        text: 'Create a practical plan around your target role and experience. Track each milestone as you complete it.',
      ),
      const SizedBox(height: 20),
      _FieldLabel('Career goal or target role'),
      TextField(
        controller: _roleController,
        textCapitalization: TextCapitalization.words,
        decoration: _fieldDecoration('e.g. Move into data analysis'),
      ),
      const SizedBox(height: 14),
      _FieldLabel('Relevant experience in years'),
      TextField(
        controller: _experienceController,
        keyboardType: TextInputType.number,
        decoration: _fieldDecoration('e.g. 3'),
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: 'Build my 12-step roadmap',
        icon: Icons.route_rounded,
        onPressed: _createRoadmap,
      ),
    ],
  );

  Widget _buildRoadmap() {
    final steps = _steps();
    final progress = _completed.length / steps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEBFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _role!,
                style: const TextStyle(
                  color: Color(0xFF302A54),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$_years years of experience · ${_completed.length} of ${steps.length} milestones complete',
                style: const TextStyle(color: Color(0xFF777582), fontSize: 12),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  color: const Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final checked = _completed.contains(index);
          final showPhase = index == 0 || index == 4 || index == 8;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showPhase)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 14, bottom: 8),
                  child: Text(
                    switch (index) {
                      0 => 'PHASE 1 · CLARITY',
                      4 => 'PHASE 2 · BUILD SKILLS',
                      _ => 'PHASE 3 · MOVE FORWARD',
                    },
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: checked ? const Color(0xFFF5F3FF) : Colors.white,
                  border: Border.all(color: const Color(0xFFECEAF2)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: checked,
                      activeColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (value) async {
                        setState(() {
                          if (value == true) {
                            _completed.add(index);
                          } else {
                            _completed.remove(index);
                          }
                        });
                        await _saveProgress();
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${index + 1}. ${step.title}',
                                    style: TextStyle(
                                      color: const Color(0xFF26252D),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      decoration: checked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  step.time,
                                  style: const TextStyle(
                                    color: Color(0xFF6C5CE7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              step.description,
                              style: const TextStyle(
                                color: Color(0xFF6F6D78),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() {
            _role = null;
            _completed.clear();
          }),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Change career goal'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C5CE7)),
        ),
      ],
    );
  }
}

class _RoadmapStep {
  final String title;
  final String description;
  final String time;
  const _RoadmapStep(this.title, this.description, this.time);
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPanel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7F9),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFECEAF2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6C5CE7), size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF666471),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF383641),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

InputDecoration _fieldDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFA6A4AE), fontSize: 13),
  filled: true,
  fillColor: const Color(0xFFF8F8FA),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: const BorderSide(color: Color(0xFFE9E7EF)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: const BorderSide(color: Color(0xFFE9E7EF)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.4),
  ),
);

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _ScorePanel extends StatelessWidget {
  final _InterviewScore score;
  const _ScorePanel({required this.score});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFEFEBFF),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Practice score',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF302A54),
                ),
              ),
            ),
            Text(
              '${score.value} / 10',
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...score.feedback.map(
          (item) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: Color(0xFF6C5CE7))),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF514B6B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

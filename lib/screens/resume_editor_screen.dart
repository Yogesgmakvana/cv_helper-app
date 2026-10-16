import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_state.dart';
import '../models/resume_samples.dart';
import '../services/resume_pdf_service.dart';
import '../services/download_notification_service.dart';
import '../services/toast_service.dart';
import '../features/ats_scanner/screens/ats_scanner_screen.dart';

class ResumeEditorScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ResumeEditorScreen({super.key, required this.onBack});

  @override
  State<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends State<ResumeEditorScreen> {
  int _selectedTab = 0; // 0: Editor, 1: Preview, 2: Optimize
  int _selectedStep =
      0; // 0: Personal Info, 1: Experience, 2: Education, 3: Skills

  // Controllers for Personal Info
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _summaryController;
  late TextEditingController _roleController;
  late TextEditingController _websiteController;
  late TextEditingController _linkedInController;
  late TextEditingController _languagesController;
  late TextEditingController _projectsController;
  late TextEditingController _referencesController;
  late TextEditingController _interestsController;

  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChanged);
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: appState.userName);
    _emailController = TextEditingController(text: appState.userEmail);
    _phoneController = TextEditingController(text: appState.userPhone);
    _locationController = TextEditingController(text: appState.userLocation);
    _summaryController = TextEditingController(text: appState.userSummary);
    _roleController = TextEditingController(text: appState.userRole);
    _websiteController = TextEditingController(text: appState.userWebsite);
    _linkedInController = TextEditingController(text: appState.userLinkedIn);
    _languagesController = TextEditingController(
      text: appState.languages.join('\n'),
    );
    _projectsController = TextEditingController(
      text: appState.projects.join('\n'),
    );
    _referencesController = TextEditingController(
      text: appState.references.join('\n'),
    );
    _interestsController = TextEditingController(
      text: appState.interests.join('\n'),
    );
  }

  @override
  void dispose() {
    appState.removeListener(_onStateChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    _roleController.dispose();
    _websiteController.dispose();
    _linkedInController.dispose();
    _languagesController.dispose();
    _projectsController.dispose();
    _referencesController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  int _readinessScore() {
    final checks = [
      appState.userName.trim().isNotEmpty,
      appState.userEmail.contains('@'),
      appState.userPhone.trim().isNotEmpty,
      appState.userSummary.trim().length >= 40,
      appState.experiences.isNotEmpty,
      appState.experiences.any((experience) => experience.bullets.isNotEmpty),
      appState.educations.isNotEmpty,
      appState.skills.isNotEmpty,
    ];
    return (checks.where((check) => check).length / checks.length * 100)
        .round();
  }

  List<String> _resumeTips() {
    final tips = <String>[];
    if (!appState.userEmail.contains('@') ||
        appState.userPhone.trim().isEmpty) {
      tips.add(
        'Add a valid email address and phone number to your contact details.',
      );
    }
    if (appState.userSummary.trim().length < 40) {
      tips.add(
        'Write a concise summary that names your role, strengths, and experience.',
      );
    }
    if (appState.experiences.isEmpty) {
      tips.add('Add at least one relevant work or project experience.');
    } else if (!appState.experiences.any(
      (experience) => experience.bullets.isNotEmpty,
    )) {
      tips.add(
        'Add achievement bullets that explain your actions and their outcomes.',
      );
    } else if (!appState.experiences
        .expand((experience) => experience.bullets)
        .any((bullet) => RegExp(r'\d').hasMatch(bullet))) {
      tips.add(
        'Where possible, quantify an achievement with a clear number or measurable result.',
      );
    }
    if (appState.educations.isEmpty)
      tips.add('Add your education or relevant training.');
    if (appState.skills.isEmpty)
      tips.add('Add skills that match the roles you are targeting.');
    if (tips.isEmpty)
      tips.add(
        'Your core resume sections are filled in. Tailor the wording and skills to each job description.',
      );
    return tips;
  }

  Future<void> _exportResume() async {
    var enteredName = appState.userName.trim().isEmpty
        ? 'Resume'
        : '${appState.userName} Resume';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Name your PDF'),
        content: TextFormField(
          initialValue: enteredName,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'PDF name',
            suffixText: '.pdf',
          ),
          onChanged: (value) => enteredName = value,
          onFieldSubmitted: (value) =>
              Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, enteredName.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      final location = await ResumePdfService.export(appState, name);
      if (location == null || !mounted) return;
      await DownloadNotificationService.showSaved(name, location);
      if (!mounted) return;
      showAppToast(
        context,
        '${name.trim()}${name.trim().toLowerCase().endsWith('.pdf') ? '' : '.pdf'} saved successfully in Downloads.',
      );
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, 'Could not export the resume: $error', isError: true);
    }
  }

  Future<void> _chooseProfilePhoto() async {
    try {
      final selection = await FilePicker.pickFile(type: FileType.image);
      final sourcePath = selection?.path;
      if (sourcePath == null) return;
      final extension = selection!.extension?.toLowerCase() ?? 'jpg';
      final directory = await getApplicationSupportDirectory();
      final destination = File(
        '${directory.path}/resume_profile_photo.$extension',
      );
      await File(sourcePath).copy(destination.path);
      appState.updateProfilePhoto(destination.path);
      if (!mounted) return;
      showAppToast(context, 'Profile photo saved for your resume.');
    } catch (error) {
      if (!mounted) return;
      showAppToast(context, 'Could not add the photo: $error', isError: true);
    }
  }

  void _showAddExperienceDialog() {
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final periodController = TextEditingController();
    final bulletController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.work_outline_rounded,
                        color: Color(0xFFF1C40F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Experience',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Highlight your career history',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Job Title',
                    hintText: 'e.g. Senior Product Designer',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyController,
                  decoration: InputDecoration(
                    labelText: 'Company / Studio',
                    hintText: 'e.g. Meizun Studio',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: periodController,
                  decoration: InputDecoration(
                    labelText: 'Period',
                    hintText: 'e.g. 2024-Present',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bulletController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Key Achievement',
                    hintText: 'e.g. Improved user engagement by 35%',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty &&
                              companyController.text.isNotEmpty) {
                            appState.addExperience(
                              ExperienceModel(
                                title: titleController.text.trim(),
                                company: companyController.text.trim(),
                                period: periodController.text.trim().isNotEmpty
                                    ? periodController.text.trim()
                                    : 'Present',
                                bullets: [
                                  bulletController.text.trim().isNotEmpty
                                      ? bulletController.text.trim()
                                      : 'Developed key features and improved product metrics.',
                                ],
                              ),
                            );
                            Navigator.pop(context);
                            showAppToast(context, 'Experience added successfully!');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add Experience',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
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

  void _showAddEducationDialog() {
    final schoolController = TextEditingController();
    final degreeController = TextEditingController();
    final periodController = TextEditingController();
    final gpaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        Icons.school_rounded,
                        color: Color(0xFF6C5CE7),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Education',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add your academic background',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: schoolController,
                  decoration: InputDecoration(
                    labelText: 'School / University',
                    hintText: 'e.g. Stanford University',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: degreeController,
                  decoration: InputDecoration(
                    labelText: 'Degree / Major',
                    hintText: 'e.g. B.S. in Computer Science',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: periodController,
                  decoration: InputDecoration(
                    labelText: 'Period',
                    hintText: 'e.g. 2019 - 2023',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gpaController,
                  decoration: InputDecoration(
                    labelText: 'GPA / Honors (Optional)',
                    hintText: 'e.g. 3.8 GPA',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (schoolController.text.isNotEmpty &&
                              degreeController.text.isNotEmpty) {
                            appState.addEducation(
                              EducationModel(
                                school: schoolController.text.trim(),
                                degree: degreeController.text.trim(),
                                period: periodController.text.trim().isNotEmpty
                                    ? periodController.text.trim()
                                    : '2020 - 2024',
                                gpa: gpaController.text.trim().isNotEmpty
                                    ? gpaController.text.trim()
                                    : '3.8 GPA',
                              ),
                            );
                            Navigator.pop(context);
                            showAppToast(context, 'Education added successfully!');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add Education',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
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

  void _showAddSkillDialog() {
    final skillController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF27AE60),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Professional Skill',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Add a skill keyword for ATS',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: skillController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Skill Name',
                  hintText: 'e.g. Jetpack Compose or React',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (skillController.text.isNotEmpty) {
                          appState.addSkill(skillController.text.trim());
                          Navigator.pop(context);
                          showAppToast(context, 'Skill added successfully!');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Add Skill',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _readinessScore();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
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
                          color: Colors.black.withOpacity(0.04),
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
                      onPressed: widget.onBack,
                    ),
                  ),
                  const Text(
                    'Resume Editor',
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
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.black87,
                        size: 18,
                      ),
                      onPressed: _exportResume,
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Tab Bar (Editor, Preview, Optimize)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFF2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildSegmentButton('Editor', 0)),
                    Expanded(child: _buildSegmentButton('Preview', 1)),
                    Expanded(child: _buildSegmentButton('Optimize', 2)),
                    Expanded(child: _buildSegmentButton('Samples', 3)),
                  ],
                ),
              ),
            ),

            // Step Category Selector (Only shown in Editor tab)
            if (_selectedTab == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      _buildStepItem(
                        Icons.person_outline_rounded,
                        'Personal Information',
                        0,
                      ),
                      const SizedBox(width: 16),
                      _buildStepItem(
                        Icons.work_outline_rounded,
                        'Experience',
                        1,
                      ),
                      const SizedBox(width: 16),
                      _buildStepItem(Icons.school_outlined, 'Education', 2),
                      const SizedBox(width: 16),
                      _buildStepItem(Icons.star_outline_rounded, 'Skills', 3),
                    ],
                  ),
                ),
              ),

            // Main Content Area based on Selected Tab & Step
            Expanded(
              child: _selectedTab == 3
                  ? _buildSamplesTab()
                  : _selectedTab == 1
                  ? _buildPreviewTab()
                  : _selectedTab == 2
                  ? _buildOptimizeTab(score)
                  : _buildEditorStepContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorStepContent() {
    switch (_selectedStep) {
      case 0:
        return _buildPersonalInformationEditor();
      case 1:
        return _buildExperienceEditor();
      case 2:
        return _buildEducationEditor();
      case 3:
        return _buildSkillsEditor();
      default:
        return _buildExperienceEditor();
    }
  }

  Widget _buildSamplesTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
    children: [
      const Text(
        'Start with a sample',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      const Text(
        'Choose a clean, professional example, then replace the sample details with your own.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 16),
      ...resumeSamples.map(
        (sample) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: _templatePreview(sample.templateId),
            title: Text(
              sample.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${sample.category}  •  ${sample.role}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              appState.applyResumeSample(
                templateId: sample.templateId,
                name: sample.name,
                role: sample.role,
                summary: sample.summary,
                company: sample.company,
                bullets: sample.bullets,
                degree: sample.degree,
                sampleSkills: sample.skills,
                website: sample.website,
                linkedin: sample.linkedin,
                secondRole: sample.secondRole,
                secondCompany: sample.secondCompany,
                secondPeriod: sample.secondPeriod,
                secondBullets: sample.secondBullets,
                school: sample.school,
                schoolPeriod: sample.schoolPeriod,
                sampleLanguages: sample.languages,
                sampleProjects: sample.projects,
                sampleReferences: sample.references,
                sampleInterests: sample.interests,
              );
              _nameController.text = appState.userName;
              _emailController.text = appState.userEmail;
              _phoneController.text = appState.userPhone;
              _locationController.text = appState.userLocation;
              _summaryController.text = appState.userSummary;
              _roleController.text = appState.userRole;
              _websiteController.text = appState.userWebsite;
              _linkedInController.text = appState.userLinkedIn;
              _languagesController.text = appState.languages.join('\n');
              _projectsController.text = appState.projects.join('\n');
              _referencesController.text = appState.references.join('\n');
              _interestsController.text = appState.interests.join('\n');
              setState(() {
                _selectedTab = 0;
                _selectedStep = 0;
              });
              showAppToast(
                context,
                '${sample.title} sample added. Edit the example details to make it yours.',
              );
            },
          ),
        ),
      ),
    ],
  );

  Color _templateColor(String id) => switch (id) {
    'teal' => const Color(0xFF2D687A),
    'gray' => const Color(0xFFE5E6E9),
    'navy' => const Color(0xFF293D4C),
    'amber' => const Color(0xFFF3A72F),
    _ => const Color(0xFF6C5CE7),
  };

  Widget _templatePreview(String id) {
    final color = _templateColor(id);
    Widget line(double width, {Color shade = const Color(0xFFB8C0C5)}) =>
        Container(height: 3, width: width, color: shade);
    return Container(
      width: 50,
      height: 64,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: id == 'gray' || id == 'amber'
            ? const Color(0xFFF0F1F2)
            : Colors.white,
        border: Border.all(color: const Color(0xFFE0E3E5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: id == 'teal'
          ? Column(
              children: [
                Container(height: 12, color: color),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            line(15, shade: color),
                            const SizedBox(height: 4),
                            line(18),
                            const SizedBox(height: 3),
                            line(14),
                            const SizedBox(height: 4),
                            line(18, shade: color),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        color: const Color(0xFFD9E1E4),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            line(22, shade: color),
                            const SizedBox(height: 4),
                            line(24),
                            const SizedBox(height: 3),
                            line(19),
                            const SizedBox(height: 3),
                            line(24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : id == 'gray'
          ? Column(
              children: [
                Container(height: 10, color: const Color(0xFFE0E2E5)),
                const SizedBox(height: 3),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: const Color(0xFFE0E2E5),
                          child: Column(
                            children: [
                              const SizedBox(height: 5),
                              line(15),
                              const SizedBox(height: 4),
                              line(18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          children: [
                            line(24, shade: color),
                            const SizedBox(height: 5),
                            line(21),
                            const SizedBox(height: 3),
                            line(24),
                            const SizedBox(height: 3),
                            line(20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : id == 'navy'
          ? Row(
              children: [
                Expanded(
                  child: Container(
                    color: color,
                    padding: const EdgeInsets.all(3),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 6,
                          backgroundColor: Color(0xFF2F7885),
                        ),
                        const SizedBox(height: 5),
                        line(16, shade: Colors.white),
                        const SizedBox(height: 4),
                        line(14, shade: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      line(23, shade: color),
                      const SizedBox(height: 4),
                      line(18),
                      const SizedBox(height: 4),
                      line(22, shade: color),
                      const SizedBox(height: 3),
                      line(23),
                      const SizedBox(height: 3),
                      line(18),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: color,
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 7,
                          backgroundColor: Color(0xFFF2AB37),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              line(18, shade: Colors.white),
                              const SizedBox(height: 3),
                              line(15, shade: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            line(21, shade: color),
                            const SizedBox(height: 4),
                            line(22),
                            const SizedBox(height: 3),
                            line(18),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFE2E4E5),
                          padding: const EdgeInsets.all(2),
                          child: Column(
                            children: [
                              line(14, shade: color),
                              const SizedBox(height: 3),
                              line(15),
                              const SizedBox(height: 3),
                              line(12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPersonalInformationEditor() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1E),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFECEEEF),
                    backgroundImage:
                        appState.profilePhotoPath.isNotEmpty &&
                            File(appState.profilePhotoPath).existsSync()
                        ? FileImage(File(appState.profilePhotoPath))
                        : null,
                    child: appState.profilePhotoPath.isEmpty
                        ? const Icon(Icons.person_outline_rounded, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  OutlinedButton.icon(
                    onPressed: _chooseProfilePhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      appState.profilePhotoPath.isEmpty
                          ? 'Add profile photo'
                          : 'Change photo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roleController,
                decoration: _resumeInputDecoration('Professional Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _websiteController,
                decoration: _resumeInputDecoration('Website / Portfolio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkedInController,
                decoration: _resumeInputDecoration('LinkedIn'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _summaryController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Professional Summary',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    appState.updatePersonalInfo(
                      name: _nameController.text.trim(),
                      email: _emailController.text.trim(),
                      phone: _phoneController.text.trim(),
                      location: _locationController.text.trim(),
                      summary: _summaryController.text.trim(),
                    );
                    appState.updateResumeExtras(
                      role: _roleController.text,
                      website: _websiteController.text,
                      linkedIn: _linkedInController.text,
                      updatedLanguages: appState.languages,
                      updatedProjects: appState.projects,
                      updatedReferences: appState.references,
                      updatedInterests: appState.interests,
                    );
                    showAppToast(
                      context,
                      'Personal information updated successfully!',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Personal Info',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildExperienceEditor() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        ...appState.experiences.asMap().entries.map((entry) {
          int index = entry.key;
          var exp = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCE8B2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${exp.company}   ${exp.period}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          appState.removeExperience(index);
                          showAppToast(context, 'Experience removed');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...exp.bullets.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '•  $b',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _showAddExperienceDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add Another Experience',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEducationEditor() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        ...appState.educations.asMap().entries.map((entry) {
          int index = entry.key;
          var edu = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
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
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF6C5CE7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu.school,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          edu.degree,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${edu.period} • ${edu.gpa}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      appState.removeEducation(index);
                      showAppToast(context, 'Education removed');
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _showAddEducationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add Education',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSkillsEditor() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Professional Skills',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add relevant keywords to boost your ATS score.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: appState.skills
                    .map(
                      (skill) => Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: const Color(0xFFEFEBFF),
                        labelStyle: const TextStyle(color: Color(0xFF6C5CE7)),
                        deleteIcon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF6C5CE7),
                        ),
                        onDeleted: () {
                          appState.removeSkill(skill);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _showAddSkillDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add New Skill',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Additional Resume Sections',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter one item per line. Empty sections are omitted from your PDF.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              _extraResumeField(_languagesController, 'Languages'),
              _extraResumeField(_projectsController, 'Projects / Certificates'),
              _extraResumeField(_referencesController, 'References'),
              _extraResumeField(_interestsController, 'Interests'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    appState.updateResumeExtras(
                      role: _roleController.text,
                      website: _websiteController.text,
                      linkedIn: _linkedInController.text,
                      updatedLanguages: _splitLines(_languagesController.text),
                      updatedProjects: _splitLines(_projectsController.text),
                      updatedReferences: _splitLines(
                        _referencesController.text,
                      ),
                      updatedInterests: _splitLines(_interestsController.text),
                    );
                    showAppToast(context, 'Additional resume sections saved.');
                  },
                  child: const Text('Save Additional Sections'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  InputDecoration _resumeInputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF7F7F9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _extraResumeField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          minLines: 1,
          maxLines: 3,
          decoration: _resumeInputDecoration(label),
        ),
      );

  List<String> _splitLines(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _templateColor(appState.resumeTemplateId),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1E),
                      ),
                    ),
                    Text(
                      appState.userRole,
                      style: TextStyle(
                        fontSize: 13,
                        color: _templateColor(appState.resumeTemplateId),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appState.userEmail,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _templateColor(appState.resumeTemplateId)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Resume Preview',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _templateColor(appState.resumeTemplateId),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                appState.userPhone,
                appState.userLocation,
                appState.userWebsite,
                appState.userLinkedIn,
              ].where((value) => value.trim().isNotEmpty).join('  •  '),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const Divider(height: 28),
            const Text(
              'PROFESSIONAL SUMMARY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C5CE7),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appState.userSummary,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'EXPERIENCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C5CE7),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...appState.experiences.map(
              (exp) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          exp.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1E),
                          ),
                        ),
                        Text(
                          exp.period,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      exp.company,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...exp.bullets.map(
                      (b) => Text(
                        '• $b',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'EDUCATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C5CE7),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...appState.educations.map(
              (edu) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          edu.school,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1E),
                          ),
                        ),
                        Text(
                          edu.period,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${edu.degree} • ${edu.gpa}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'SKILLS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _templateColor(appState.resumeTemplateId),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: appState.skills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _templateColor(appState.resumeTemplateId)
                            .withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1E),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            _previewExtraSection('LANGUAGES', appState.languages),
            _previewExtraSection('PROJECTS & CERTIFICATES', appState.projects),
            _previewExtraSection('REFERENCES', appState.references),
            _previewExtraSection('INTERESTS', appState.interests),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _previewExtraSection(String title, List<String> values) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _templateColor(appState.resumeTemplateId),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          ...values.map(
            (value) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '• $value',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizeTab(int score) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Resume Quality Checklist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$score% Score',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Profile completeness: $score%. These checks are based on the information in your resume.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              ..._resumeTips().map(_buildAiTip),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AtsScannerScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Compare with a job description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAiTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1A1E),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String text, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1E) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(IconData icon, String title, int index) {
    bool isSelected = _selectedStep == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedStep = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFEBFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[400],
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

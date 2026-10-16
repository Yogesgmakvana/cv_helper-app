import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExperienceModel {
  String title;
  String company;
  String period;
  List<String> bullets;

  ExperienceModel({
    required this.title,
    required this.company,
    required this.period,
    required this.bullets,
  });

  Map<String, Object?> toJson() => {
    'title': title,
    'company': company,
    'period': period,
    'bullets': bullets,
  };

  factory ExperienceModel.fromJson(Map<String, dynamic> json) =>
      ExperienceModel(
        title: json['title'] as String? ?? '',
        company: json['company'] as String? ?? '',
        period: json['period'] as String? ?? '',
        bullets: (json['bullets'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toList(),
      );
}

class EducationModel {
  String school;
  String degree;
  String period;
  String gpa;

  EducationModel({
    required this.school,
    required this.degree,
    required this.period,
    required this.gpa,
  });

  Map<String, Object?> toJson() => {
    'school': school,
    'degree': degree,
    'period': period,
    'gpa': gpa,
  };

  factory EducationModel.fromJson(Map<String, dynamic> json) => EducationModel(
    school: json['school'] as String? ?? '',
    degree: json['degree'] as String? ?? '',
    period: json['period'] as String? ?? '',
    gpa: json['gpa'] as String? ?? '',
  );
}

class DocumentModel {
  String title;
  String updatedAt;
  int atsScore;

  DocumentModel({
    required this.title,
    required this.updatedAt,
    required this.atsScore,
  });

  Map<String, Object?> toJson() => {
    'title': title,
    'updatedAt': updatedAt,
    'atsScore': atsScore,
  };

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    title: json['title'] as String? ?? 'Resume',
    updatedAt: json['updatedAt'] as String? ?? 'Recently updated',
    atsScore: (json['atsScore'] as num?)?.toInt() ?? 0,
  );
}

class AppNotificationModel {
  final String title;
  final String message;
  final String location;
  final String createdAt;

  const AppNotificationModel({
    required this.title,
    required this.message,
    required this.location,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
    'title': title,
    'message': message,
    'location': location,
    'createdAt': createdAt,
  };

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) =>
      AppNotificationModel(
        title: json['title'] as String? ?? 'Notification',
        message: json['message'] as String? ?? '',
        location: json['location'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class AppState extends ChangeNotifier {
  static const _storageKey = 'cv_helper_app_state_v1';
  String userName = 'James';
  String userEmail = 'james.designer@example.com';
  String userPhone = '+1 (555) 234-5678';
  String userLocation = 'San Francisco, CA';
  String userRole = 'Senior Product Designer';
  String userWebsite = '';
  String userLinkedIn = '';
  String profilePhotoPath = '';
  String resumeTemplateId = 'violet';
  String userSummary =
      'Passionate Senior Product Designer with 6+ years of experience crafting intuitive digital products and scaling design systems.';

  final List<ExperienceModel> experiences = [
    ExperienceModel(
      title: 'Senior Product Designer',
      company: 'Meizun Studio',
      period: '2024-Present',
      bullets: [
        'Designer and launched 12+ product.',
        'Improve user engagement by 35% through intuitive UI/UX design.',
      ],
    ),
    ExperienceModel(
      title: 'UI/UX Designer',
      company: 'Meizun Studio',
      period: '2023-2024',
      bullets: [
        'Designer and launched 12+ product used by 500k+ users worldwide.',
        'Improve user engagement by 35%.',
      ],
    ),
  ];

  final List<EducationModel> educations = [
    EducationModel(
      school: 'Stanford University',
      degree: 'B.S. in Human-Computer Interaction',
      period: '2019 - 2023',
      gpa: '3.8 GPA',
    ),
  ];

  final List<String> skills = [
    'UI/UX Design',
    'Figma',
    'Flutter',
    'User Research',
    'Prototyping',
    'Design Systems',
    'Dart',
    'Agile Methodology',
  ];
  final List<String> languages = [];
  final List<String> projects = [];
  final List<String> references = [];
  final List<String> interests = [];

  final List<DocumentModel> documents = [
    DocumentModel(
      title: 'Product Designer',
      updatedAt: 'Update 2h ago',
      atsScore: 92,
    ),
    DocumentModel(
      title: 'Mobile App Developer',
      updatedAt: 'Update 1d ago',
      atsScore: 88,
    ),
  ];
  final List<AppNotificationModel> notifications = [];

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedState = preferences.getString(_storageKey);
    if (savedState == null) return;

    try {
      final data = jsonDecode(savedState) as Map<String, dynamic>;
      userName = data['userName'] as String? ?? userName;
      userEmail = data['userEmail'] as String? ?? userEmail;
      userPhone = data['userPhone'] as String? ?? userPhone;
      userLocation = data['userLocation'] as String? ?? userLocation;
      userRole = data['userRole'] as String? ?? userRole;
      userWebsite = data['userWebsite'] as String? ?? userWebsite;
      userLinkedIn = data['userLinkedIn'] as String? ?? userLinkedIn;
      profilePhotoPath =
          data['profilePhotoPath'] as String? ?? profilePhotoPath;
      resumeTemplateId =
          data['resumeTemplateId'] as String? ?? resumeTemplateId;
      userSummary = data['userSummary'] as String? ?? userSummary;
      _replaceList(experiences, data['experiences'], ExperienceModel.fromJson);
      _replaceList(educations, data['educations'], EducationModel.fromJson);
      _replaceList(documents, data['documents'], DocumentModel.fromJson);
      _replaceList(
        notifications,
        data['notifications'],
        AppNotificationModel.fromJson,
      );
      final savedSkills = data['skills'];
      if (savedSkills is List) {
        skills
          ..clear()
          ..addAll(savedSkills.whereType<String>());
      }
      _replaceStringList(languages, data['languages']);
      _replaceStringList(projects, data['projects']);
      _replaceStringList(references, data['references']);
      _replaceStringList(interests, data['interests']);
      notifyListeners();
    } on FormatException {
      await preferences.remove(_storageKey);
    } on TypeError {
      await preferences.remove(_storageKey);
    }
  }

  void _replaceStringList(List<String> target, Object? value) {
    if (value is! List) return;
    target
      ..clear()
      ..addAll(value.whereType<String>());
  }

  void _replaceList<T>(
    List<T> destination,
    Object? value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value is! List) return;
    destination
      ..clear()
      ..addAll(value.whereType<Map<String, dynamic>>().map(decode));
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'userLocation': userLocation,
        'userRole': userRole,
        'userWebsite': userWebsite,
        'userLinkedIn': userLinkedIn,
        'profilePhotoPath': profilePhotoPath,
        'resumeTemplateId': resumeTemplateId,
        'userSummary': userSummary,
        'experiences': experiences.map((item) => item.toJson()).toList(),
        'educations': educations.map((item) => item.toJson()).toList(),
        'skills': skills,
        'languages': languages,
        'projects': projects,
        'references': references,
        'interests': interests,
        'documents': documents.map((item) => item.toJson()).toList(),
        'notifications': notifications.map((item) => item.toJson()).toList(),
      }),
    );
  }

  void addExperience(ExperienceModel exp) {
    experiences.insert(0, exp);
    notifyListeners();
    unawaited(_persist());
  }

  void removeExperience(int index) {
    experiences.removeAt(index);
    notifyListeners();
    unawaited(_persist());
  }

  void addEducation(EducationModel edu) {
    educations.insert(0, edu);
    notifyListeners();
    unawaited(_persist());
  }

  void removeEducation(int index) {
    educations.removeAt(index);
    notifyListeners();
    unawaited(_persist());
  }

  void addSkill(String skill) {
    final normalized = skill.trim();
    if (normalized.isNotEmpty &&
        !skills.any(
          (existing) => existing.toLowerCase() == normalized.toLowerCase(),
        )) {
      skills.add(normalized);
      notifyListeners();
      unawaited(_persist());
    }
  }

  void removeSkill(String skill) {
    skills.remove(skill);
    notifyListeners();
    unawaited(_persist());
  }

  void updatePersonalInfo({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String summary,
  }) {
    userName = name;
    userEmail = email;
    userPhone = phone;
    userLocation = location;
    userSummary = summary;
    notifyListeners();
    unawaited(_persist());
  }

  void updateResumeExtras({
    required String role,
    required String website,
    required String linkedIn,
    required List<String> updatedLanguages,
    required List<String> updatedProjects,
    required List<String> updatedReferences,
    required List<String> updatedInterests,
  }) {
    userRole = role.trim();
    userWebsite = website.trim();
    userLinkedIn = linkedIn.trim();
    languages
      ..clear()
      ..addAll(updatedLanguages.where((value) => value.trim().isNotEmpty));
    projects
      ..clear()
      ..addAll(updatedProjects.where((value) => value.trim().isNotEmpty));
    references
      ..clear()
      ..addAll(updatedReferences.where((value) => value.trim().isNotEmpty));
    interests
      ..clear()
      ..addAll(updatedInterests.where((value) => value.trim().isNotEmpty));
    notifyListeners();
    unawaited(_persist());
  }

  void updateProfilePhoto(String path) {
    profilePhotoPath = path;
    notifyListeners();
    unawaited(_persist());
  }

  void addDocument(String title) {
    if (title.trim().isEmpty) return;
    documents.insert(
      0,
      DocumentModel(title: title, updatedAt: 'Just now', atsScore: 90),
    );
    notifyListeners();
    unawaited(_persist());
  }

  void addNotification(AppNotificationModel notification) {
    notifications.insert(0, notification);
    notifyListeners();
    unawaited(_persist());
  }

  void clearNotifications() {
    if (notifications.isEmpty) return;
    notifications.clear();
    notifyListeners();
    unawaited(_persist());
  }

  void applyResumeSample({
    required String templateId,
    required String name,
    required String role,
    required String summary,
    required String company,
    required List<String> bullets,
    required String degree,
    required List<String> sampleSkills,
    String website = '',
    String linkedin = '',
    String secondRole = '',
    String secondCompany = '',
    String secondPeriod = '',
    List<String> secondBullets = const [],
    String school = 'University Name',
    String schoolPeriod = '2018 – 2022',
    List<String> sampleLanguages = const [],
    List<String> sampleProjects = const [],
    List<String> sampleReferences = const [],
    List<String> sampleInterests = const [],
  }) {
    userName = name;
    userRole = role;
    userEmail = 'your.email@example.com';
    userPhone = '+1 (555) 010-2020';
    userLocation = 'City, Country';
    userWebsite = website;
    userLinkedIn = linkedin;
    resumeTemplateId = templateId;
    userSummary = summary;
    experiences
      ..clear()
      ..add(
        ExperienceModel(
          title: role,
          company: company,
          period: '2022 – Present',
          bullets: bullets,
        ),
      );
    if (secondRole.trim().isNotEmpty) {
      experiences.add(
        ExperienceModel(
          title: secondRole,
          company: secondCompany,
          period: secondPeriod,
          bullets: secondBullets,
        ),
      );
    }
    educations
      ..clear()
      ..add(
        EducationModel(
          school: school,
          degree: degree,
          period: schoolPeriod,
          gpa: '',
        ),
      );
    skills
      ..clear()
      ..addAll(sampleSkills);
    languages
      ..clear()
      ..addAll(sampleLanguages);
    projects
      ..clear()
      ..addAll(sampleProjects);
    references
      ..clear()
      ..addAll(sampleReferences);
    interests
      ..clear()
      ..addAll(sampleInterests);
    notifyListeners();
    unawaited(_persist());
  }

  void updateProfile(String name, String email) {
    userName = name;
    userEmail = email;
    notifyListeners();
    unawaited(_persist());
  }

  int get averageAtsScore {
    if (documents.isEmpty) return 90;
    int sum = documents.fold(0, (acc, doc) => acc + doc.atsScore);
    return (sum / documents.length).round();
  }
}

final appState = AppState();

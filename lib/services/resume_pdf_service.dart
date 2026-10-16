import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_state.dart';

class ResumePdfService {
  static final double _pageContentWidth = PdfPageFormat.a4.width - 56;
  static const MethodChannel _androidDownloads = MethodChannel(
    'cv_helper/downloads',
  );

  static Future<String?> export(AppState state, String name) async {
    final pdfTheme = await _loadPdfTheme();
    final document = pw.Document();
    var palette = _Palette.forId(state.resumeTemplateId);
    if (state.profilePhotoPath.isNotEmpty) {
      final photo = File(state.profilePhotoPath);
      if (await photo.exists()) {
        palette = palette.withPhoto(pw.MemoryImage(await photo.readAsBytes()));
      }
    }
    document.addPage(_templatePage(state, palette, pdfTheme));

    final safeName = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    final baseName = safeName.isEmpty ? 'Resume' : safeName;
    final fileName = baseName.toLowerCase().endsWith('.pdf')
        ? baseName
        : '$baseName.pdf';
    final bytes = await document.save();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidDownloads.invokeMethod<String>('savePdf', {
        'fileName': fileName,
        'bytes': bytes,
      });
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<pw.ThemeData> _loadPdfTheme() async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-bold.ttf'),
    );
    final italic = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-italic.ttf'),
    );
    final boldItalic = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-bolditalic.ttf'),
    );
    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
    );
  }

  static pw.MultiPage _templatePage(
    AppState state,
    _Palette p,
    pw.ThemeData theme,
  ) {
    final content = _needsFlowLayout(state)
        ? _classicLayout(state, p)
        : switch (state.resumeTemplateId) {
            'teal' => _tealLayout(state, p),
            'gray' => _grayLayout(state, p),
            'navy' => _navyLayout(state, p),
            'amber' => _amberLayout(state, p),
            _ => _classicLayout(state, p),
          };
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 30),
      theme: theme,
      build: (_) => content,
    );
  }

  static bool _needsFlowLayout(AppState state) {
    var estimate = 140 + state.userSummary.trim().length / 78 * 12;
    for (final experience in state.experiences) {
      final bullets = experience.bullets
          .where((bullet) => bullet.trim().isNotEmpty)
          .toList();
      if (experience.title.trim().isEmpty &&
          experience.company.trim().isEmpty &&
          bullets.isEmpty) {
        continue;
      }
      estimate += 34;
      for (final bullet in bullets) {
        estimate +=
            (bullet.trim().length / 90).ceil().clamp(1, 100).toInt() * 12 + 3;
      }
    }
    estimate +=
        state.educations
            .where(
              (education) =>
                  education.degree.trim().isNotEmpty ||
                  education.school.trim().isNotEmpty,
            )
            .length *
        42;
    estimate +=
        state.skills.where((skill) => skill.trim().isNotEmpty).length * 15;
    estimate +=
        [
          ...state.languages,
          ...state.projects,
          ...state.references,
          ...state.interests,
        ].where((item) => item.trim().isNotEmpty).length *
        16;
    return estimate > 720;
  }

  static List<pw.Widget> _tealLayout(AppState s, _Palette p) {
    final sidebarWidth = _pageContentWidth * .34;
    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 17, horizontal: 12),
        color: p.primary,
        child: pw.Column(
          children: [
            pw.Text(
              _name(s),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 22,
                letterSpacing: 2.4,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              _role(s).toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: p.pale,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 18),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: sidebarWidth,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(right: 9),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: _avatar(s, p, 62)),
                  _contact(s, p, compact: true),
                  if (s.userSummary.trim().isNotEmpty)
                    _bodySection('Summary', s.userSummary, p),
                  _education(s, p, compact: true),
                  _skills(s.skills, p, bars: true),
                ],
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _experience(s, p),
                  _simpleSection('Languages', s.languages, p),
                  _simpleSection('Projects & Certificates', s.projects, p),
                  _simpleSection('References', s.references, p),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
  }

  static List<pw.Widget> _grayLayout(AppState s, _Palette p) {
    final sidebarWidth = _pageContentWidth * .32;
    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 12),
        color: p.pale,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _name(s),
              style: pw.TextStyle(
                color: p.dark,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _role(s),
              style: pw.TextStyle(
                color: p.muted,
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            if (s.userSummary.trim().isNotEmpty) ...[
              pw.SizedBox(height: 9),
              pw.Text(
                s.userSummary.trim(),
                style: pw.TextStyle(
                  color: p.dark,
                  fontSize: 8.4,
                  lineSpacing: 2,
                ),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: 13),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: sidebarWidth,
            padding: const pw.EdgeInsets.all(11),
            color: p.pale,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _contact(s, p, compact: true),
                _skills(s.skills, p),
                _simpleSection('Certificates', s.projects, p),
                _simpleSection('Languages', s.languages, p),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _experience(s, p, title: 'Work History'),
                _education(s, p),
                _simpleSection('References', s.references, p),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static List<pw.Widget> _navyLayout(AppState s, _Palette p) {
    final sidebarWidth = _pageContentWidth * .28;
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: sidebarWidth,
            padding: const pw.EdgeInsets.all(13),
            color: p.primary,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: _avatar(s, p, 57, reverse: true)),
                _contact(s, p, light: true, compact: true),
                _skills(s.skills, p, light: true),
                _simpleSection('Languages', s.languages, p, light: true),
                _simpleSection('References', s.references, p, light: true),
              ],
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),
                pw.Text(
                  _name(s).toUpperCase(),
                  style: pw.TextStyle(
                    color: p.dark,
                    fontSize: 23,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  _role(s).toUpperCase(),
                  style: pw.TextStyle(
                    color: p.muted,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 15),
                _bodySection('Profile', s.userSummary, p),
                _experience(s, p, timeline: true),
                _education(s, p, timeline: true),
                _simpleSection('Projects & Certificates', s.projects, p),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static List<pw.Widget> _amberLayout(AppState s, _Palette p) {
    final contactWidth = _pageContentWidth * .25;
    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: p.primary,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            _avatar(s, p, 62, reverse: true),
            pw.SizedBox(width: 13),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _name(s),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _role(s),
                    style: pw.TextStyle(color: p.accent, fontSize: 10),
                  ),
                  pw.SizedBox(height: 6),
                  if (s.userSummary.trim().isNotEmpty)
                    pw.Text(
                      s.userSummary.trim(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8,
                        lineSpacing: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.SizedBox(
              width: contactWidth,
              child: _contact(s, p, light: true, compact: true),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 14),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 11,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [_experience(s, p), _education(s, p)],
            ),
          ),
          pw.SizedBox(width: 13),
          pw.Expanded(
            flex: 9,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: p.pale,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _skills(s.skills, p, columns: 2),
                  _simpleSection('Personal Projects', s.projects, p),
                  _simpleSection('Languages', s.languages, p),
                  _simpleSection('Interests', s.interests, p),
                  _simpleSection('References', s.references, p),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
  }

  static List<pw.Widget> _classicLayout(AppState s, _Palette p) => [
    pw.Text(
      _name(s),
      style: pw.TextStyle(
        fontSize: 25,
        fontWeight: pw.FontWeight.bold,
        color: p.dark,
      ),
    ),
    pw.Text(_role(s), style: pw.TextStyle(fontSize: 11, color: p.primary)),
    pw.SizedBox(height: 8),
    _contact(s, p),
    _bodySection('Professional Summary', s.userSummary, p),
    _experience(s, p),
    _education(s, p),
    _skills(s.skills, p),
    _simpleSection('Languages', s.languages, p),
    _simpleSection('Projects & Certificates', s.projects, p),
    _simpleSection('Interests', s.interests, p),
    _simpleSection('References', s.references, p),
  ];

  static pw.Widget _avatar(
    AppState s,
    _Palette p,
    double size, {
    bool reverse = false,
  }) {
    final initials = _name(s)
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: reverse ? p.accent : p.pale,
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: PdfColors.white, width: 2),
      ),
      child: p.photo == null
          ? pw.Text(
              initials,
              style: pw.TextStyle(
                color: reverse ? p.dark : p.primary,
                fontSize: size * .27,
                fontWeight: pw.FontWeight.bold,
              ),
            )
          : pw.ClipOval(
              child: pw.Image(
                p.photo!,
                width: size,
                height: size,
                fit: pw.BoxFit.cover,
              ),
            ),
    );
  }

  static pw.Widget _contact(
    AppState s,
    _Palette p, {
    bool light = false,
    bool compact = false,
  }) {
    final color = light ? PdfColors.white : p.dark;
    final lines = <String>[
      if (s.userPhone.trim().isNotEmpty) 'Phone  ${s.userPhone}',
      if (s.userEmail.trim().isNotEmpty) 'Email  ${s.userEmail}',
      if (s.userLocation.trim().isNotEmpty) 'Address  ${s.userLocation}',
      if (s.userWebsite.trim().isNotEmpty) 'Web  ${s.userWebsite}',
      if (s.userLinkedIn.trim().isNotEmpty) 'LinkedIn  ${s.userLinkedIn}',
    ];
    if (lines.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _section('Contact', p, light: light),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                line,
                style: pw.TextStyle(
                  fontSize: compact ? 8 : 9,
                  color: color,
                  lineSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _section(String title, _Palette p, {bool light = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.3,
                color: light ? p.accent : p.primary,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: .7,
              width: double.infinity,
              color: light ? p.muted : p.pale,
            ),
          ],
        ),
      );

  static pw.Widget _bodySection(
    String title,
    String text,
    _Palette p, {
    bool alignRight = false,
  }) {
    if (text.trim().isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: alignRight
          ? pw.CrossAxisAlignment.end
          : pw.CrossAxisAlignment.start,
      children: [
        _section(title, p),
        pw.Text(
          text.trim(),
          textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(fontSize: 9.2, color: p.dark, lineSpacing: 2),
        ),
      ],
    );
  }

  static pw.Widget _experience(
    AppState s,
    _Palette p, {
    String title = 'Professional Experience',
    bool timeline = false,
  }) {
    final experiences = s.experiences.where((experience) {
      return experience.title.trim().isNotEmpty ||
          experience.company.trim().isNotEmpty ||
          experience.period.trim().isNotEmpty ||
          experience.bullets.any((bullet) => bullet.trim().isNotEmpty);
    }).toList();
    if (experiences.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _section(title, p),
        ...experiences.map(
          (experience) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 9),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (timeline)
                  pw.Container(
                    width: 8,
                    height: 8,
                    margin: const pw.EdgeInsets.only(top: 2, right: 6),
                    decoration: pw.BoxDecoration(
                      color: p.accent,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (experience.title.trim().isNotEmpty)
                            pw.Expanded(
                              child: pw.Text(
                                experience.title.trim(),
                                style: pw.TextStyle(
                                  fontSize: 9.8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: p.dark,
                                ),
                              ),
                            ),
                          if (experience.period.trim().isNotEmpty) ...[
                            pw.SizedBox(width: 4),
                            pw.Flexible(
                              child: pw.Text(
                                experience.period.trim(),
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: p.muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (experience.company.trim().isNotEmpty)
                        pw.Text(
                          experience.company.trim(),
                          style: pw.TextStyle(
                            fontSize: 8.8,
                            color: p.muted,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ...experience.bullets
                          .where((bullet) => bullet.trim().isNotEmpty)
                          .map(
                            (bullet) => pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '• ',
                                    style: pw.TextStyle(
                                      color: p.accent,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      bullet.trim(),
                                      style: pw.TextStyle(
                                        fontSize: 8.8,
                                        color: p.dark,
                                        lineSpacing: 1.5,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _education(
    AppState s,
    _Palette p, {
    bool compact = false,
    bool timeline = false,
  }) {
    final educations = s.educations.where((education) {
      return education.degree.trim().isNotEmpty ||
          education.school.trim().isNotEmpty ||
          education.period.trim().isNotEmpty ||
          education.gpa.trim().isNotEmpty;
    }).toList();
    if (educations.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _section('Education', p),
        ...educations.map(
          (education) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (timeline)
                  pw.Container(
                    width: 8,
                    height: 8,
                    margin: const pw.EdgeInsets.only(top: 2, right: 6),
                    decoration: pw.BoxDecoration(
                      color: p.accent,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (education.degree.trim().isNotEmpty)
                        pw.Text(
                          education.degree.trim(),
                          style: pw.TextStyle(
                            fontSize: compact ? 8 : 9.3,
                            fontWeight: pw.FontWeight.bold,
                            color: p.dark,
                          ),
                        ),
                      if (education.school.trim().isNotEmpty)
                        pw.Text(
                          education.school.trim(),
                          style: pw.TextStyle(
                            fontSize: compact ? 7.8 : 8.8,
                            color: p.muted,
                          ),
                        ),
                      if ([
                        education.period,
                        education.gpa,
                      ].any((value) => value.trim().isNotEmpty))
                        pw.Text(
                          [education.period, education.gpa]
                              .where((value) => value.trim().isNotEmpty)
                              .join('  ·  '),
                          style: pw.TextStyle(fontSize: 7.8, color: p.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _skills(
    List<String> skills,
    _Palette p, {
    bool bars = false,
    bool light = false,
    int columns = 1,
  }) {
    final visibleSkills = skills
        .where((skill) => skill.trim().isNotEmpty)
        .toList();
    if (visibleSkills.isEmpty) return pw.SizedBox();
    final color = light ? PdfColors.white : p.dark;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _section('Relevant Skills', p, light: light),
        if (columns == 1)
          ...visibleSkills.asMap().entries.map((entry) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: bars
                  ? pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Text(
                          entry.value.trim(),
                          style: pw.TextStyle(fontSize: 8, color: color),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Container(height: .8, color: p.pale),
                      ],
                    )
                  : pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          margin: const pw.EdgeInsets.only(top: 3, right: 6),
                          decoration: pw.BoxDecoration(
                            color: p.accent,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            entry.value.trim(),
                            style: pw.TextStyle(fontSize: 8.2, color: color),
                          ),
                        ),
                      ],
                    ),
            );
          })
        else
          pw.Wrap(
            spacing: 5,
            runSpacing: 5,
            children: visibleSkills
                .map(
                  (skill) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(3),
                      ),
                    ),
                    child: pw.Text(
                      skill,
                      style: pw.TextStyle(fontSize: 8, color: p.dark),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  static pw.Widget _simpleSection(
    String title,
    List<String> items,
    _Palette p, {
    bool light = false,
  }) {
    final visibleItems = items.where((item) => item.trim().isNotEmpty).toList();
    if (visibleItems.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _section(title, p, light: light),
        ...visibleItems.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(color: p.accent)),
                pw.Expanded(
                  child: pw.Text(
                    item.trim(),
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: light ? PdfColors.white : p.dark,
                      lineSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _name(AppState s) =>
      s.userName.trim().isEmpty ? 'Your Name' : s.userName;
  static String _role(AppState s) =>
      s.userRole.trim().isEmpty ? 'Professional Title' : s.userRole;
}

class _Palette {
  final PdfColor primary, dark, muted, pale, accent;
  final pw.ImageProvider? photo;
  const _Palette(
    this.primary,
    this.dark,
    this.muted,
    this.pale,
    this.accent, {
    this.photo,
  });

  _Palette withPhoto(pw.ImageProvider image) =>
      _Palette(primary, dark, muted, pale, accent, photo: image);

  factory _Palette.forId(String id) => switch (id) {
    'teal' => _Palette(
      PdfColor.fromHex('#2D687A'),
      PdfColor.fromHex('#303A3F'),
      PdfColor.fromHex('#657078'),
      PdfColor.fromHex('#D9E6E9'),
      PdfColor.fromHex('#2D687A'),
    ),
    'gray' => _Palette(
      PdfColor.fromHex('#3A3D43'),
      PdfColor.fromHex('#282B30'),
      PdfColor.fromHex('#5F6369'),
      PdfColor.fromHex('#E8E9EC'),
      PdfColor.fromHex('#454A52'),
    ),
    'navy' => _Palette(
      PdfColor.fromHex('#293D4C'),
      PdfColor.fromHex('#26323B'),
      PdfColor.fromHex('#66727A'),
      PdfColor.fromHex('#DCE3E7'),
      PdfColor.fromHex('#2F7885'),
    ),
    'amber' => _Palette(
      PdfColor.fromHex('#213846'),
      PdfColor.fromHex('#26343D'),
      PdfColor.fromHex('#63717A'),
      PdfColor.fromHex('#ECEEEF'),
      PdfColor.fromHex('#F2AB37'),
    ),
    _ => _Palette(
      PdfColor.fromHex('#20233A'),
      PdfColor.fromHex('#20233A'),
      PdfColor.fromHex('#68707A'),
      PdfColor.fromHex('#E6E1FA'),
      PdfColor.fromHex('#6C5CE7'),
    ),
  };
}

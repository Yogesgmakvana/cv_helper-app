import '../models/ats_result.dart';

class AtsScannerService {
  static const List<String> skillDictionary = [
    'flutter', 'dart', 'firebase', 'rest apis', 'getx', 'provider', 'bloc',
    'git', 'sql', 'unit testing', 'ci/cd', 'responsive ui', 'state management',
    'ui/ux design', 'figma', 'agile', 'tailwind', 'react', 'node.js', 'python',
    'kotlin', 'swift', 'javascript', 'typescript', 'html', 'css', 'java', 'c++',
    'c#', '.net', 'aws', 'azure', 'gcp', 'docker', 'kubernetes', 'graphql',
    'machine learning', 'data analysis', 'data visualization', 'excel', 'power bi',
    'tableau', 'product management', 'project management', 'user research',
    'prototyping', 'design systems', 'communication', 'leadership', 'problem solving',
    'customer service', 'sales', 'marketing', 'writing', 'financial analysis',
    'accounting', 'recruiting', 'time management', 'collaboration',
  ];

  static const Set<String> _stopWords = {
    'about', 'after', 'also', 'and', 'are', 'based', 'been', 'being', 'build',
    'candidate', 'company', 'considered', 'currently', 'experience', 'for', 'from',
    'have', 'including', 'into', 'job', 'looking', 'must', 'our', 'required',
    'requirements', 'role', 'should', 'skills', 'team', 'that', 'their', 'this',
    'through', 'using', 'want', 'will', 'with', 'work', 'working', 'years',
  };

  static Future<AtsResult> analyzeResume({
    required String fileName,
    required int fileSizeKb,
    required String resumeText,
    required String jobDescription,
  }) async {
    final resume = _normalize(resumeText);
    final job = _normalize(jobDescription);
    final requested = skillDictionary.map(_normalize).where((skill) => skill.isNotEmpty && _containsPhrase(job, skill)).toSet().toList();

    // When the job description uses skills outside the built-in vocabulary,
    // compare its meaningful terms instead of inventing a default skill list.
    if (requested.isEmpty) {
      requested.addAll(
        job.split(' ').where((word) => word.length >= 4 && !_stopWords.contains(word)).toSet().take(20),
      );
    }

    final matched = requested.where((term) => _containsPhrase(resume, term)).toList();
    final missing = requested.where((term) => !_containsPhrase(resume, term)).toList();
    final detectedSkills = skillDictionary
        .where((skill) => _containsPhrase(resume, _normalize(skill)))
        .map((skill) => skill.toUpperCase())
        .toList();

    final hasEmail = RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}').hasMatch(resumeText);
    final hasPhone = RegExp(r'(?:\+?\d[\d ().-]{6,}\d)').hasMatch(resumeText);
    final sections = <String, bool>{
      'Contact Information': hasEmail && hasPhone,
      'Professional Summary': _hasAny(resume, ['summary', 'profile', 'objective']),
      'Skills': _hasAny(resume, ['skills', 'technical skills', 'core competencies']),
      'Work Experience': _hasAny(resume, ['experience', 'employment', 'work history']),
      'Education': _hasAny(resume, ['education', 'degree', 'university', 'college']),
      'Projects': _hasAny(resume, ['projects', 'selected projects', 'portfolio']),
    };
    final requiredSections = sections.entries.where((entry) => entry.key != 'Projects').toList();
    final sectionScore = requiredSections.where((entry) => entry.value).length / requiredSections.length;
    final keywordScore = requested.isEmpty ? 0.0 : matched.length / requested.length;
    final score = ((keywordScore * .8 + sectionScore * .2) * 100).round().clamp(0, 100);

    final suggestions = <String>[];
    if (missing.isNotEmpty) {
      suggestions.add('If accurate to your experience, add these job terms where they fit naturally: ${missing.take(5).join(', ')}.');
    }
    if (!sections['Professional Summary']!) suggestions.add('Add a clearly labeled Professional Summary or Profile section.');
    if (!sections['Work Experience']!) suggestions.add('Use a standard Work Experience heading and include relevant roles and outcomes.');
    if (!sections['Education']!) suggestions.add('Add an Education section with your qualification and institution.');
    if (!hasEmail || !hasPhone) suggestions.add('Place a valid email address and phone number near the top of your resume.');
    if (suggestions.isEmpty) suggestions.add('Your resume covers the detected job terms and standard sections. Tailor your achievement bullets to the role.');

    final readabilityChecks = <String, bool>{
      'Text Extractable': resumeText.trim().isNotEmpty,
      'Readable Text Length': resumeText.trim().length >= 100,
      'Email Address Detected': hasEmail,
      'Phone Number Detected': hasPhone,
      'Standard Headings Identified': sections.values.where((found) => found).length >= 3,
    };

    final warnings = <String>[];
    if (fileSizeKb > 5000) warnings.add('The file is larger than 5 MB; some employer portals may have smaller limits.');
    if (requested.isEmpty) warnings.add('No usable job terms were found. Add a fuller job description for a more meaningful comparison.');
    if (resumeText.trim().length < 100) warnings.add('Only a small amount of readable text was extracted from this file.');

    return AtsResult(
      fileName: fileName,
      fileSizeKb: fileSizeKb,
      matchScore: score,
      matchedKeywords: matched.map((term) => term.toUpperCase()).toList(),
      missingKeywords: missing.map((term) => term.toUpperCase()).toList(),
      detectedSkills: detectedSkills,
      sectionStatuses: sections.map((name, found) => MapEntry(name, found ? 'Found' : 'Needs Review')),
      readabilityChecks: readabilityChecks,
      improvementSuggestions: suggestions,
      analysisWarnings: warnings,
      jobDescription: jobDescription,
    );
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+#]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static bool _containsPhrase(String text, String phrase) =>
      text.contains(' $phrase ') || text.startsWith('$phrase ') || text.endsWith(' $phrase') || text == phrase;

  static bool _hasAny(String text, List<String> terms) =>
      terms.any((term) => _containsPhrase(text, _normalize(term)));
}

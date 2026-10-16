class AtsResult {
  final String fileName;
  final int fileSizeKb;
  final int matchScore;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> detectedSkills;
  final Map<String, String> sectionStatuses; // e.g. "Contact Info": "Found"
  final Map<String, bool> readabilityChecks; // e.g. "Text Extractable": true
  final List<String> improvementSuggestions;
  final List<String> analysisWarnings;
  final String jobDescription;

  AtsResult({
    required this.fileName,
    required this.fileSizeKb,
    required this.matchScore,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.detectedSkills,
    required this.sectionStatuses,
    required this.readabilityChecks,
    required this.improvementSuggestions,
    required this.analysisWarnings,
    required this.jobDescription,
  });
}

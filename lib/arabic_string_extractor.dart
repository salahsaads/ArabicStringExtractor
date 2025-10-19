import 'dart:io';
import 'dart:convert';

/// Main class for extracting Arabic strings from Dart files
class ArabicStringExtractor {
  final Directory sourceDirectory;
  final String outputFileName;
  final bool includeInterpolated;
  final List<String> excludedPaths;

  ArabicStringExtractor({
    required this.sourceDirectory,
    this.outputFileName = 'arabic_strings.json',
    this.includeInterpolated = false,
    this.excludedPaths = const [],
  });

  /// Checks if text contains Arabic characters
  bool containsArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  /// Gets all Dart files from directory recursively
  List<FileSystemEntity> getDartFiles(Directory dir) {
    return dir
        .listSync(recursive: true)
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !_isExcluded(f.path))
        .toList();
  }

  /// Checks if path should be excluded
  bool _isExcluded(String path) {
    return excludedPaths.any((excluded) => path.contains(excluded));
  }

  /// Extract Arabic strings from all Dart files
  Future<Map<String, String>> extract() async {
    final dartFiles = getDartFiles(sourceDirectory);
    print('🔍 Found ${dartFiles.length} Dart files');

    final Map<String, String> arabicTexts = {};

    // Patterns to match different string contexts
    final patterns = [
      RegExp(r'''Text\s*\(\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''const\s+Text\s*\(\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''label:\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''hintText:\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''labelText:\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''placeholder:\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''title:\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''content:\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''message:\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''text:\s*['"](.*?)['"]\s*[,\)]''', multiLine: true),
      RegExp(r'''['"]([^'"]*[\u0600-\u06FF][^'"]*)['"]''', multiLine: true),
    ];

    for (final file in dartFiles) {
      if (file is! File) continue;

      try {
        final content = await File(file.path).readAsString();

        for (final pattern in patterns) {
          for (final match in pattern.allMatches(content)) {
            final text = match.group(1)?.trim() ?? '';

            if (_isValidText(text)) {
              if (containsArabic(text)) {
                arabicTexts[text] = text;
              }
            }
          }
        }
      } catch (e) {
        print('⚠️  Error reading file ${file.path}: $e');
      }
    }

    return arabicTexts;
  }

  /// Validates if text should be included
  bool _isValidText(String text) {
    if (text.length <= 1) return false;
    if (text.startsWith('http')) return false;
    if (text.startsWith('assets/')) return false;
    if (!includeInterpolated && text.contains('\$')) return false;
    if (text.contains(RegExp(r'^[0-9]+$'))) return false;
    if (text.contains('(') || text.contains(')')) return false;
    if (text.contains('{') || text.contains('}')) return false;
    if (text.contains('AppLocalizations.of')) return false;

    return true;
  }

  /// Extract and save to JSON file
  Future<void> extractAndSave() async {
    final arabicTexts = await extract();
    final outputFile = File('${sourceDirectory.path}/$outputFileName');

    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(arabicTexts),
    );

    print('✅ Found ${arabicTexts.length} Arabic strings');
    print('✅ Saved to: ${outputFile.path}');
  }

  /// Extract and return formatted output
  Future<String> extractAsJson() async {
    final arabicTexts = await extract();
    return const JsonEncoder.withIndent('  ').convert(arabicTexts);
  }

  /// Extract with custom key generation
  Future<Map<String, String>> extractWithKeys({
    required String Function(String text, int index) keyGenerator,
  }) async {
    final arabicTexts = await extract();
    final Map<String, String> result = {};

    int index = 0;
    for (final text in arabicTexts.keys) {
      final key = keyGenerator(text, index);
      result[key] = text;
      index++;
    }

    return result;
  }
}

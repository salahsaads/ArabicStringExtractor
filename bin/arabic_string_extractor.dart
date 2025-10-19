#!/usr/bin/env dart

import 'dart:io';
import 'package:arabic_string_extractor/arabic_string_extractor.dart';

void main(List<String> arguments) async {
  print('🚀 Arabic String Extractor v1.0.0\n');

  // Parse arguments
  String? targetPath;
  String outputFile = 'arabic_strings.json';
  List<String> excludedPaths = [];

  for (int i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--path' && i + 1 < arguments.length) {
      targetPath = arguments[i + 1];
    } else if (arguments[i] == '--output' && i + 1 < arguments.length) {
      outputFile = arguments[i + 1];
    } else if (arguments[i] == '--exclude' && i + 1 < arguments.length) {
      excludedPaths = arguments[i + 1].split(',');
    } else if (arguments[i] == '--help' || arguments[i] == '-h') {
      _printHelp();
      return;
    }
  }

  // Use current directory if no path specified
  final directory = targetPath != null
      ? Directory(targetPath)
      : Directory.current;

  if (!directory.existsSync()) {
    print('❌ Error: Directory does not exist: ${directory.path}');
    exit(1);
  }

  print('📁 Scanning directory: ${directory.path}');
  if (excludedPaths.isNotEmpty) {
    print('🚫 Excluding paths: ${excludedPaths.join(", ")}');
  }
  print('');

  final extractor = ArabicStringExtractor(
    sourceDirectory: directory,
    outputFileName: outputFile,
    excludedPaths: excludedPaths,
  );

  try {
    await extractor.extractAndSave();
    print('\n🎉 Extraction complete!');
  } catch (e) {
    print('❌ Error during extraction: $e');
    exit(1);
  }
}

void _printHelp() {
  print('''
Usage: dart run arabic_string_extractor [options]

Options:
  --path <directory>      Target directory to scan (default: current directory)
  --output <filename>     Output JSON file name (default: arabic_strings.json)
  --exclude <paths>       Comma-separated paths to exclude (e.g., "test,build")
  --help, -h              Show this help message

Examples:
  dart run arabic_string_extractor
  dart run arabic_string_extractor --path ./lib
  dart run arabic_string_extractor --output translations.json
  dart run arabic_string_extractor --exclude "test,build,.dart_tool"
  ''');
}

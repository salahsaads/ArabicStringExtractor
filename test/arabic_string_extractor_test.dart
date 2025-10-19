import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_string_extractor/arabic_string_extractor.dart';

void main() {
  group('ArabicStringExtractor Tests', () {
    late Directory testDir;

    setUp(() async {
      // Create temporary test directory
      testDir = await Directory.systemTemp.createTemp('arabic_test_');
    });

    tearDown(() async {
      // Clean up test directory
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('containsArabic should detect Arabic characters', () {
      final extractor = ArabicStringExtractor(sourceDirectory: testDir);

      expect(extractor.containsArabic('مرحبا'), true);
      expect(extractor.containsArabic('Hello'), false);
      expect(extractor.containsArabic('Hello مرحبا'), true);
      expect(extractor.containsArabic('123'), false);
      expect(extractor.containsArabic('العربية'), true);
    });

    test('should extract Arabic strings from Text widgets', () async {
      // Create test Dart file
      final testFile = File('${testDir.path}/test_widget.dart');
      await testFile.writeAsString('''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('مرحبا بك'),
        const Text('الصفحة الرئيسية'),
        Text('Hello World'),
      ],
    );
  }
}
      ''');

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final results = await extractor.extract();

      expect(results.containsKey('مرحبا بك'), true);
      expect(results.containsKey('الصفحة الرئيسية'), true);
      expect(results.containsKey('Hello World'), false);
      expect(results.length, 2);
    });

    test('should extract Arabic from TextField properties', () async {
      final testFile = File('${testDir.path}/test_form.dart');
      await testFile.writeAsString('''
import 'package:flutter/material.dart';

class TestForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      hintText: 'أدخل اسمك',
      labelText: 'الاسم',
    );
  }
}
      ''');

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final results = await extractor.extract();

      expect(results.containsKey('أدخل اسمك'), true);
      expect(results.containsKey('الاسم'), true);
      expect(results.length, 2);
    });

    test('should exclude interpolated strings by default', () async {
      final testFile = File('${testDir.path}/test_interpolated.dart');
      await testFile.writeAsString('''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('مرحبا'),
        Text('مرحبا \$name'),
      ],
    );
  }
}
      ''');

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final results = await extractor.extract();

      expect(results.containsKey('مرحبا'), true);
      expect(results.containsKey('مرحبا \$name'), false);
      expect(results.length, 1);
    });

    test('should include interpolated strings when enabled', () async {
      final testFile = File('${testDir.path}/test_interpolated.dart');
      await testFile.writeAsString('''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('مرحبا \$name');
  }
}
      ''');

      final extractor = ArabicStringExtractor(
        sourceDirectory: testDir,
        includeInterpolated: true,
      );
      final results = await extractor.extract();

      expect(results.containsKey('مرحبا \$name'), true);
    });

    test('should exclude specified paths', () async {
      // Create test directory structure
      final excludedDir = Directory('${testDir.path}/excluded');
      await excludedDir.create();

      final includedFile = File('${testDir.path}/included.dart');
      await includedFile.writeAsString("Text('مرحبا')");

      final excludedFile = File('${excludedDir.path}/excluded.dart');
      await excludedFile.writeAsString("Text('العربية')");

      final extractor = ArabicStringExtractor(
        sourceDirectory: testDir,
        excludedPaths: ['excluded'],
      );
      final results = await extractor.extract();

      expect(results.containsKey('مرحبا'), true);
      expect(results.containsKey('العربية'), false);
    });

    test('should filter out URLs and asset paths', () async {
      final testFile = File('${testDir.path}/test_urls.dart');
      await testFile.writeAsString('''
class TestWidget {
  final url = 'https://مثال.com';
  final asset = 'assets/صورة.png';
  final text = 'نص عادي';
}
      ''');

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final results = await extractor.extract();

      expect(results.containsKey('نص عادي'), true);
      expect(results.length, 1);
    });

    test('should extract from various widget properties', () async {
      final testFile = File('${testDir.path}/test_properties.dart');
      await testFile.writeAsString('''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(title: 'العنوان', content: 'المحتوى'),
        Container(label: 'التسمية'),
        Placeholder(message: 'رسالة'),
      ],
    );
  }
}
      ''');

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final results = await extractor.extract();

      expect(results.containsKey('العنوان'), true);
      expect(results.containsKey('المحتوى'), true);
      expect(results.containsKey('التسمية'), true);
      expect(results.containsKey('رسالة'), true);
    });

    test('extractAsJson should return valid JSON', () async {
      final testFile = File('${testDir.path}/test.dart');
      await testFile.writeAsString("Text('مرحبا')");

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final json = await extractor.extractAsJson();

      expect(json, contains('مرحبا'));
      expect(json, contains('{'));
      expect(json, contains('}'));
    });

    test('extractWithKeys should generate custom keys', () async {
      final testFile = File('${testDir.path}/test.dart');
      await testFile.writeAsString('''
        Text('الأول')
        Text('الثاني')
      ''');

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final results = await extractor.extractWithKeys(
        keyGenerator: (text, index) => 'key_$index',
      );

      expect(results.containsKey('key_0'), true);
      expect(results.containsKey('key_1'), true);
      expect(results.values.contains('الأول'), true);
      expect(results.values.contains('الثاني'), true);
    });

    test('should handle empty directory', () async {
      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final results = await extractor.extract();

      expect(results.isEmpty, true);
    });

    test('should handle files with no Arabic text', () async {
      final testFile = File('${testDir.path}/test.dart');
      await testFile.writeAsString('''
        Text('Hello')
        Text('World')
      ''');

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final results = await extractor.extract();

      expect(results.isEmpty, true);
    });

    test('getDartFiles should only return .dart files', () async {
      await File('${testDir.path}/test1.dart').writeAsString('');
      await File('${testDir.path}/test2.dart').writeAsString('');
      await File('${testDir.path}/test.txt').writeAsString('');
      await File('${testDir.path}/test.json').writeAsString('');

      final extractor = ArabicStringExtractor(sourceDirectory: testDir);
      final dartFiles = extractor.getDartFiles(testDir);

      expect(dartFiles.length, 2);
      expect(dartFiles.every((f) => f.path.endsWith('.dart')), true);
    });
  });
}

# Arabic String Extractor 🔍

A Flutter package to automatically extract Arabic strings from your Dart files for easy localization.

## Features ✨

- Extracts all Arabic text from Dart files
- Supports multiple widget types (Text, TextField, etc.)
- Customizable output format
- Exclude specific paths
- Command-line tool included
- Easy integration with existing projects

## Installation 📦

Add this to your `pubspec.yaml`:

```yaml
dev_dependencies:
  arabic_string_extractor: ^0.0.2
```

Then run:

```bash
flutter pub get
```

## Usage 🚀

### Command Line

Extract Arabic strings from current directory:

```bash
dart run arabic_string_extractor
```

Extract from specific directory:

```bash
dart run arabic_string_extractor --path ./lib
```

Custom output file:

```bash
dart run arabic_string_extractor --output my_translations.json
```

Exclude specific paths:

```bash
dart run arabic_string_extractor --exclude "test,build,.dart_tool"
```

### Programmatic Usage

```dart
import 'dart:io';
import 'package:arabic_string_extractor/arabic_string_extractor.dart';

void main() async {
  final extractor = ArabicStringExtractor(
    sourceDirectory: Directory('./lib'),
    outputFileName: 'arabic_strings.json',
    excludedPaths: ['test', 'build'],
  );

  // Extract and save to file
  await extractor.extractAndSave();

  // Or get the results as a Map
  final results = await extractor.extract();
  print('Found ${results.length} Arabic strings');

  // Or get JSON string
  final json = await extractor.extractAsJson();
  print(json);

  // Custom key generation
  final withKeys = await extractor.extractWithKeys(
    keyGenerator: (text, index) => 'arabic_text_$index',
  );
}
```

## Output Format 📄

The extracted strings are saved as JSON:

```json
{
  "مرحبا بك": "مرحبا بك",
  "الصفحة الرئيسية": "الصفحة الرئيسية",
  "إعدادات": "إعدادات"
}
```

## What Gets Extracted? 🎯

The package extracts Arabic text from:

- `Text()` widgets
- `TextField` properties (hintText, labelText)
- Common properties (title, content, message, label)
- Any quoted string containing Arabic characters

It automatically filters out:

- URLs
- Asset paths
- Interpolated strings (with `$`)
- Numbers only
- Already localized strings
- Special characters

## Example 💡

Given this Dart code:

```dart
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصفحة الرئيسية'),
      ),
      body: Column(
        children: [
          Text('مرحبا بك في التطبيق'),
          TextField(
            hintText: 'أدخل اسمك',
            labelText: 'الاسم',
          ),
        ],
      ),
    );
  }
}
```

Output `arabic_strings.json`:

```json
{
  "الصفحة الرئيسية": "الصفحة الرئيسية",
  "مرحبا بك في التطبيق": "مرحبا بك في التطبيق",
  "أدخل اسمك": "أدخل اسمك",
  "الاسم": "الاسم"
}
```

## Configuration Options ⚙️

```dart
ArabicStringExtractor(
  sourceDirectory: Directory('./lib'),    // Directory to scan
  outputFileName: 'arabic_strings.json',  // Output file name
  includeInterpolated: false,             // Include strings with $
  excludedPaths: ['test', 'build'],       // Paths to exclude
)
```

## License 📝

MIT License - feel free to use in your projects!

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues 🐛

Found a bug or have a feature request? Please open an issue on GitHub.

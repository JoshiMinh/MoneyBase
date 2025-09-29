import 'dart:io';

Future<void> main(List<String> args) async {
  final targetPath = args.isNotEmpty ? args.first : '.env';
  final file = File(targetPath);
  final existing = await file.exists() ? await file.readAsLines() : <String>[];

  final preservedLines = <String>[];
  final values = <String, String>{};

  for (final line in existing) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#') || !trimmed.contains('=')) {
      preservedLines.add(line);
      continue;
    }

    final separatorIndex = line.indexOf('=');
    final key = line.substring(0, separatorIndex).trim();
    final value = line.substring(separatorIndex + 1);
    values[key] = value;
  }

  void upsertFromEnvironment(String key, List<String> environmentKeys) {
    for (final environmentKey in environmentKeys) {
      final envValue = Platform.environment[environmentKey];
      if (envValue != null && envValue.trim().isNotEmpty) {
        values[key] = envValue.trim();
        return;
      }
    }

    if (!values.containsKey(key)) {
      values[key] = '';
    }
  }

  upsertFromEnvironment('GEMINI_API_KEY', const [
    'GEMINI_API_KEY',
    'VERCEL_GEMINI_API_KEY',
    'NEXT_PUBLIC_GEMINI_API_KEY',
    'PUBLIC_GEMINI_API_KEY',
  ]);

  upsertFromEnvironment('CLOUDINARY_CLOUD_NAME', const [
    'CLOUDINARY_CLOUD_NAME',
    'VERCEL_CLOUDINARY_CLOUD_NAME',
  ]);
  upsertFromEnvironment('CLOUDINARY_API_KEY', const [
    'CLOUDINARY_API_KEY',
    'VERCEL_CLOUDINARY_API_KEY',
  ]);
  upsertFromEnvironment('CLOUDINARY_API_SECRET', const [
    'CLOUDINARY_API_SECRET',
    'VERCEL_CLOUDINARY_API_SECRET',
  ]);
  upsertFromEnvironment('CLOUDINARY_UPLOAD_PRESET', const [
    'CLOUDINARY_UPLOAD_PRESET',
    'VERCEL_CLOUDINARY_UPLOAD_PRESET',
  ]);

  final buffer = StringBuffer();
  for (final line in preservedLines) {
    buffer.writeln(line);
  }

  if (preservedLines.isNotEmpty) {
    buffer.writeln();
  }

  for (final entry in values.entries) {
    buffer.writeln('${entry.key}=${entry.value}');
  }

  await file.writeAsString(buffer.toString());

  stdout.writeln(
    'Wrote ${values.length} environment entr${values.length == 1 ? 'y' : 'ies'} to ${file.path}.',
  );
}

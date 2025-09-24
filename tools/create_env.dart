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

  final candidateKeys = [
    'GEMINI_API_KEY',
    'VERCEL_GEMINI_API_KEY',
    'NEXT_PUBLIC_GEMINI_API_KEY',
    'PUBLIC_GEMINI_API_KEY',
  ];

  String resolvedKey = '';
  for (final key in candidateKeys) {
    final value = Platform.environment[key];
    if (value != null && value.trim().isNotEmpty) {
      resolvedKey = value.trim();
      break;
    }
  }

  if (resolvedKey.isNotEmpty) {
    values['GEMINI_API_KEY'] = resolvedKey;
  } else {
    stdout.writeln(
      'No GEMINI_API_KEY found in the environment. Existing .env value will be preserved.',
    );
    values.putIfAbsent('GEMINI_API_KEY', () => '');
  }

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

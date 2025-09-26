import 'csv_exporter_stub.dart'
    if (dart.library.html) 'csv_exporter_web.dart'
    if (dart.library.io) 'csv_exporter_io.dart' as exporter;

Future<String?> saveCsvExport({
  required String fileName,
  required String csv,
}) {
  final sanitized = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
  return exporter.saveCsvExport(fileName: sanitized, csv: csv);
}

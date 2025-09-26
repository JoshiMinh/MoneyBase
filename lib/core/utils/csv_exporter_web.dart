import 'dart:convert';
import 'dart:html' as html;

Future<String?> saveCsvExport({
  required String fileName,
  required String csv,
}) async {
  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = '$fileName.csv'
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return '$fileName.csv';
}

import 'dart:convert';
import 'dart:io';

Future<String?> saveCsvExport({
  required String fileName,
  required String csv,
}) async {
  final directory = await Directory.systemTemp.createTemp('moneybase_export_');
  final file = File('${directory.path}/$fileName.csv');
  await file.writeAsString(csv, encoding: utf8);
  return file.path;
}

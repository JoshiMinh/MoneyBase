import 'package:csv/csv.dart';

import '../models/transaction.dart';

String encodeTransactionsCsv(List<MoneyBaseTransaction> transactions) {
  final rows = <List<dynamic>>[
    [
      'id',
      'date',
      'description',
      'amount',
      'currencyCode',
      'isIncome',
      'categoryId',
      'walletId',
      'createdAt',
    ],
  ];

  for (final transaction in transactions) {
    rows.add([
      transaction.id,
      transaction.date.toUtc().toIso8601String(),
      transaction.description,
      transaction.amount,
      transaction.currencyCode,
      transaction.isIncome,
      transaction.categoryId,
      transaction.walletId,
      transaction.createdAt.toUtc().toIso8601String(),
    ]);
  }

  return const ListToCsvConverter().convert(rows);
}

List<MoneyBaseTransaction> decodeTransactionsCsv(String csvSource) {
  final normalized = csvSource.trim();
  if (normalized.isEmpty) {
    return const <MoneyBaseTransaction>[];
  }

  final rows = const CsvToListConverter(eol: '\n')
      .convert(normalized, shouldParseNumbers: false);

  if (rows.isEmpty) {
    return const <MoneyBaseTransaction>[];
  }

  final header = rows.first.map((value) => value.toString().trim()).toList();
  final lookup = <String, int>{};
  for (var index = 0; index < header.length; index++) {
    lookup[header[index].toLowerCase()] = index;
  }

  final requiredKeys = ['date', 'description', 'amount'];
  for (final key in requiredKeys) {
    if (!lookup.containsKey(key)) {
      return const <MoneyBaseTransaction>[];
    }
  }

  final idIndex = lookup['id'];
  final dateIndex = lookup['date']!;
  final descriptionIndex = lookup['description']!;
  final amountIndex = lookup['amount']!;
  final currencyIndex = lookup['currencycode'];
  final isIncomeIndex = lookup['isincome'];
  final categoryIndex = lookup['categoryid'];
  final walletIndex = lookup['walletid'];
  final createdIndex = lookup['createdat'];

  final transactions = <MoneyBaseTransaction>[];

  for (final row in rows.skip(1)) {
    if (row.isEmpty) {
      continue;
    }

    String readValue(int? index) {
      if (index == null || index < 0 || index >= row.length) {
        return '';
      }
      return row[index]?.toString().trim() ?? '';
    }

    final description = readValue(descriptionIndex);
    final amountText = readValue(amountIndex);
    final parsedAmount = double.tryParse(amountText.replaceAll(',', ''));
    if (parsedAmount == null || parsedAmount <= 0) {
      continue;
    }

    final dateText = readValue(dateIndex);
    final parsedDate = DateTime.tryParse(dateText) ?? DateTime.now();
    final createdText = readValue(createdIndex);
    final createdAt =
        createdText.isNotEmpty ? DateTime.tryParse(createdText) : null;

    final isIncomeText = readValue(isIncomeIndex);
    final isIncome = isIncomeText.toLowerCase() == 'true';

    final transaction = MoneyBaseTransaction(
      id: readValue(idIndex),
      description: description,
      amount: parsedAmount,
      currencyCode: readValue(currencyIndex).isNotEmpty
          ? readValue(currencyIndex).toUpperCase()
          : 'USD',
      isIncome: isIncome,
      categoryId: readValue(categoryIndex),
      walletId: readValue(walletIndex),
      date: parsedDate,
      createdAt: createdAt ?? parsedDate,
    );
    transactions.add(transaction);
  }

  return transactions;
}

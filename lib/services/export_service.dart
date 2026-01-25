import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class ExportService {
  static Future<void> exportToCSV(List<Expense> expenses) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Title',
      'Amount',
      'Currency',
      'Category',
      'Date',
      'Description',
      'Recurring'
    ]);

    // Data
    for (var expense in expenses) {
      rows.add([
        expense.title,
        expense.amount,
        expense.currency,
        expense.category,
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.description ?? '',
        expense.isRecurring ? 'Yes' : 'No',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Save to file
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    // Share file
    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv')],
      subject: 'Expense Report',
      text:
          'Expenses exported on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
  }

  static Future<void> exportToExcel(List<Expense> expenses) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Expenses'];

    // Header with styling
    sheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Amount'),
      TextCellValue('Currency'),
      TextCellValue('Category'),
      TextCellValue('Date'),
      TextCellValue('Description'),
      TextCellValue('Recurring'),
    ]);

    // Data rows
    for (var expense in expenses) {
      sheet.appendRow([
        TextCellValue(expense.title),
        DoubleCellValue(expense.amount),
        TextCellValue(expense.currency),
        TextCellValue(expense.category),
        TextCellValue(DateFormat('yyyy-MM-dd').format(expense.date)),
        TextCellValue(expense.description ?? ''),
        TextCellValue(expense.isRecurring ? 'Yes' : 'No'),
      ]);
    }

    // Save to file
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }
    await file.writeAsBytes(bytes);

    // Share file
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Expense Report',
      text:
          'Expenses exported on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
  }

  static Future<String> exportForBackup(List<Expense> expenses) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Backup'];

    // Header
    sheet.appendRow([
      TextCellValue('id'),
      TextCellValue('title'),
      TextCellValue('amount'),
      TextCellValue('currency'),
      TextCellValue('category'),
      TextCellValue('date'),
      TextCellValue('description'),
      TextCellValue('isRecurring'),
      TextCellValue('recurringType'),
      TextCellValue('nextRecurringDate'),
    ]);

    // Full data for restore
    for (var expense in expenses) {
      sheet.appendRow([
        IntCellValue(expense.id ?? 0),
        TextCellValue(expense.title),
        DoubleCellValue(expense.amount),
        TextCellValue(expense.currency),
        TextCellValue(expense.category),
        TextCellValue(expense.date.toIso8601String()),
        TextCellValue(expense.description ?? ''),
        TextCellValue(expense.isRecurring ? '1' : '0'),
        TextCellValue(expense.recurringType ?? ''),
        TextCellValue(expense.nextRecurringDate?.toIso8601String() ?? ''),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }
    await file.writeAsBytes(bytes);

    return path;
  }
}

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  static Future<Map<String, dynamic>> extractFromReceipt(
      String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    String fullText = recognizedText.text;

    // Extract data
    double? amount = _extractAmount(fullText);
    String? date = _extractDate(fullText);
    String? merchantName = _extractMerchantName(recognizedText);

    return {
      'amount': amount,
      'date': date,
      'merchantName': merchantName,
      'fullText': fullText,
    };
  }

  static double? _extractAmount(String text) {
    // Pattern untuk mencari nominal uang
    // Contoh: Rp 50.000, 50000, Rp50,000, Total: 50.000
    RegExp amountPattern = RegExp(
      r'(?:Rp\.?\s*|Total[:\s]*|TOTAL[:\s]*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      caseSensitive: false,
    );

    List<double> amounts = [];

    for (var match in amountPattern.allMatches(text)) {
      String amountStr = match.group(1) ?? '';
      // Remove dots and commas, keep only digits
      amountStr = amountStr.replaceAll(RegExp(r'[.,](?=\d{3})'), '');
      amountStr = amountStr.replaceAll(',', '.');

      double? amount = double.tryParse(amountStr);
      if (amount != null && amount > 0) {
        amounts.add(amount);
      }
    }

    // Return the largest amount (usually the total)
    if (amounts.isNotEmpty) {
      amounts.sort((a, b) => b.compareTo(a));
      return amounts.first;
    }

    return null;
  }

  static String? _extractDate(String text) {
    // Pattern untuk tanggal Indonesia
    RegExp datePattern = RegExp(
      r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})|(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|Mei|Jun|Jul|Agu|Sep|Okt|Nov|Des)[a-z]*\s+\d{2,4})',
      caseSensitive: false,
    );

    var match = datePattern.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  static String? _extractMerchantName(RecognizedText recognizedText) {
    // Usually merchant name is at the top
    if (recognizedText.blocks.isNotEmpty) {
      // Get first 2-3 lines
      List<String> firstLines = [];
      for (var block in recognizedText.blocks.take(3)) {
        for (var line in block.lines) {
          String lineText = line.text.trim();
          if (lineText.isNotEmpty &&
              lineText.length > 3 &&
              !lineText.contains(RegExp(r'\d{4,}'))) {
            firstLines.add(lineText);
          }
        }
      }

      if (firstLines.isNotEmpty) {
        return firstLines.first;
      }
    }

    return null;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}

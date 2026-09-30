import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptScanResult {
  final DateTime? date;
  final String? station;
  final String? fuelType;
  final double? pricePerLitre;
  final double? litres;
  final double? total;
  final String rawText;

  const ReceiptScanResult({
    this.date,
    this.station,
    this.fuelType,
    this.pricePerLitre,
    this.litres,
    this.total,
    required this.rawText,
  });
}

class ReceiptScanService {
  static Future<ReceiptScanResult> scan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(image);
      return parse(result.text);
    } finally {
      await recognizer.close();
    }
  }

  static ReceiptScanResult parse(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final lower = text.toLowerCase();

    DateTime? date;
    for (final pattern in <RegExp>[
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
      RegExp(r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b'),
    ]) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      try {
        if (match.group(1)!.length == 4) {
          date = DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
        } else {
          var year = int.parse(match.group(3)!);
          if (year < 100) year += 2000;
          date = DateTime(year, int.parse(match.group(2)!), int.parse(match.group(1)!));
        }
        break;
      } catch (_) {}
    }

    double? findNumberNear(List<String> labels, {double min = 0, double max = 99999}) {
      for (final line in lines) {
        final l = line.toLowerCase();
        if (!labels.any((label) => l.contains(label))) continue;
        final matches = RegExp(r'(\d+(?:[.,]\d{1,3})?)').allMatches(line).toList();
        for (final match in matches.reversed) {
          final value = double.tryParse((match.group(1) ?? '').replaceAll(',', '.'));
          if (value != null && value >= min && value <= max) return value;
        }
      }
      return null;
    }

    var litres = findNumberNear(<String>['litre', 'liters', 'litres', ' ltr', ' qty', 'volume'], min: 1, max: 200);
    litres ??= () {
      final match = RegExp(r'\b(\d{1,3}(?:[.,]\d{1,3})?)\s*(?:l|ltr|litres|liters)\b', caseSensitive: false).firstMatch(text);
      return double.tryParse((match?.group(1) ?? '').replaceAll(',', '.'));
    }();

    var total = findNumberNear(<String>['total', 'amount', 'sale'], min: 1, max: 10000);
    var price = findNumberNear(<String>['price/l', 'price per l', 'unit price', '/l', 'c/l', 'cpl'], min: 0.2, max: 9999);

    if (price != null && price > 20) price /= 100.0;
    if (price == null && total != null && litres != null && litres > 0) {
      final calculated = total / litres;
      if (calculated >= 0.2 && calculated <= 10) price = calculated;
    }
    if (total == null && price != null && litres != null) total = price * litres;

    String? fuelType;
    if (RegExp(r'\b(?:petrol\s*92|octane\s*92)\b', caseSensitive: false).hasMatch(lower)) {
      fuelType = 'Petrol 92';
    } else if (RegExp(r'\b(?:petrol\s*95|octane\s*95)\b', caseSensitive: false).hasMatch(lower)) {
      fuelType = 'Petrol 95';
    } else if (lower.contains('super diesel')) {
      fuelType = 'Super Diesel';
    } else if (lower.contains('auto diesel')) {
      fuelType = 'Auto Diesel';
    } else if (lower.contains('diesel')) {
      fuelType = 'Diesel';
    } else if (lower.contains('e10')) {
      fuelType = 'E10';
    } else if (RegExp(r'\b(?:premium|pulp|ron|ulp)\s*98\b', caseSensitive: false).hasMatch(lower)) {
      fuelType = 'Premium 98';
    } else if (RegExp(r'\b(?:premium|pulp|ron|ulp)\s*95\b', caseSensitive: false).hasMatch(lower)) {
      fuelType = 'Premium 95';
    } else if (RegExp(r'\b(?:unleaded|ulp|ron)\s*91\b', caseSensitive: false).hasMatch(lower) || lower.contains('unleaded petrol')) {
      fuelType = 'Unleaded 91';
    }

    String? station;
    const ignored = <String>['tax invoice', 'receipt', 'abn', 'gst', 'date', 'time', 'total', 'amount'];
    for (final line in lines.take(8)) {
      final l = line.toLowerCase();
      if (line.length < 3 || ignored.any((label) => l.contains(label)) || RegExp(r'^\d').hasMatch(line)) continue;
      station = line.length > 60 ? line.substring(0, 60) : line;
      break;
    }

    return ReceiptScanResult(
      date: date,
      station: station,
      fuelType: fuelType,
      pricePerLitre: price,
      litres: litres,
      total: total,
      rawText: text,
    );
  }
}

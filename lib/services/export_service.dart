import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/fuel_entry.dart';
import 'fuel_math.dart';

class ExportService {
  static Future<File> createExcel({
    required List<FuelEntry> entries,
    required String currencyCode,
  }) async {
    final book = xl.Excel.createExcel();
    final sheet = book['Fuel Records'];
    sheet.appendRow(<xl.CellValue>[
      xl.TextCellValue('Date'),
      xl.TextCellValue('Fuel Type'),
      xl.TextCellValue('Station'),
      xl.TextCellValue('Price / Litre ($currencyCode)'),
      xl.TextCellValue('Litres'),
      xl.TextCellValue('Total ($currencyCode)'),
      xl.TextCellValue('Odometer'),
      xl.TextCellValue('Efficiency (L/100km)'),
      xl.TextCellValue('Notes'),
    ]);

    for (final entry in entries) {
      final efficiency = FuelMath.efficiencyLPer100Km(entry, entries);
      sheet.appendRow(<xl.CellValue>[
        xl.TextCellValue(DateFormat('yyyy-MM-dd').format(entry.date)),
        xl.TextCellValue(entry.fuelType),
        xl.TextCellValue(entry.station),
        xl.DoubleCellValue(entry.pricePerLitre),
        xl.DoubleCellValue(entry.litres),
        xl.DoubleCellValue(entry.total),
        entry.odometer == null ? xl.TextCellValue('') : xl.DoubleCellValue(entry.odometer!),
        efficiency == null ? xl.TextCellValue('') : xl.DoubleCellValue(efficiency),
        xl.TextCellValue(entry.notes),
      ]);
    }

    final summary = book['Summary'];
    summary.appendRow(<xl.CellValue>[
      xl.TextCellValue('Metric'),
      xl.TextCellValue('Value'),
    ]);
    summary.appendRow(<xl.CellValue>[
      xl.TextCellValue('Total Spend ($currencyCode)'),
      xl.DoubleCellValue(FuelMath.totalSpend(entries)),
    ]);
    summary.appendRow(<xl.CellValue>[
      xl.TextCellValue('Total Litres'),
      xl.DoubleCellValue(FuelMath.totalLitres(entries)),
    ]);
    summary.appendRow(<xl.CellValue>[
      xl.TextCellValue('Average Price / Litre ($currencyCode)'),
      xl.DoubleCellValue(FuelMath.averagePricePerLitre(entries)),
    ]);
    summary.appendRow(<xl.CellValue>[
      xl.TextCellValue('Measured Distance (km)'),
      xl.DoubleCellValue(FuelMath.totalMeasuredDistance(entries)),
    ]);
    final avgEfficiency = FuelMath.averageEfficiencyLPer100Km(entries);
    summary.appendRow(<xl.CellValue>[
      xl.TextCellValue('Average Efficiency (L/100km)'),
      avgEfficiency == null ? xl.TextCellValue('') : xl.DoubleCellValue(avgEfficiency),
    ]);

    final bytes = book.save();
    if (bytes == null) throw Exception('Could not create Excel file.');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/NEVIRO_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> shareExcel({
    required List<FuelEntry> entries,
    required String currencyCode,
  }) async {
    final file = await createExcel(entries: entries, currencyCode: currencyCode);
    await SharePlus.instance.share(
      ShareParams(
        text: 'NEVIRO fuel records',
        files: <XFile>[XFile(file.path)],
      ),
    );
  }
}

import 'package:http/http.dart' as http;

class NationalFuelPrice {
  final String fuelType;
  final double pricePerLitre;

  const NationalFuelPrice({required this.fuelType, required this.pricePerLitre});
}

class SriLankaPriceService {
  static const String sourceUrl = 'https://ceypetco.gov.lk/marketing-sales/';

  static Future<List<NationalFuelPrice>> fetchCurrentPrices() async {
    final response = await http.get(Uri.parse(sourceUrl)).timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) {
      throw Exception('Official Sri Lanka fuel prices are unavailable.');
    }

    final clean = response.body
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ');

    const labels = <String, String>{
      'Petrol 92': 'Lanka Petrol 92 Octane',
      'Petrol 95': 'Lanka Petrol 95 Octane Euro 4',
      'Auto Diesel': 'Lanka Auto Diesel',
      'Super Diesel': 'Lanka Super Diesel 4 Star Euro 4',
      'Kerosene': 'Lanka Kerosene',
    };

    final prices = <NationalFuelPrice>[];
    for (final entry in labels.entries) {
      final index = clean.toLowerCase().indexOf(entry.value.toLowerCase());
      if (index < 0) continue;
      final end = (index + 220) > clean.length ? clean.length : (index + 220);
      final window = clean.substring(index, end);
      double? found;
      for (final match in RegExp(r'(?:Rs\.?|LKR)?\s*([0-9]{2,4}(?:\.[0-9]{1,2})?)', caseSensitive: false).allMatches(window)) {
        final candidate = double.tryParse(match.group(1) ?? '');
        if (candidate != null && candidate >= 100 && candidate <= 2000) {
          found = candidate;
          break;
        }
      }
      if (found != null) {
        prices.add(NationalFuelPrice(fuelType: entry.key, pricePerLitre: found));
      }
    }

    if (prices.isEmpty) {
      throw Exception('The official page changed and prices could not be read.');
    }
    return prices;
  }
}

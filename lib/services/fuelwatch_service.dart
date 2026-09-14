import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/station_price.dart';

class FuelWatchService {
  static const Map<String, int> products = <String, int>{
    'Unleaded 91': 1,
    'Premium 95': 2,
    'Premium 98': 6,
    'Diesel': 4,
    'LPG': 5,
    'E85': 10,
  };

  static Future<List<StationPrice>> fetchWaPrices({
    required String suburb,
    required String fuelType,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final product = products[fuelType] ?? 1;
    final uri = Uri.https(
      'www.fuelwatch.wa.gov.au',
      '/fuelwatch/fuelWatchRSS',
      <String, String>{
        'Product': '$product',
        'Suburb': suburb,
        'Surrounding': 'yes',
        'Day': 'today',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) {
      throw Exception('FuelWatch returned ${response.statusCode}.');
    }

    final document = XmlDocument.parse(response.body);
    final rows = <StationPrice>[];

    for (final item in document.findAllElements('item')) {
      String value(String tag) => item.getElement(tag)?.innerText.trim() ?? '';
      final price = double.tryParse(value('price'));
      if (price == null) continue;

      final latitude = double.tryParse(value('latitude'));
      final longitude = double.tryParse(value('longitude'));
      double? distanceKm;
      if (userLatitude != null && userLongitude != null && latitude != null && longitude != null) {
        distanceKm = Geolocator.distanceBetween(
              userLatitude,
              userLongitude,
              latitude,
              longitude,
            ) /
            1000.0;
      }

      final station = value('trading-name').isNotEmpty ? value('trading-name') : value('title');
      rows.add(
        StationPrice(
          station: station,
          brand: value('brand'),
          address: value('address'),
          suburb: value('location'),
          fuelType: fuelType,
          priceCentsPerLitre: price,
          sourceDate: DateTime.tryParse(value('date')),
          latitude: latitude,
          longitude: longitude,
          distanceKm: distanceKm,
        ),
      );
    }

    rows.sort((StationPrice a, StationPrice b) => a.priceCentsPerLitre.compareTo(b.priceCentsPerLitre));
    return rows.take(10).toList();
  }
}

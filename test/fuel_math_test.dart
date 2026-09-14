import 'package:flutter_test/flutter_test.dart';
import 'package:neviro/models/fuel_entry.dart';
import 'package:neviro/services/fuel_math.dart';

void main() {
  test('fuel totals and efficiency are calculated as doubles', () {
    final entries = <FuelEntry>[
      FuelEntry(
        id: '1',
        date: DateTime(2026, 1, 1),
        fuelType: 'Unleaded 91',
        pricePerLitre: 1.80,
        litres: 40.0,
        odometer: 10000,
      ),
      FuelEntry(
        id: '2',
        date: DateTime(2026, 1, 10),
        fuelType: 'Unleaded 91',
        pricePerLitre: 1.90,
        litres: 45.0,
        odometer: 10600,
      ),
    ];

    expect(FuelMath.totalLitres(entries), 85.0);
    expect(FuelMath.totalSpend(entries), closeTo(157.5, 0.001));
    expect(FuelMath.efficiencyLPer100Km(entries[1], entries), closeTo(7.5, 0.001));
  });
}

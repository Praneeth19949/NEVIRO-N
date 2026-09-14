import '../models/fuel_entry.dart';

class FuelMath {
  static double totalSpend(Iterable<FuelEntry> entries) {
    return entries.fold<double>(0.0, (double value, FuelEntry e) => value + e.total);
  }

  static double totalLitres(Iterable<FuelEntry> entries) {
    return entries.fold<double>(0.0, (double value, FuelEntry e) => value + e.litres);
  }

  static double averagePricePerLitre(Iterable<FuelEntry> entries) {
    final litres = totalLitres(entries);
    if (litres <= 0) return 0.0;
    return totalSpend(entries) / litres;
  }

  static List<FuelEntry> sortedAscending(Iterable<FuelEntry> entries) {
    final list = entries.toList()..sort((FuelEntry a, FuelEntry b) => a.date.compareTo(b.date));
    return list;
  }

  static double _odometerKm(FuelEntry entry) {
    final value = entry.odometer ?? 0.0;
    return entry.odometerUnit == 'mi' ? value * 1.609344 : value;
  }

  static double? distanceForEntry(FuelEntry entry, Iterable<FuelEntry> allEntries) {
    if (entry.odometer == null) return null;
    final list = sortedAscending(allEntries);
    final index = list.indexWhere((FuelEntry e) => e.id == entry.id);
    if (index <= 0) return null;
    for (var i = index - 1; i >= 0; i--) {
      final previousOdo = list[i].odometer;
      if (previousOdo != null) {
        final currentKm = _odometerKm(entry);
        final previousKm = _odometerKm(list[i]);
        if (currentKm > previousKm) return currentKm - previousKm;
      }
    }
    return null;
  }

  static double? efficiencyLPer100Km(FuelEntry entry, Iterable<FuelEntry> allEntries) {
    final distance = distanceForEntry(entry, allEntries);
    if (distance == null || distance <= 0 || entry.litres <= 0) return null;
    return (entry.litres / distance) * 100.0;
  }

  static double? averageEfficiencyLPer100Km(Iterable<FuelEntry> entries) {
    final list = sortedAscending(entries);
    double totalDistance = 0.0;
    double litresForMeasuredLegs = 0.0;
    for (var i = 1; i < list.length; i++) {
      final current = list[i];
      final previous = list[i - 1];
      if (current.odometer == null || previous.odometer == null) continue;
      final distance = _odometerKm(current) - _odometerKm(previous);
      if (distance <= 0) continue;
      totalDistance += distance;
      litresForMeasuredLegs += current.litres;
    }
    if (totalDistance <= 0 || litresForMeasuredLegs <= 0) return null;
    return (litresForMeasuredLegs / totalDistance) * 100.0;
  }

  static double totalMeasuredDistance(Iterable<FuelEntry> entries) {
    final list = sortedAscending(entries);
    double total = 0.0;
    for (var i = 1; i < list.length; i++) {
      final a = list[i - 1].odometer;
      final b = list[i].odometer;
      if (a != null && b != null) {
        final aKm = _odometerKm(list[i - 1]);
        final bKm = _odometerKm(list[i]);
        if (bKm > aKm) total += bKm - aKm;
      }
    }
    return total;
  }
}

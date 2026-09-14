import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fuel_entry.dart';
import '../models/station_price.dart';

class LocalStore extends ChangeNotifier {
  static const String _entriesKey = 'neviro.entries.v1';
  static const String _regionKey = 'neviro.region.v1';
  static const String _currencyKey = 'neviro.currency.v1';
  static const String _distanceUnitKey = 'neviro.distanceUnit.v1';
  static const String _efficiencyUnitKey = 'neviro.efficiencyUnit.v1';
  static const String _cheapestKey = 'neviro.cheapest.v1';
  static const String _cheapestAreaKey = 'neviro.cheapestArea.v1';
  static const String _cheapestUpdatedKey = 'neviro.cheapestUpdated.v1';

  final SharedPreferences preferences;
  final List<FuelEntry> entries;

  String regionOverride;
  String? currencyOverride;
  String distanceUnit;
  String efficiencyUnit;
  StationPrice? cachedCheapest;
  String? cachedCheapestArea;
  DateTime? cachedCheapestUpdated;

  LocalStore({
    required this.preferences,
    required this.entries,
    required this.regionOverride,
    required this.currencyOverride,
    required this.distanceUnit,
    required this.efficiencyUnit,
    required this.cachedCheapest,
    required this.cachedCheapestArea,
    required this.cachedCheapestUpdated,
  });

  static Future<LocalStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = <FuelEntry>[];
    final raw = prefs.getString(_entriesKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              entries.add(FuelEntry.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      } catch (_) {
        // Corrupt local data is ignored so the app can still open safely.
      }
    }
    entries.sort((FuelEntry a, FuelEntry b) => b.date.compareTo(a.date));

    StationPrice? cachedCheapest;
    final cachedRaw = prefs.getString(_cheapestKey);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedRaw);
        if (decoded is Map) {
          cachedCheapest = StationPrice.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    return LocalStore(
      preferences: prefs,
      entries: entries,
      regionOverride: prefs.getString(_regionKey) ?? 'AUTO',
      currencyOverride: prefs.getString(_currencyKey),
      distanceUnit: prefs.getString(_distanceUnitKey) ?? 'km',
      efficiencyUnit: prefs.getString(_efficiencyUnitKey) ?? 'L/100km',
      cachedCheapest: cachedCheapest,
      cachedCheapestArea: prefs.getString(_cheapestAreaKey),
      cachedCheapestUpdated: DateTime.tryParse(prefs.getString(_cheapestUpdatedKey) ?? ''),
    );
  }

  Future<void> _saveEntries() async {
    await preferences.setString(
      _entriesKey,
      jsonEncode(entries.map((FuelEntry e) => e.toJson()).toList()),
    );
  }

  Future<void> addEntry(FuelEntry entry) async {
    entries.add(entry);
    entries.sort((FuelEntry a, FuelEntry b) => b.date.compareTo(a.date));
    await _saveEntries();
    notifyListeners();
  }

  Future<void> updateEntry(FuelEntry entry) async {
    final index = entries.indexWhere((FuelEntry e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entry;
    entries.sort((FuelEntry a, FuelEntry b) => b.date.compareTo(a.date));
    await _saveEntries();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    entries.removeWhere((FuelEntry e) => e.id == id);
    await _saveEntries();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    entries.clear();
    await _saveEntries();
    notifyListeners();
  }

  Future<void> setRegionOverride(String value) async {
    regionOverride = value;
    await preferences.setString(_regionKey, value);
    notifyListeners();
  }

  Future<void> setCurrencyOverride(String? value) async {
    currencyOverride = value;
    if (value == null) {
      await preferences.remove(_currencyKey);
    } else {
      await preferences.setString(_currencyKey, value);
    }
    notifyListeners();
  }

  Future<void> setDistanceUnit(String value) async {
    distanceUnit = value;
    await preferences.setString(_distanceUnitKey, value);
    notifyListeners();
  }

  Future<void> setEfficiencyUnit(String value) async {
    efficiencyUnit = value;
    await preferences.setString(_efficiencyUnitKey, value);
    notifyListeners();
  }

  Future<void> cacheCheapest({
    required StationPrice station,
    required String area,
    required DateTime updated,
  }) async {
    cachedCheapest = station;
    cachedCheapestArea = area;
    cachedCheapestUpdated = updated;
    await preferences.setString(_cheapestKey, jsonEncode(station.toJson()));
    await preferences.setString(_cheapestAreaKey, area);
    await preferences.setString(_cheapestUpdatedKey, updated.toIso8601String());
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/region_profile.dart';
import 'screens/app_shell.dart';
import 'services/local_store.dart';
import 'services/region_service.dart';

const Color kNeviroDark = Color(0xFF041F1A);
const Color kNeviroCard = Color(0xFF0B332B);
const Color kNeviroCard2 = Color(0xFF10483C);
const Color kNeviroGreen = Color(0xFF38E66B);
const Color kNeviroMuted = Color(0xFF9EB8B0);

class NeviroApp extends StatelessWidget {
  final LocalStore store;

  const NeviroApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final profile = RegionService.profileFor(overrideCode: store.regionOverride);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NEVIRO',
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kNeviroDark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kNeviroGreen,
              brightness: Brightness.dark,
              surface: kNeviroCard,
            ),
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: kNeviroDark,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: kNeviroCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF245749)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF245749)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kNeviroGreen, width: 1.5),
              ),
            ),
            cardTheme: CardThemeData(
              color: kNeviroCard,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF123F35),
              contentTextStyle: TextStyle(color: Colors.white),
            ),
          ),
          home: AppShell(store: store, profile: profile),
        );
      },
    );
  }
}

String effectiveCurrencyCode(LocalStore store, RegionProfile profile) {
  return store.currencyOverride ?? profile.currencyCode;
}

String currencySymbolFor(String code) {
  const symbols = <String, String>{
    'AUD': r'A$',
    'LKR': 'Rs.',
    'USD': r'$',
    'GBP': '£',
    'NZD': r'NZ$',
    'CAD': r'C$',
    'EUR': '€',
  };
  return symbols[code] ?? code;
}

String money(LocalStore store, RegionProfile profile, double value) {
  final code = effectiveCurrencyCode(store, profile);
  final symbol = currencySymbolFor(code);
  return NumberFormat.currency(symbol: '$symbol ', decimalDigits: 2).format(value);
}

String distanceText(LocalStore store, double km, {int decimals = 0}) {
  if (store.distanceUnit == 'mi') {
    return '${(km * 0.621371).toStringAsFixed(decimals)} mi';
  }
  return '${km.toStringAsFixed(decimals)} km';
}

String efficiencyText(LocalStore store, double lPer100Km) {
  if (store.efficiencyUnit == 'km/L') {
    if (lPer100Km <= 0) return '—';
    return '${(100.0 / lPer100Km).toStringAsFixed(1)} km/L';
  }
  return '${lPer100Km.toStringAsFixed(1)} L/100km';
}

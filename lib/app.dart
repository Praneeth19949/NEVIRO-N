import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/region_profile.dart';
import 'screens/app_shell.dart';
import 'services/local_store.dart';
import 'services/region_service.dart';

const Color kNeviroBackground = Color(0xFFF3F7F2);
const Color kNeviroDark = Color(0xFF163B2D);
const Color kNeviroCard = Color(0xFFFFFFFF);
const Color kNeviroCard2 = Color(0xFFEAF7EE);
const Color kNeviroGreen = Color(0xFF18B45B);
const Color kNeviroGreenDark = Color(0xFF0D8E46);
const Color kNeviroMuted = Color(0xFF6C7F75);
const Color kNeviroBorder = Color(0xFFDCE8E0);

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
          themeMode: ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: kNeviroBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kNeviroGreen,
              brightness: Brightness.light,
              surface: kNeviroCard,
            ),
            fontFamily: 'Roboto',
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: kNeviroDark),
              bodyLarge: TextStyle(color: kNeviroDark),
              titleMedium: TextStyle(color: kNeviroDark),
              titleLarge: TextStyle(color: kNeviroDark),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: kNeviroBackground,
              foregroundColor: kNeviroDark,
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: kNeviroCard,
              hintStyle: const TextStyle(color: kNeviroMuted),
              prefixIconColor: kNeviroGreenDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kNeviroBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kNeviroBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kNeviroGreen, width: 1.5),
              ),
            ),
            cardTheme: CardThemeData(
              color: kNeviroCard,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: kNeviroBorder),
              ),
            ),
            dividerTheme: const DividerThemeData(color: kNeviroBorder),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: kNeviroDark,
              contentTextStyle: TextStyle(color: Colors.white),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: kNeviroCard,
              surfaceTintColor: kNeviroCard,
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
    'AUD': r'$',
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

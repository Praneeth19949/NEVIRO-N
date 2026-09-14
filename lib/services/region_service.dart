import 'package:flutter/widgets.dart';

import '../models/region_profile.dart';

class RegionService {
  static String detectedCountryCode() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return (locale.countryCode ?? '').toUpperCase();
  }

  static RegionProfile profileFor({String? overrideCode}) {
    final code = (overrideCode == null || overrideCode == 'AUTO')
        ? detectedCountryCode()
        : overrideCode.toUpperCase();
    return regionProfiles[code] ?? fallbackRegion;
  }
}

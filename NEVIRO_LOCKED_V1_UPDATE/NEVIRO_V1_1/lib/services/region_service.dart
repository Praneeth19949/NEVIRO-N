import 'package:flutter/widgets.dart';

import '../models/region_profile.dart';

class RegionService {
  static String detectedCountryCode() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;

    // Australian phones are sometimes configured with an English (UK) locale,
    // which previously made NEVIRO default to GBP. Australian timezone names
    // give us a safe extra signal without requesting location permission.
    final zone = DateTime.now().timeZoneName.toUpperCase();
    const auZones = <String>{'AWST', 'AEST', 'AEDT', 'ACST', 'ACDT'};
    if (auZones.contains(zone)) return 'AU';

    for (final locale in dispatcher.locales) {
      final code = (locale.countryCode ?? '').toUpperCase();
      if (regionProfiles.containsKey(code)) return code;
    }

    final code = (dispatcher.locale.countryCode ?? '').toUpperCase();
    return code;
  }

  static RegionProfile profileFor({String? overrideCode}) {
    final code = (overrideCode == null || overrideCode == 'AUTO')
        ? detectedCountryCode()
        : overrideCode.toUpperCase();
    return regionProfiles[code] ?? fallbackRegion;
  }
}

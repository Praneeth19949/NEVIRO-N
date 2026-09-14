class RegionProfile {
  final String code;
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final List<String> fuelTypes;

  const RegionProfile({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.fuelTypes,
  });
}

const Map<String, RegionProfile> regionProfiles = <String, RegionProfile>{
  'AU': RegionProfile(
    code: 'AU',
    name: 'Australia',
    currencyCode: 'AUD',
    currencySymbol: r'A$',
    fuelTypes: <String>['Unleaded 91', 'E10', 'Premium 95', 'Premium 98', 'Diesel'],
  ),
  'LK': RegionProfile(
    code: 'LK',
    name: 'Sri Lanka',
    currencyCode: 'LKR',
    currencySymbol: 'Rs.',
    fuelTypes: <String>['Petrol 92', 'Petrol 95', 'Auto Diesel', 'Super Diesel', 'Kerosene'],
  ),
  'US': RegionProfile(
    code: 'US',
    name: 'United States',
    currencyCode: 'USD',
    currencySymbol: r'$',
    fuelTypes: <String>['Regular 87', 'Midgrade 89', 'Premium 91/93', 'Diesel'],
  ),
  'GB': RegionProfile(
    code: 'GB',
    name: 'United Kingdom',
    currencyCode: 'GBP',
    currencySymbol: '£',
    fuelTypes: <String>['E10 Petrol', 'E5 Premium Petrol', 'Diesel'],
  ),
  'NZ': RegionProfile(
    code: 'NZ',
    name: 'New Zealand',
    currencyCode: 'NZD',
    currencySymbol: r'NZ$',
    fuelTypes: <String>['91', '95', '98', 'Diesel'],
  ),
  'CA': RegionProfile(
    code: 'CA',
    name: 'Canada',
    currencyCode: 'CAD',
    currencySymbol: r'C$',
    fuelTypes: <String>['Regular', 'Midgrade', 'Premium', 'Diesel'],
  ),
};

const RegionProfile fallbackRegion = RegionProfile(
  code: 'US',
  name: 'International',
  currencyCode: 'USD',
  currencySymbol: r'$',
  fuelTypes: <String>['Petrol', 'Premium Petrol', 'Diesel'],
);

class RegionProfile {
  final String code;
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final List<String> fuelTypes;
  final String fuelDataMode;

  const RegionProfile({required this.code, required this.name, required this.currencyCode, required this.currencySymbol, required this.fuelTypes, required this.fuelDataMode});
}

const Map<String, RegionProfile> regionProfiles = <String, RegionProfile>{
  'AU': RegionProfile(code:'AU', name:'Australia', currencyCode:'AUD', currencySymbol:r'$', fuelTypes:<String>['Unleaded 91','E10','Premium 95','Premium 98','Diesel'], fuelDataMode:'Free verified station data where available'),
  'LK': RegionProfile(code:'LK', name:'Sri Lanka', currencyCode:'LKR', currencySymbol:'Rs.', fuelTypes:<String>['Petrol 92','Petrol 95','Auto Diesel','Super Diesel','Kerosene'], fuelDataMode:'Official/reference price'),
  'IN': RegionProfile(code:'IN', name:'India', currencyCode:'INR', currencySymbol:'₹', fuelTypes:<String>['Petrol','Diesel','CNG'], fuelDataMode:'Free reliable city/reference data only'),
  'NZ': RegionProfile(code:'NZ', name:'New Zealand', currencyCode:'NZD', currencySymbol:r'NZ$', fuelTypes:<String>['91','95','98','Diesel'], fuelDataMode:'Official/reference price'),
  'NP': RegionProfile(code:'NP', name:'Nepal', currencyCode:'NPR', currencySymbol:'रू', fuelTypes:<String>['Petrol','Diesel','Kerosene'], fuelDataMode:'Official/regional reference price'),
  'SG': RegionProfile(code:'SG', name:'Singapore', currencyCode:'SGD', currencySymbol:r'S$', fuelTypes:<String>['Petrol 92','Petrol 95','Petrol 98','Diesel'], fuelDataMode:'Free legally usable data only'),
};

const RegionProfile fallbackRegion = regionProfiles['AU']!;

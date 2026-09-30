class StationPrice {
  final String station;
  final String brand;
  final String address;
  final String suburb;
  final String fuelType;
  final double priceCentsPerLitre;
  final DateTime? sourceDate;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  const StationPrice({
    required this.station,
    required this.brand,
    required this.address,
    required this.suburb,
    required this.fuelType,
    required this.priceCentsPerLitre,
    this.sourceDate,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  double get pricePerLitre => priceCentsPerLitre / 100.0;

  StationPrice copyWithDistance(double? km) {
    return StationPrice(
      station: station,
      brand: brand,
      address: address,
      suburb: suburb,
      fuelType: fuelType,
      priceCentsPerLitre: priceCentsPerLitre,
      sourceDate: sourceDate,
      latitude: latitude,
      longitude: longitude,
      distanceKm: km,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'station': station,
        'brand': brand,
        'address': address,
        'suburb': suburb,
        'fuelType': fuelType,
        'priceCentsPerLitre': priceCentsPerLitre,
        'sourceDate': sourceDate?.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'distanceKm': distanceKm,
      };

  factory StationPrice.fromJson(Map<String, dynamic> json) {
    return StationPrice(
      station: (json['station'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      suburb: (json['suburb'] ?? '').toString(),
      fuelType: (json['fuelType'] ?? '').toString(),
      priceCentsPerLitre: (json['priceCentsPerLitre'] as num?)?.toDouble() ?? 0.0,
      sourceDate: DateTime.tryParse((json['sourceDate'] ?? '').toString()),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

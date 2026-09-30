class FuelEntry {
  final String id;
  final DateTime date;
  final String fuelType;
  final double pricePerLitre;
  final double litres;
  final String station;
  final String notes;
  final double? odometer;
  final String odometerUnit;

  const FuelEntry({
    required this.id,
    required this.date,
    required this.fuelType,
    required this.pricePerLitre,
    required this.litres,
    this.station = '',
    this.notes = '',
    this.odometer,
    this.odometerUnit = 'km',
  });

  double get total => pricePerLitre * litres;

  FuelEntry copyWith({
    String? id,
    DateTime? date,
    String? fuelType,
    double? pricePerLitre,
    double? litres,
    String? station,
    String? notes,
    double? odometer,
    String? odometerUnit,
    bool clearOdometer = false,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      fuelType: fuelType ?? this.fuelType,
      pricePerLitre: pricePerLitre ?? this.pricePerLitre,
      litres: litres ?? this.litres,
      station: station ?? this.station,
      notes: notes ?? this.notes,
      odometer: clearOdometer ? null : (odometer ?? this.odometer),
      odometerUnit: odometerUnit ?? this.odometerUnit,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date.toIso8601String(),
        'fuelType': fuelType,
        'pricePerLitre': pricePerLitre,
        'litres': litres,
        'station': station,
        'notes': notes,
        'odometer': odometer,
        'odometerUnit': odometerUnit,
      };

  factory FuelEntry.fromJson(Map<String, dynamic> json) {
    return FuelEntry(
      id: (json['id'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      fuelType: (json['fuelType'] ?? 'Fuel').toString(),
      pricePerLitre: (json['pricePerLitre'] as num?)?.toDouble() ?? 0.0,
      litres: (json['litres'] as num?)?.toDouble() ?? 0.0,
      station: (json['station'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      odometer: (json['odometer'] as num?)?.toDouble(),
      odometerUnit: (json['odometerUnit'] ?? 'km').toString(),
    );
  }
}

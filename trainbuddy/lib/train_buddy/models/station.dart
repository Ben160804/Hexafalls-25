class Station {
  final String code;
  final String name;
  final String city;

  Station({
    required this.code,
    required this.name,
    required this.city,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      code: json['stnCode'] as String,
      name: json['stnName'] as String,
      city: json['stnCity'] as String,
    );
  }

  @override
  String toString() => '$name ($code)';
} 
class FreightName {
  final String id;
  final String name;

  FreightName({required this.id, required this.name});

  factory FreightName.fromJson(Map<String, dynamic> json) {
    return FreightName(id: json['freightId'], name: json['freightName']);
  }
}

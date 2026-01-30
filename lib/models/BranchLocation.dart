class BranchLocation {
  final String branchId;
  final String branchName;
  final String location;
  final String code;
  final String? address;

  BranchLocation({
    required this.branchId,
    required this.branchName,
    required this.location,
    required this.code,
    this.address,
  });

  factory BranchLocation.fromJson(Map<String, dynamic> json) {
    return BranchLocation(
      branchId: json['branchId'] ?? '',
      branchName: json['branchName'] ?? '',
      location: json['location'] ?? '',
      code: json['code'] ?? '',
      address: json['address'],
    );
  }
}

class BranchLocation {
  final String branchId;
  final String location;
  final String branchName;

  BranchLocation({
    required this.branchId,
    required this.location,
    required this.branchName,
  });

  factory BranchLocation.fromJson(Map<String, dynamic> json) {
    return BranchLocation(
      branchId: json['branchId'] ?? '',
      location: json['locationId'] ?? '',
      branchName: json['branchName'] ?? '',
    );
  }
}

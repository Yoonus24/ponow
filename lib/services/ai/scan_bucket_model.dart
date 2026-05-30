// class ScanBucket {
//   final String id;

//   final String bucketNo;

//   final String status;

//   final String imagePath;

//   final String invoiceNumber;

//   final String vendorName;

//   final String createdAt;

//   ScanBucket({
//     required this.id,

//     required this.bucketNo,

//     required this.status,

//     required this.imagePath,

//     required this.invoiceNumber,

//     required this.vendorName,

//     required this.createdAt,
//   });

//   factory ScanBucket.fromJson(Map<String, dynamic> json) {
//     return ScanBucket(
//       id: json["_id"],

//       bucketNo: json["bucketNo"] ?? "",

//       status: json["status"] ?? "",

//       imagePath: json["imagePath"] ?? "",

//       invoiceNumber: json["invoiceNumber"] ?? "",

//       vendorName: json["vendorName"] ?? "",

//       createdAt: json["createdAt"] ?? "",
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       "_id": id,

//       "bucketNo": bucketNo,

//       "status": status,

//       "imagePath": imagePath,

//       "invoiceNumber": invoiceNumber,

//       "vendorName": vendorName,

//       "createdAt": createdAt,
//     };
//   }
// }

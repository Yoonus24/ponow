// import 'package:dio/dio.dart';


// import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
// import 'package:purchaseorders2/services/ai/scan_bucket_model.dart';

// import 'package:purchaseorders2/services/dio_client.dart';

// class ScanBucketService {
//   final Dio dio = DioClient.dio;

//   // =====================================================
//   // SAVE BUCKET
//   // =====================================================

//   Future<void> saveBucket({
//     required Map<String, dynamic> aiResponse,

//     required String tempImagePath,

//     required String invoiceNumber,

//     required String vendorName,

//     String? poId,

//     String? poNumber,
//   }) async {
//     try {
//       await dio.post(
//         "/scan-buckets",

//         data: {
//           "aiResponse": aiResponse,

//           "tempImagePath": tempImagePath,

//           "invoiceNumber": invoiceNumber,

//           "vendorName": vendorName,

//           "poId": poId,

//           "poNumber": poNumber,

//           "createdBy": "admin",
//         },
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // =====================================================
//   // GET ALL BUCKETS
//   // =====================================================

//   Future<List<ScanBucket>> getBuckets() async {
//     try {
//       final response = await dio.get(
//         "/scan-buckets",
//       );

//       final List data = response.data;

//       return data
//           .map(
//             (e) => ScanBucket.fromJson(e),
//           )
//           .toList();
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // =====================================================
//   // GET BUCKET BY ID
//   // =====================================================

//   Future<AIInvoiceResponse> getBucketById(
//     String bucketId,
//   ) async {
//     try {
//       final response = await dio.get(
//         "/scan-buckets/$bucketId",
//       );

//       final data = response.data;

//       return AIInvoiceResponse.fromJson(
//         data["aiResponse"],
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // =====================================================
//   // DELETE BUCKET
//   // =====================================================

//   Future<void> deleteBucket(
//     String bucketId,
//   ) async {
//     try {
//       await dio.delete(
//         "/scan-buckets/$bucketId",
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // =====================================================
//   // UPDATE BUCKET STATUS
//   // =====================================================

//   Future<void> updateBucketStatus({
//     required String bucketId,

//     required String status,
//   }) async {
//     try {
//       await dio.patch(
//         "/scan-buckets/$bucketId/status",

//         data: {
//           "status": status,
//         },
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }
// }
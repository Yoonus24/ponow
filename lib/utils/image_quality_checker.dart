// import 'dart:io';
// import 'package:image_blur_detection/image_blur_detection.dart';
// import 'package:flutter/material.dart';

// class ImageQualityChecker {
//   static const double _threshold = 100.0;

//   static Future<({
//     bool isBlurry,
//     double score,
//     String message,
//   })> check(File image) async {
//     try {
//       final result = await ImageBlurDetection.analyzeImage(
//         imagePath: image.path,
//         blurThreshold: _threshold,
//       );

//       final score = result.varianceScore.toDouble();

//       debugPrint("📷 Quality Score: $score");

//       return (
//         isBlurry: result.isBlurry,
//         score: score,
//         message: result.isBlurry ? "Image is blurry" : "Image quality is good",
//       );
//     } catch (e) {
//       debugPrint("⚠️ Quality check error: $e");
//       return (
//         isBlurry: false,
//         score: 100.0,
//         message: "Quality check unavailable",
//       );
//     }
//   }

//   static Future<List<({
//     bool isBlurry,
//     double score,
//     String message,
//   })>> checkMultiple(List<File> images) async {
//     final results = <({
//       bool isBlurry,
//       double score,
//       String message,
//     })>[];

//     for (final image in images) {
//       results.add(await check(image));
//     }

//     return results;
//   }
// }
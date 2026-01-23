// import 'package:flutter/material.dart';
// import 'package:purchaseorders2/widgets/numeric_Calculator.dart';

// void showNumericCalculator({
//   required BuildContext context,
//   TextEditingController? controller, // Change to nullable
//   String? varianceName,
//   VoidCallback? onValueSelected,
// }) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return NumericCalculator(
//         varianceName: varianceName ?? 'Enter Value',
//     //    initialValue: controller != null ? double.tryParse(controller.text) ?? 0.0 : 0.0,
//        initialValue: 0.0,
//         onValueSelected: (double value) {
//           if (controller != null) {
//             controller.text = value.toStringAsFixed(2); // Format to 2 decimal places
//           }
//           onValueSelected?.call();
//         },
//         controller: controller, // Pass the nullable controller
//       );
//     },
//   );
// }



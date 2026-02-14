import 'package:flutter/material.dart';
import '../widgets/numeric_calculator.dart'; // adjust path if needed

void showNumericCalculator({
  required BuildContext context,
  required TextEditingController controller,
  required String varianceName,
  required VoidCallback onValueSelected,
  String fieldType = '',
  ValueNotifier<String?>? errorNotifier,
}) {
  showDialog(
    context: context,
    builder: (context) => NumericCalculator(
      varianceName: varianceName,
      controller: controller,
      initialValue: double.tryParse(controller.text),
      onValueSelected: (value) {
        controller.text = value.toStringAsFixed(2);
        onValueSelected();
      },
    ),
  );
}

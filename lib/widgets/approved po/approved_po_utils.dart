import 'package:flutter/material.dart';
import '../numeric_Calculator.dart';

class ApprovedPOUtils {
  // MARK: - Expiry Date Formatter
  static String? formatExpiryDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final date = DateTime.parse(dateString);
      return DateTime.utc(date.year, date.month, date.day).toIso8601String();
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  // MARK: - Numeric Calculator Show Method
  static void showNumericCalculator({
    required BuildContext context,
    required TextEditingController? controller,
    required String varianceName,
    double? initialValue,
    required VoidCallback onValueSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => NumericCalculator(
        varianceName: varianceName,
        initialValue: initialValue ?? 0.0,
        controller: controller,
        onValueSelected: (value) {
          if (controller != null) {
            controller.text = value.toStringAsFixed(2);
          }
          onValueSelected();
        },
      ),
    );
  }

  // MARK: - Table Cell Builder
  static Widget buildTableCell(String text, {bool isHeader = false, bool alignLeft = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.black87 : Colors.black54,
        ),
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}
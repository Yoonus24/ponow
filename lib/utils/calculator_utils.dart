import 'package:flutter/material.dart';

void showNumericCalculator({
  required BuildContext context,
  required TextEditingController controller,
  required String varianceName,
  required VoidCallback onValueSelected,
  required String fieldType,
  ValueNotifier<String?>? errorNotifier,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) {
      return RightSideCalculator(
        controller: controller,
        title: varianceName,
        onValueSelected: onValueSelected,
        fieldType: fieldType,
        errorNotifier: errorNotifier,
      );
    },
  );
}

class RightSideCalculator extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final VoidCallback onValueSelected;
  final String fieldType;
  final ValueNotifier<String?>? errorNotifier;

  const RightSideCalculator({
    super.key,
    required this.controller,
    required this.title,
    required this.onValueSelected,
    required this.fieldType,
    this.errorNotifier,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.text.isEmpty) {
        controller.text = '0';
      }
    });

    return AlertDialog(
      alignment: Alignment.centerRight,
      insetPadding: const EdgeInsets.only(right: 37.0),
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      content: Container(
        width: 300,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            // ---------------- HEADER ----------------
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // ---------------- DISPLAY ----------------
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 24),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                readOnly: true,
              ),
            ),

            // ---------------- KEYPAD ----------------
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                padding: const EdgeInsets.all(8.0),
                children:
                    [
                      '7',
                      '8',
                      '9',
                      '4',
                      '5',
                      '6',
                      '1',
                      '2',
                      '3',
                      'C',
                      '0',
                      '←',
                    ].map((key) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            if (key == '←') {
                              if (controller.text.length > 1) {
                                controller.text = controller.text.substring(
                                  0,
                                  controller.text.length - 1,
                                );
                              } else {
                                controller.text = '0';
                              }
                            } else if (key == 'C') {
                              controller.text = '0';
                            } else {
                              if (controller.text == '0') {
                                controller.text = key;
                              } else {
                                controller.text += key;
                              }
                            }
                          },
                          child: Text(
                            key,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // ---------------- BUTTONS ----------------
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (fieldType == 'price') {
                          final priceValue =
                              double.tryParse(controller.text) ?? 0;

                          if (priceValue <= 0) {
                            if (errorNotifier != null) {
                              errorNotifier!.value =
                                  "Price must be greater than 0";
                            }
                            return;
                          }
                        }

                        onValueSelected();
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

// ignore: must_be_immutable
class NumericCalculator extends StatefulWidget {
  String? varianceName;
  final Function(double) onValueSelected;
  final double? initialValue;
  final TextEditingController? controller;

  NumericCalculator({
    super.key,
    this.varianceName,
    required this.onValueSelected,
    this.initialValue,
    this.controller,
  });

  @override
  _NumericCalculatorState createState() => _NumericCalculatorState();
}

class _NumericCalculatorState extends State<NumericCalculator> {
  late ValueNotifier<String> displayNotifier;
  bool _isNegative = false;

  @override
  void initState() {
    super.initState();

    String initialDisplay;
    if (widget.initialValue != null && widget.initialValue! != 0) {
      _isNegative = widget.initialValue! < 0;
      initialDisplay = widget.initialValue!.abs().toStringAsFixed(2);
    } else if (widget.controller?.text.isNotEmpty == true &&
        widget.controller!.text != '0' &&
        widget.controller!.text != '0.00') {
      _isNegative = widget.controller!.text.startsWith('-');
      initialDisplay = widget.controller!.text.replaceAll('-', '');
    } else {
      initialDisplay = '';
    }

    displayNotifier = ValueNotifier<String>(
      _isNegative && initialDisplay != '0'
          ? '-$initialDisplay'
          : initialDisplay,
    );
  }

  @override
  void dispose() {
    displayNotifier.dispose();
    super.dispose();
  }

  void _appendToDisplay(String value) {
    String current = displayNotifier.value;
    bool isNegative = current.startsWith('-');
    String display = isNegative ? current.substring(1) : current;

    if (display.isEmpty || display == '0') {
      display = value == '.' ? '0.' : value;
    } else if (value == '.' && !display.contains('.')) {
      display += value;
    } else if (value != '.') {
      if (display.contains('.')) {
        final decimals = display.split('.').last;
        if (decimals.length < 2) {
          display += value;
        }
      } else {
        display += value;
      }
    }

    displayNotifier.value = isNegative ? '-$display' : display;
  }

  void _toggleSign() {
    String current = displayNotifier.value;

    if (current.startsWith('-')) {
      displayNotifier.value = current.substring(1);
    } else {
      displayNotifier.value = '-$current';
    }
  }

  void _backspace() {
    String current = displayNotifier.value;
    bool isNegative = current.startsWith('-');
    String display = isNegative ? current.substring(1) : current;

    if (display.length > 1) {
      display = display.substring(0, display.length - 1);
    } else {
      display = '0';
    }

    displayNotifier.value = isNegative && display != '0'
        ? '-$display'
        : display;
  }

  void _clear() {
    displayNotifier.value = '';
    widget.controller?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 25,
                color: Colors.black.withOpacity(0.28),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⭐ TITLE
              Text(
                widget.varianceName ?? 'Enter Value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueAccent,
                ),
              ),

              const SizedBox(height: 12),

              // ⭐ DISPLAY BOX
              ValueListenableBuilder<String>(
                valueListenable: displayNotifier,
                builder: (_, value, __) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue, width: 1.3),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // ⭐ KEYPAD
              _row(['1', '2', '3']),
              const SizedBox(height: 10),
              _row(['4', '5', '6']),
              const SizedBox(height: 10),
              _row(['7', '8', '9']),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton('.'),
                  _buildButton('0'),
                  _buildButton('-', onPressed: _toggleSign),
                ],
              ),

              const SizedBox(height: 14),

              // ⭐ ACTION BUTTONS (CLEAR & BACKSPACE)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWideButton('Clear', _clear),
                  const SizedBox(width: 14),
                  _buildWideButton('⌫', _backspace),
                ],
              ),

              const SizedBox(height: 16),

              // ⭐ SUBMIT + CLOSE ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWideButton('Close', () => Navigator.of(context).pop()),
                  const SizedBox(width: 14),
                  _buildWideButton('Submit', () {
                    final value = double.tryParse(displayNotifier.value) ?? 0;
                    widget.onValueSelected(value);
                    Navigator.of(context).pop();
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // BUTTON BUILDERS
  // ---------------------------------------------------------

  Widget _row(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((e) => _buildButton(e)).toList(),
    );
  }

  Widget _buildButton(String text, {VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed ?? () => _appendToDisplay(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // SAME COLOR
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        minimumSize: const Size(70, 52),
        elevation: 4,
        shadowColor: Colors.blue.shade200,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWideButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // SAME COLOR
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(115, 52),
        elevation: 4,
        shadowColor: Colors.blue.shade200,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }
}

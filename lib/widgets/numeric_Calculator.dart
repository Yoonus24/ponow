import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late TextEditingController _textController;
  late FocusNode _focusNode;

  late final ValueNotifier<bool> _isNegativeNotifier;
  late final ValueNotifier<bool> _isInitialValueNotifier;
  late final ValueNotifier<bool> _isFocusedNotifier;

  @override
  void initState() {
    super.initState();

    _isNegativeNotifier = ValueNotifier<bool>(false);
    _isInitialValueNotifier = ValueNotifier<bool>(false);
    _isFocusedNotifier = ValueNotifier<bool>(false);

    _focusNode = FocusNode();
    _textController = widget.controller ?? TextEditingController();

    _focusNode.addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.initialValue != null && widget.initialValue != 0) {
        String formattedValue = widget.initialValue!.toStringAsFixed(2);

        _isNegativeNotifier.value = widget.initialValue! < 0;
        _textController.text = formattedValue;
        _isInitialValueNotifier.value = true;

        _focusNode.requestFocus();
        _textController.selection = TextSelection.collapsed(
          offset: formattedValue.length,
        );
      } else if (widget.controller?.text.isNotEmpty == true &&
          widget.controller!.text != "0" &&
          widget.controller!.text != "0.00") {
        String text = widget.controller!.text;

        _isNegativeNotifier.value = text.startsWith('-');
        _textController.text = text;
        _isInitialValueNotifier.value = false;

        _focusNode.requestFocus();
        _textController.selection = TextSelection.collapsed(
          offset: text.length,
        );
      } else {
        _textController.clear();
        _isNegativeNotifier.value = false;
        _isInitialValueNotifier.value = false;

        _focusNode.requestFocus();
      }
    });
  }

  void _onFocusChange() {
    _isFocusedNotifier.value = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _isNegativeNotifier.dispose();
    _isInitialValueNotifier.dispose();
    _isFocusedNotifier.dispose();

    if (widget.controller == null) {
      _textController.dispose();
    }
    super.dispose();
  }

  void _appendToDisplay(String value) {
    if (_isInitialValueNotifier.value) {
      _textController.clear();
      _isInitialValueNotifier.value = false;
    }

    final text = _textController.text;
    final selection = _textController.selection;

    String newText;
    int newPosition;

    if (value == '.') {
      if (!text.contains('.')) {
        newText = '$text.';
        newPosition = newText.length;
      } else {
        return;
      }
    } else {
      newText = text.replaceRange(selection.start, selection.end, value);
      newPosition = selection.start + value.length;
    }

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newPosition),
    );

    _isNegativeNotifier.value = newText.startsWith('-');

    _focusNode.requestFocus();
  }

  void _toggleSign() {
    if (_isInitialValueNotifier.value) {
      _textController.clear();
      _isInitialValueNotifier.value = false;
    }

    String text = _textController.text;

    if (text.startsWith('-')) {
      text = text.substring(1);
    } else {
      text = '-$text';
    }

    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    _isNegativeNotifier.value = text.startsWith('-');
    _focusNode.requestFocus();
  }

  void _backspace() {
    final text = _textController.text;
    final selection = _textController.selection;

    if (_isInitialValueNotifier.value) {
      _textController.clear();
      _isInitialValueNotifier.value = false;
      _isNegativeNotifier.value = false;
      _focusNode.requestFocus();
      return;
    }

    if (selection.start == 0 && selection.end == 0) {
      _focusNode.requestFocus();
      return;
    }

    String newText;
    int newPosition;

    if (selection.start == selection.end) {
      if (selection.start > 0) {
        newText = text.replaceRange(selection.start - 1, selection.start, '');
        newPosition = selection.start - 1;
      } else {
        _focusNode.requestFocus();
        return;
      }
    } else {
      newText = text.replaceRange(selection.start, selection.end, '');
      newPosition = selection.start;
    }

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newPosition.clamp(0, newText.length),
      ),
    );

    _isNegativeNotifier.value = newText.startsWith('-');
    _focusNode.requestFocus();
  }

  void _clear() {
    _textController.clear();
    _isNegativeNotifier.value = false;
    _isInitialValueNotifier.value = false;
    widget.controller?.clear();
    _focusNode.requestFocus();
  }

  bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).size.width >
        MediaQuery.of(context).size.height;
  }

  @override
  Widget build(BuildContext context) {
    final landscape = isLandscape(context);

    if (!landscape) {
      return _buildPortraitMode(context);
    }

    return _buildLandscapeMode(context);
  }

  // ORIGINAL PORTRAIT MODE - NO CHANGES
  Widget _buildPortraitMode(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 350,
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
              Text(
                widget.varianceName ?? 'Enter Value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: _isFocusedNotifier,
                builder: (context, isFocused, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isFocused ? Colors.grey : Colors.grey.shade600,
                        width: 1.3,
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.none,
                      readOnly: true,
                      showCursor: true,
                      cursorColor: Colors.grey.shade800,
                      cursorWidth: 2,
                      cursorHeight: 32,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d{0,2}'),
                        ),
                      ],
                      enableInteractiveSelection: true,
                      enableIMEPersonalizedLearning: false,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWideButton('Clear', _clear),
                  const SizedBox(width: 14),
                  _buildWideButton('⌫', _backspace),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    'Close',
                    () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  _buildActionButton('Submit', () {
                    final text = _textController.text;
                    final value =
                        double.tryParse(text.isEmpty ? '0' : text) ?? 0;
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

  // COMPACT LANDSCAPE MODE - NO OVERFLOW
  Widget _buildLandscapeMode(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.28),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.varianceName ?? 'Enter Value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _isFocusedNotifier,
                  builder: (context, isFocused, child) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isFocused ? Colors.grey : Colors.grey.shade600,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.none,
                        readOnly: true,
                        showCursor: true,
                        cursorColor: Colors.grey.shade800,
                        cursorWidth: 1.5,
                        cursorHeight: 24,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d{0,2}'),
                          ),
                        ],
                        enableInteractiveSelection: true,
                        enableIMEPersonalizedLearning: false,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _landscapeRow(['1', '2', '3']),
                const SizedBox(height: 6),
                _landscapeRow(['4', '5', '6']),
                const SizedBox(height: 6),
                _landscapeRow(['7', '8', '9']),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _landscapeButton('.'),
                    _landscapeButton('0'),
                    _landscapeButton('-', onPressed: _toggleSign),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _landscapeWideButton('Clear', _clear),
                    const SizedBox(width: 8),
                    _landscapeWideButton('⌫', _backspace),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _landscapeActionButton(
                      'Close',
                      () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    _landscapeActionButton('Submit', () {
                      final text = _textController.text;
                      final value =
                          double.tryParse(text.isEmpty ? '0' : text) ?? 0;
                      widget.onValueSelected(value);
                      Navigator.of(context).pop();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((e) => _buildButton(e)).toList(),
    );
  }

  Widget _landscapeRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((e) => _landscapeButton(e)).toList(),
    );
  }

  Widget _buildButton(String text, {VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed();
        } else {
          _appendToDisplay(text);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        minimumSize: const Size(70, 52),
        elevation: 4,
        shadowColor: Colors.grey.shade400,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _landscapeButton(String text, {VoidCallback? onPressed}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            if (onPressed != null) {
              onPressed();
            } else {
              _appendToDisplay(text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: const Size(40, 36),
            elevation: 2,
            shadowColor: Colors.grey.shade400,
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildWideButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(115, 52),
        elevation: 4,
        shadowColor: Colors.grey.shade400,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _landscapeWideButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: const Size(60, 36),
            elevation: 2,
            shadowColor: Colors.grey.shade400,
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
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

  Widget _landscapeActionButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: const Size(60, 36),
            elevation: 2,
            shadowColor: Colors.blue.shade200,
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

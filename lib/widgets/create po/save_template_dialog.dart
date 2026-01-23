import 'package:flutter/material.dart';

class SaveTemplateDialog extends StatefulWidget {
  final Function(String) onSave;
  final String? initialName;

  const SaveTemplateDialog({super.key, required this.onSave, this.initialName});

  @override
  _SaveTemplateDialogState createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<SaveTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _templateNameController.text = widget.initialName!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.white, // ✅ White dialog
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: isMobile ? double.infinity : 420, // ✅ Responsive width
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Save as Template',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ✅ DESCRIPTION
              const Text(
                'Save this purchase order as a reusable template.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 20),

              // ✅ TEMPLATE NAME FIELD (BLUE BORDER)
              TextFormField(
                controller: _templateNameController,
                decoration: InputDecoration(
                  labelText: 'Template Name *',

                  // ✅ Center position (light)
                  labelStyle: TextStyle(
                    color: Colors.grey.shade400, // Light when not focused
                    fontWeight: FontWeight.w500,
                  ),

                  // ✅ Floating position (blue)
                  floatingLabelStyle: const TextStyle(
                    color: Colors.orange, // Blue on focus
                    fontWeight: FontWeight.w600,
                  ),

                  hintText: 'e.g. Monthly Order',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400, // Light hint
                    fontSize: 13,
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Colors.orangeAccent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Colors.orangeAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Template name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Minimum 3 characters required';
                  }
                  return null;
                },
                autofocus: true,
              ),

              const SizedBox(height: 24),

              // ✅ BUTTONS (SAME THEME)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ✅ CANCEL BUTTON
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),

                  const SizedBox(width: 12),

                  // ✅ SAVE BUTTON
                  ElevatedButton(
                    onPressed: _saveTemplate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,

                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                        vertical: isMobile ? 8 : 10,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
                      ),
                    ),
                    child: Text(
                      'Save Template',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTemplate() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_templateNameController.text.trim());
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }
}

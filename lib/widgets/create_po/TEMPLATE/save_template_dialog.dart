import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/utils/app_snackbar.dart';

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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: isMobile ? double.infinity : 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              const Text(
                'Save this purchase order as a reusable template.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _templateNameController,
                decoration: InputDecoration(
                  labelText: 'Template Name *',

                  labelStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),

                  floatingLabelStyle: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),

                  hintText: 'e.g. Monthly Order',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
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

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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

  void _saveTemplate() async {
    if (_formKey.currentState!.validate()) {
      try {
        await widget.onSave(_templateNameController.text.trim());

        if (!mounted) return;

        Navigator.of(context).pop();
      } catch (e, stackTrace) {
        if (!mounted) return;

        final appError = AppErrorHandler.handle(e, stackTrace: stackTrace);

        AppSnackbar.showError(context, appError);
      }
    }
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }
}

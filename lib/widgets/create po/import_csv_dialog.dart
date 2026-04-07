import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/import_provider.dart';

class ImportCSVDialog extends StatelessWidget {
  final Function(List items) onSuccess;

  const ImportCSVDialog({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImportProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          title: Row(
            children: const [
              Icon(Icons.upload_file, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "Import CSV",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: provider.isLoading
                ? _buildLoadingView(provider)
                : _buildUploadView(context, provider),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: provider.isLoading
              ? null
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
        );
      },
    );
  }

  Widget _buildUploadView(BuildContext context, ImportProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Upload CSV or Excel file",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),

        /// Upload Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.cloud_upload),
            label: const Text(
              "Choose File",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv', 'xlsx', 'xls'],
              );

              if (result == null) return;

              String path = result.files.single.path!;
              final data = await provider.uploadFile(path);

              if (data['success'] == true) {
                Navigator.pop(context);
                onSuccess(data['imported_items']);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Successfully imported ${data['imported_items'].length} items",
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),

                    behavior: SnackBarBehavior.floating, 

                    margin: const EdgeInsets.only(
                      bottom: 80, 
                      left: 16,
                      right: 16,
                    ),
                  ),
                );
              } else {
                _showErrorDialog(context, data['errors']);
              }
            },
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          "Supported formats: CSV, XLSX, XLS",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLoadingView(ImportProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress Circle
        SizedBox(
          height: 100,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: provider.uploadProgress,
                    strokeWidth: 5,
                    backgroundColor: Colors.blue.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
                Text(
                  provider.uploadProgress == null
                      ? "0%"
                      : "${(provider.uploadProgress! * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // File Name
        if (provider.currentFileName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              provider.currentFileName!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

        const SizedBox(height: 12),

        // Status Message
        Text(
          provider.uploadStatus ?? "Processing...",
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Small helper text
        Text(
          "Please wait...",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, List errors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: const Text(
          "Import Errors",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

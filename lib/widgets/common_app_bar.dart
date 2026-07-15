import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:purchaseorders2/services/auth_service.dart';
import 'package:purchaseorders2/services/session_service.dart';
import 'package:purchaseorders2/services/ai/global_ai_scan_flow.dart';
import 'package:purchaseorders2/widgets/ai/scan_invoice_sheet.dart';

// =====================================================
// FIXED: Constants with lowerCamelCase naming
// =====================================================
const int maxImageCount = 5;
const int maxPdfSizeMb = 10;
const int maxImageSizeMb = 5;

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isLoading;

  static final ValueNotifier<String?> selectedLabel = ValueNotifier<String?>(
    'Home',
  );

  static final ValueNotifier<String?> hoveredLabel = ValueNotifier<String?>('');

  const CommonAppBar({super.key, required this.title, this.isLoading = false});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isTablet = screenWidth > 600;

    return AppBar(
      leadingWidth: 72,
      toolbarHeight: preferredSize.height,

      backgroundColor: Colors.blueAccent,

      elevation: 4,

      automaticallyImplyLeading: false,

      centerTitle: true,
      titleSpacing: 0,
      //LEFT SIDE SCAN / UPLOAD
      leading: IconButton(
        tooltip: "Scan Invoice",

        onPressed: () async {
          final selected = await showModalBottomSheet<String>(
            context: context,

            backgroundColor: Colors.white,

            builder: (_) {
              return const ScanInvoiceSheet();
            },
          );

          if (selected == null) {
            return;
          }

          File? selectedFile;
          List<File>? selectedFiles;

          // =====================================================
          // CAMERA - WITH SIZE VALIDATION
          // =====================================================

          if (selected == "camera") {
            final picker = ImagePicker();

            final picked = await picker.pickImage(source: ImageSource.camera);

            if (picked == null) {
              return;
            }

            // =====================================================
            // ADDED: Image Size Validation
            // =====================================================
            final file = File(picked.path);
            final fileSize = await file.length();
            final maxSizeBytes = maxImageSizeMb * 1024 * 1024;

            if (fileSize > maxSizeBytes) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      "Image too large. Max size: $maxImageSizeMb MB. Your file: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB",
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return;
            }

            selectedFile = file;

            debugPrint("CAMERA IMAGE SELECTED: ${selectedFile.path}");
          }
          // =====================================================
          // GALLERY (MULTIPLE IMAGES) - WITH VALIDATION
          // =====================================================
          else if (selected == "gallery") {
            final picker = ImagePicker();

            final pickedImages = await picker.pickMultiImage(imageQuality: 80);

            if (pickedImages.isEmpty) {
              return;
            }

            // =====================================================
            // VALIDATION 1: MAX 5 IMAGES
            // =====================================================
            if (pickedImages.length > maxImageCount) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      "Maximum $maxImageCount images allowed. You selected ${pickedImages.length} images.",
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return;
            }

            // =====================================================
            // VALIDATION 2: Each Image Size
            // =====================================================
            final maxSizeBytes = maxImageSizeMb * 1024 * 1024;
            bool sizeExceeded = false;
            String oversizedFile = "";

            for (var picked in pickedImages) {
              final file = File(picked.path);
              final fileSize = await file.length();
              if (fileSize > maxSizeBytes) {
                sizeExceeded = true;
                oversizedFile = picked.name;
                break;
              }
            }

            if (sizeExceeded) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      "Image '$oversizedFile' is too large. Max size: $maxImageSizeMb MB per image.",
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return;
            }

            selectedFiles = pickedImages.map((e) => File(e.path)).toList();

            debugPrint("MULTIPLE IMAGES PICKED: ${selectedFiles.length}");
            for (int i = 0; i < selectedFiles.length; i++) {
              debugPrint("  IMAGE ${i + 1}: ${selectedFiles[i].path}");
            }

            // If only one image is selected, treat it as a single image.
            if (selectedFiles.length == 1) {
              selectedFile = selectedFiles.first;
              selectedFiles = null;
            }
          }
          // =====================================================
          // PDF - WITH SIZE VALIDATION
          // =====================================================
          else if (selected == "pdf") {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,

              allowedExtensions: ["pdf"],
            );

            if (result == null || result.files.single.path == null) {
              return;
            }

            // =====================================================
            // ADDED: PDF Size Validation
            // =====================================================
            final fileSize = result.files.single.size; // in bytes
            final maxSizeBytes = maxPdfSizeMb * 1024 * 1024;

            if (fileSize > maxSizeBytes) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      "PDF too large. Max size: $maxPdfSizeMb MB. Your file: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB",
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return;
            }

            selectedFile = File(result.files.single.path!);

            debugPrint("PDF SELECTED: ${selectedFile.path}");
          }

          // =====================================================
          // SAFETY CHECK
          // =====================================================

          if (selectedFile == null &&
              (selectedFiles == null || selectedFiles!.isEmpty)) {
            debugPrint("NO FILE SELECTED - ABORTING");
            return;
          }

          // =====================================================
          // START AI FLOW - WITH ERROR HANDLING
          // =====================================================

          if (selectedFiles != null && selectedFiles!.isNotEmpty) {
            debugPrint("STARTING AI FLOW WITH ${selectedFiles!.length} IMAGES");
            try {
              await scanAndOpenPOFlow(context: context, files: selectedFiles);
            } catch (e) {
              // =====================================================
              // SHOW ERROR MESSAGE TO USER (Including Blur Detection)
              // =====================================================
              if (context.mounted) {
                String errorMessage = e.toString();
                
                // Check for blur error from backend
                if (errorMessage.contains("blurry") || 
                    errorMessage.contains("Image quality") ||
                    errorMessage.contains("clearer image") ||
                    errorMessage.contains("blur")) {
                  errorMessage = "📸 Image is blurry. Please take a clearer photo.";
                }
                // Check for other image quality issues
                else if (errorMessage.contains("Unable to read image")) {
                  errorMessage = "❌ Unable to read the image. Please try again.";
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(errorMessage),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          } else if (selectedFile != null) {
            debugPrint(
              "STARTING AI FLOW WITH SINGLE FILE: ${selectedFile.path}",
            );
            try {
              await scanAndOpenPOFlow(context: context, file: selectedFile);
            } catch (e) {
              // =====================================================
              // SHOW ERROR MESSAGE TO USER (Including Blur Detection)
              // =====================================================
              if (context.mounted) {
                String errorMessage = e.toString();
                
                // Check for blur error from backend
                if (errorMessage.contains("blurry") || 
                    errorMessage.contains("Image quality") ||
                    errorMessage.contains("clearer image") ||
                    errorMessage.contains("blur")) {
                  errorMessage = "📸 Image is blurry. Please take a clearer photo.";
                }
                // Check for other image quality issues
                else if (errorMessage.contains("Unable to read image")) {
                  errorMessage = "❌ Unable to read the image. Please try again.";
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(errorMessage),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          }
        },
        icon: const Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 22),

            SizedBox(height: 2),

            Text(
              "AI Scan",

              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: isTablet ? 20 : 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      actions: isLoading
          ? [
              const Padding(
                padding: EdgeInsets.only(right: 16),

                child: Center(
                  child: SizedBox(
                    width: 18,

                    height: 18,

                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,

                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ]
          : [
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,

                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),

                      title: const Text(
                        "Logout",

                        style: TextStyle(
                          fontWeight: FontWeight.bold,

                          color: Colors.black,
                        ),
                      ),

                      content: const Text(
                        "Are you sure you want to logout?",

                        style: TextStyle(fontSize: 14),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),

                          child: const Text(
                            "Cancel",

                            style: TextStyle(
                              color: Colors.blueAccent,

                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,

                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),

                          onPressed: () => Navigator.pop(context, true),

                          child: const Text(
                            "Logout",

                            style: TextStyle(
                              color: Colors.white,

                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) {
                    return;
                  }

                  // Loading dialog
                  if (context.mounted) {
                    showDialog(
                      context: context,

                      barrierDismissible: false,

                      barrierColor: Colors.black.withOpacity(0.5),

                      builder: (context) => WillPopScope(
                        onWillPop: () async => false,

                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(16),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),

                                  blurRadius: 10,

                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),

                            child: Column(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                const SizedBox(
                                  width: 40,

                                  height: 40,

                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,

                                    color: Colors.blueAccent,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Text(
                                  "You are logging out...",

                                  style: TextStyle(
                                    fontSize: 16,

                                    fontWeight: FontWeight.w500,

                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  await AuthService.logout();

                  SessionService.stop();

                  if (context.mounted) {
                    Navigator.pop(context);

                    Navigator.pushNamedAndRemoveUntil(
                      context,

                      '/login',

                      (route) => false,
                    );
                  }
                },

                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: const [
                      Icon(Icons.logout, color: Colors.white, size: 22),

                      SizedBox(height: 2),

                      Text(
                        "Logout",

                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
    );
  }
}
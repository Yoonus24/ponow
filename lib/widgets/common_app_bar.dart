import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:purchaseorders2/services/auth_service.dart';
import 'package:purchaseorders2/services/session_service.dart';
import 'package:purchaseorders2/services/ai/global_ai_scan_flow.dart';
import 'package:purchaseorders2/widgets/ai/scan_invoice_sheet.dart';

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

          // =====================================================
          // CAMERA
          // =====================================================

          if (selected == "camera") {
            final picker = ImagePicker();

            final picked = await picker.pickImage(source: ImageSource.camera);

            if (picked == null) {
              return;
            }

            selectedFile = File(picked.path);
          }
          // =====================================================
          // GALLERY
          // =====================================================
          else if (selected == "gallery") {
            final picker = ImagePicker();

            final picked = await picker.pickImage(source: ImageSource.gallery);

            if (picked == null) {
              return;
            }

            selectedFile = File(picked.path);
          }
          // =====================================================
          // PDF
          // =====================================================
          else if (selected == "pdf") {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,

              allowedExtensions: ["pdf"],
            );

            if (result == null || result.files.single.path == null) {
              return;
            }

            selectedFile = File(result.files.single.path!);
          }

          // =====================================================
          // SAFETY CHECK
          // =====================================================

          if (selectedFile == null) {
            return;
          }

          // =====================================================
          // START AI FLOW
          // =====================================================

          await scanAndOpenPOFlow(context: context, file: selectedFile);
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

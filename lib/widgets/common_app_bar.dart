// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:purchaseorders2/services/auth_service.dart';
import 'package:purchaseorders2/services/session_service.dart';

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
      toolbarHeight: preferredSize.height,
      backgroundColor: Colors.blueAccent,
      elevation: 4,
      automaticallyImplyLeading: false,
      centerTitle: true,

      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: isTablet ? 20 : 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
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

                  if (confirm != true) return;

                  // 🔄 Loading dialog
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.white, size: 22),
                      SizedBox(height: 2),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10, // 👈 small text
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
    );
  }
}

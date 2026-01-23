import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isLoading; 

  static final ValueNotifier<String?> selectedLabel = ValueNotifier<String?>(
    'Home',
  );

  static final ValueNotifier<String?> hoveredLabel = ValueNotifier<String?>('');

  const CommonAppBar({
    super.key,
    required this.title,
    this.isLoading = false,
  });

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
          : null,
    );
  }
}

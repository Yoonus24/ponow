import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int index) onTabChanged;
  final VoidCallback onCreatePO;

  const CommonBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onCreatePO,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    // ---------- RESPONSIVE CALCULATIONS ----------
    final bool isTablet = width >= 600;

    final double navHeight = isTablet ? 72 : (height * 0.085).clamp(60, 70);

    final double iconSize = isTablet ? 28 : (width * 0.065).clamp(22, 26);

    final double fontSize = isTablet ? 12 : (width * 0.030).clamp(10, 12);

    final double verticalPadding = isTablet ? 6 : 4;

    return SafeArea(
      top: false,
      child: Container(
        height: navHeight,
        padding: EdgeInsets.only(bottom: verticalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            _navItem(
              label: "Create PO",
              icon: Icons.add_circle_outline_rounded,
              iconSize: iconSize,
              fontSize: fontSize,
              isSelected: false,
              onTap: onCreatePO,
            ),
            _navItem(
              label: "Home",
              icon: Icons.home_filled,
              iconSize: iconSize,
              fontSize: fontSize,
              isSelected: currentIndex == 0,
              onTap: () => _onTabTap(0),
            ),
            _navItem(
              label: "Approved",
              icon: Icons.check_circle_outline_rounded,
              iconSize: iconSize,
              fontSize: fontSize,
              isSelected: currentIndex == 1,
              onTap: () => _onTabTap(1),
            ),
            _navItem(
              label: "GRN",
              icon: Icons.receipt_long_rounded,
              iconSize: iconSize,
              fontSize: fontSize,
              isSelected: currentIndex == 2,
              onTap: () => _onTabTap(2),
            ),
            _navItem(
              label: "AP Invoice",
              icon: Icons.article_rounded,
              iconSize: iconSize,
              fontSize: fontSize,
              isSelected: currentIndex == 3,
              onTap: () => _onTabTap(3),
            ),
            _navItem(
              label: "Outgoing",
              icon: Icons.payments_rounded,
              iconSize: iconSize,
              fontSize: fontSize,
              isSelected: currentIndex == 4,
              onTap: () => _onTabTap(4),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabTap(int index) {
    HapticFeedback.lightImpact();
    onTabChanged(index);
  }

  Widget _navItem({
    required String label,
    required IconData icon,
    required double iconSize,
    required double fontSize,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.20 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Container(
                padding: EdgeInsets.all(isSelected ? 4 : 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blueAccent.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isSelected ? Colors.blueAccent : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.blueAccent : Colors.grey.shade700,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

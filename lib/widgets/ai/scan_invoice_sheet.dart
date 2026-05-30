import 'package:flutter/material.dart';

class ScanInvoiceSheet extends StatelessWidget {
  const ScanInvoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            const _DragHandle(),
            const SizedBox(height: 16),

            // Header Section
            const _HeaderSection(),
            const SizedBox(height: 8),

            // Subtitle
            const _SubtitleSection(),
            const SizedBox(height: 20),

            // Action Cards - 2x2 Grid
            const _ActionCardsSection(),

            // Bottom Spacing - Dynamic
            SizedBox(
              height: bottomPadding > 0
                  ? bottomPadding + 16
                  : MediaQuery.of(context).padding.bottom + 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Drag handle widget
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: const Center(child: _DragHandleBar()),
    );
  }
}

class _DragHandleBar extends StatelessWidget {
  const _DragHandleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// Header section
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 380
        ? 24.0
        : screenWidth < 600
        ? 28.0
        : 32.0;
    final fontSize = screenWidth < 380
        ? 18.0
        : screenWidth < 600
        ? 22.0
        : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth < 380 ? 20 : 24),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: const Color(0xFF6366F1),
            size: iconSize,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "AI Invoice Assistant",
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Subtitle section
class _SubtitleSection extends StatelessWidget {
  const _SubtitleSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 380
        ? 12.0
        : screenWidth < 600
        ? 13.0
        : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth < 380 ? 20 : 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Let AI help you scan and process invoices",
          style: TextStyle(
            fontSize: fontSize,
            color: const Color(0xFF6B7280),
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// Action cards section - 2x2 Grid Layout
class _ActionCardsSection extends StatelessWidget {
  const _ActionCardsSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 380 ? 20.0 : 24.0;
    final spacing = screenWidth < 380 ? 12.0 : 16.0;

    // Responsive aspect ratio
    double aspectRatio;
    if (screenWidth < 380) {
      aspectRatio = 1.0;
    } else if (screenWidth < 480) {
      aspectRatio = 1.05;
    } else {
      aspectRatio = 1.1;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
        children: const [
          _QuickActionCard(
            icon: Icons.camera_alt_rounded,
            iconColor: Color(0xFF6366F1),
            label: "AI Scan",
            subtitle: "Smart Capture",
            value: "camera",
          ),
          _QuickActionCard(
            icon: Icons.image_rounded,
            iconColor: Color(0xFF10B981),
            label: "Gallery",
            subtitle: "Upload Image",
            value: "gallery",
          ),
          _QuickActionCard(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: Color(0xFFE53935),
            label: "PDF",
            subtitle: "Upload PDF",
            value: "pdf",
          ),
          _QuickActionCard(
            icon: Icons.inventory_2_rounded,
            iconColor: Color(0xFFFF9800),
            label: "Buckets",
            subtitle: "Pending List",
            value: "buckets",
          ),
        ],
      ),
    );
  }
}

// Optimized card widget - Fully Responsive
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String value;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen width
    double verticalPadding;
    double horizontalPadding;
    double iconSize;
    double iconContainerPadding;
    double labelFontSize;
    double subtitleFontSize;
    double gapSize;

    if (screenWidth < 380) {
      // Very small phones
      verticalPadding = 14.0;
      horizontalPadding = 8.0;
      iconSize = 22.0;
      iconContainerPadding = 10.0;
      labelFontSize = 12.0;
      subtitleFontSize = 9.0;
      gapSize = 6.0;
    } else if (screenWidth < 480) {
      // Small phones
      verticalPadding = 16.0;
      horizontalPadding = 10.0;
      iconSize = 26.0;
      iconContainerPadding = 12.0;
      labelFontSize = 13.0;
      subtitleFontSize = 10.0;
      gapSize = 8.0;
    } else if (screenWidth < 600) {
      // Medium phones
      verticalPadding = 18.0;
      horizontalPadding = 12.0;
      iconSize = 30.0;
      iconContainerPadding = 13.0;
      labelFontSize = 14.0;
      subtitleFontSize = 11.0;
      gapSize = 10.0;
    } else {
      // Tablets and large screens
      verticalPadding = 22.0;
      horizontalPadding = 16.0;
      iconSize = 34.0;
      iconContainerPadding = 15.0;
      labelFontSize = 15.0;
      subtitleFontSize = 12.0;
      gapSize = 12.0;
    }

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.pop(context, value),
          borderRadius: BorderRadius.circular(20),
          splashColor: iconColor.withOpacity(0.12),
          highlightColor: iconColor.withOpacity(0.06),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconContainer(
                  icon: icon,
                  color: iconColor,
                  iconSize: iconSize,
                  padding: iconContainerPadding,
                ),
                SizedBox(height: gapSize),
                _CardLabel(label: label, fontSize: labelFontSize),
                const SizedBox(height: 4),
                _CardSubtitle(subtitle: subtitle, fontSize: subtitleFontSize),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Icon Container
class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double iconSize;
  final double padding;

  const _IconContainer({
    required this.icon,
    required this.color,
    this.iconSize = 32,
    this.padding = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

// Card Label
class _CardLabel extends StatelessWidget {
  final String label;
  final double fontSize;

  const _CardLabel({required this.label, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Card Subtitle
class _CardSubtitle extends StatelessWidget {
  final String subtitle;
  final double fontSize;

  const _CardSubtitle({required this.subtitle, this.fontSize = 11.5});

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: fontSize, color: const Color(0xFF6B7280)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Theme extensions
extension ThemeColors on Color {
  static const Color primary = Color(0xFF6366F1);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
}
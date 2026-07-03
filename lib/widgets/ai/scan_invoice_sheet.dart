import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// Main Bottom Sheet Widget
// ============================================================================

class ScanInvoiceSheet extends StatelessWidget {
  const ScanInvoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ResponsiveBottomSheet(child: _ScanInvoiceSheetContent());
  }
}

// ============================================================================
// Responsive Wrapper for Performance
// ============================================================================

class _ResponsiveBottomSheet extends StatelessWidget {
  final Widget child;

  const _ResponsiveBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: child,
      ),
    );
  }
}

// ============================================================================
// Main Content (Optimized with RepaintBoundary)
// ============================================================================

class _ScanInvoiceSheetContent extends StatelessWidget {
  const _ScanInvoiceSheetContent();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.paddingOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return RepaintBoundary(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            const SizedBox(height: 16),
            const _HeaderSection(),
            const SizedBox(height: 8),
            const _SubtitleSection(),
            const SizedBox(height: 20),
            _ActionCardsSection(screenWidth: screenWidth),
            SizedBox(
              height: viewInsets.bottom > 0
                  ? viewInsets.bottom + 16
                  : padding.bottom + 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Drag Handle Component
// ============================================================================

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return const Center(child: _DragHandleBar());
  }
}

class _DragHandleBar extends StatelessWidget {
  const _DragHandleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ============================================================================
// Header Section
// ============================================================================

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final theme = _HeaderTheme.fromWidth(screenWidth);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.horizontalPadding),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppColors.primary,
            size: theme.iconSize,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "AI Invoice Assistant",
              style: TextStyle(
                fontSize: theme.fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
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

@immutable
class _HeaderTheme {
  final double iconSize;
  final double fontSize;
  final double horizontalPadding;

  const _HeaderTheme({
    required this.iconSize,
    required this.fontSize,
    required this.horizontalPadding,
  });

  factory _HeaderTheme.fromWidth(double width) {
    if (width < 380) {
      return const _HeaderTheme(
        iconSize: 24,
        fontSize: 18,
        horizontalPadding: 20,
      );
    } else if (width < 600) {
      return const _HeaderTheme(
        iconSize: 28,
        fontSize: 22,
        horizontalPadding: 24,
      );
    } else {
      return const _HeaderTheme(
        iconSize: 32,
        fontSize: 24,
        horizontalPadding: 24,
      );
    }
  }
}

// ============================================================================
// Subtitle Section
// ============================================================================

class _SubtitleSection extends StatelessWidget {
  const _SubtitleSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize = screenWidth < 380
        ? 12.0
        : screenWidth < 600
        ? 13.0
        : 14.0;
    final horizontalPadding = screenWidth < 380 ? 20.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Let AI help you scan and process invoices",
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textLight,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ============================================================================
// Action Cards Section (3 Cards in a Row)
// ============================================================================

class _ActionCardsSection extends StatelessWidget {
  final double screenWidth;

  const _ActionCardsSection({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final spacing = screenWidth < 380 ? 10.0 : 12.0;
    final horizontalPadding = screenWidth < 380 ? 20.0 : 24.0;
    final cardConfig = _CardConfig.fromWidth(screenWidth);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              config: cardConfig,
              icon: Icons.camera_alt_rounded,
              iconColor: AppColors.primary,
              label: "AI Scan",
              subtitle: "Smart Capture",
              value: "camera",
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _QuickActionCard(
              config: cardConfig,
              icon: Icons.image_rounded,
              iconColor: AppColors.success,
              label: "Gallery",
              subtitle: "Upload Image",
              value: "gallery",
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _QuickActionCard(
              config: cardConfig,
              icon: Icons.picture_as_pdf_rounded,
              iconColor: AppColors.danger,
              label: "PDF",
              subtitle: "Upload PDF",
              value: "pdf",
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Card Configuration (Theme)
// ============================================================================

@immutable
class _CardConfig {
  final double verticalPadding;
  final double horizontalPadding;
  final double iconSize;
  final double iconContainerPadding;
  final double labelFontSize;
  final double subtitleFontSize;
  final double gapSize;
  final double borderRadius;

  const _CardConfig({
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.iconSize,
    required this.iconContainerPadding,
    required this.labelFontSize,
    required this.subtitleFontSize,
    required this.gapSize,
    this.borderRadius = 20,
  });

  factory _CardConfig.fromWidth(double width) {
    if (width < 380) {
      return const _CardConfig(
        verticalPadding: 12,
        horizontalPadding: 6,
        iconSize: 20,
        iconContainerPadding: 8,
        labelFontSize: 11,
        subtitleFontSize: 9,
        gapSize: 6,
      );
    } else if (width < 480) {
      return const _CardConfig(
        verticalPadding: 14,
        horizontalPadding: 8,
        iconSize: 22,
        iconContainerPadding: 10,
        labelFontSize: 12,
        subtitleFontSize: 10,
        gapSize: 8,
      );
    } else if (width < 600) {
      return const _CardConfig(
        verticalPadding: 16,
        horizontalPadding: 10,
        iconSize: 24,
        iconContainerPadding: 11,
        labelFontSize: 13,
        subtitleFontSize: 10,
        gapSize: 10,
      );
    } else {
      return const _CardConfig(
        verticalPadding: 18,
        horizontalPadding: 12,
        iconSize: 28,
        iconContainerPadding: 12,
        labelFontSize: 14,
        subtitleFontSize: 11,
        gapSize: 12,
      );
    }
  }
}

// ============================================================================
// Optimized Quick Action Card (Performance Optimized)
// ============================================================================

class _QuickActionCard extends StatelessWidget {
  final _CardConfig config;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String value;

  const _QuickActionCard({
    required this.config,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(config.borderRadius),
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(config.borderRadius),
          splashColor: iconColor.withOpacity(0.12),
          highlightColor: iconColor.withOpacity(0.06),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: config.verticalPadding,
              horizontal: config.horizontalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(config.borderRadius),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              // boxShadow: kElevationToShadow[1],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OptimizedIconContainer(
                  icon: icon,
                  color: iconColor,
                  size: config.iconSize,
                  padding: config.iconContainerPadding,
                ),
                SizedBox(height: config.gapSize),
                _CardLabel(label: label, fontSize: config.labelFontSize),
                const SizedBox(height: 4),
                _CardSubtitle(
                  subtitle: subtitle,
                  fontSize: config.subtitleFontSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context, value);
  }
}

// ============================================================================
// Optimized Icon Container (Cacheable)
// ============================================================================

class _OptimizedIconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double padding;

  const _OptimizedIconContainer({
    required this.icon,
    required this.color,
    required this.size,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

// ============================================================================
// Card Label Component
// ============================================================================

class _CardLabel extends StatelessWidget {
  final String label;
  final double fontSize;

  const _CardLabel({required this.label, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ============================================================================
// Card Subtitle Component
// ============================================================================

class _CardSubtitle extends StatelessWidget {
  final String subtitle;
  final double fontSize;

  const _CardSubtitle({required this.subtitle, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: fontSize, color: AppColors.textLight),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ============================================================================
// App Colors (Centralized Theme Management)
// ============================================================================

@immutable
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF6366F1);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color background = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
}

// ============================================================================
// Shadow Extension (Cached Shadows for Performance)
// ============================================================================

const List<BoxShadow> kElevationToShadow = [
  BoxShadow(blurRadius: 0, offset: Offset(0, 0), spreadRadius: 0),
  BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8,
    offset: Offset(0, 1),
    spreadRadius: 0,
  ),
  BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 12,
    offset: Offset(0, 2),
    spreadRadius: 0,
  ),
];

// ============================================================================
// MediaQuery Extension (Cleaner API)
// ============================================================================

extension MediaQueryExtensions on MediaQuery {
  static EdgeInsets paddingOf(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  static EdgeInsets viewInsetsOf(BuildContext context) {
    return MediaQuery.of(context).viewInsets;
  }

  static Size sizeOf(BuildContext context) {
    return MediaQuery.of(context).size;
  }
}

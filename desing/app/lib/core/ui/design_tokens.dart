import 'package:flutter/material.dart';

/// Design Tokens - DESIGN_SYSTEM.md Compliance
///
/// This file centralizes all design tokens per DESIGN_SYSTEM.md:
/// - 8pt grid spacing
/// - Card radius: 16
/// - Button height: 48
/// - Premium, calm, trust-building aesthetic
class AppSpacing {
  AppSpacing._();

  /// Base unit: 8pt grid system
  static const double unit = 8.0;

  static const double xs = 8.0; // 1 unit
  static const double sm = 16.0; // 2 units
  static const double md = 24.0; // 3 units
  static const double lg = 32.0; // 4 units
  static const double xl = 40.0; // 5 units
  static const double xxl = 48.0; // 6 units
}

class AppRadius {
  AppRadius._();

  /// Card radius per DESIGN_SYSTEM.md
  static const double card = 16.0;

  /// Button radius
  static const double button = 12.0;

  /// Chip/badge radius
  static const double chip = 8.0;

  /// Avatar radius (circular)
  static const double avatarSmall = 20.0;
  static const double avatarMedium = 24.0;
  static const double avatarLarge = 50.0;
}

class AppButton {
  AppButton._();

  /// Primary button height per DESIGN_SYSTEM.md
  static const double height = 48.0;

  /// Secondary button height
  static const double heightSmall = 40.0;
}

class AppShadows {
  AppShadows._();

  /// Very light shadow per DESIGN_SYSTEM.md (won't clutter UI)
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Elevated shadow for floating elements
  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Badge text standards per DESIGN_SYSTEM.md
class AppBadges {
  AppBadges._();

  /// Price levels
  static const List<String> priceLevels = ['€', '€€', '€€€'];

  /// Local/Tourist indicators
  static String localBadge(String type) {
    switch (type) {
      case 'local':
        return 'Local favorite';
      case 'tourist':
        return 'Mostly tourist';
      case 'hidden':
        return 'Hidden gem';
      default:
        return '';
    }
  }

  /// AI confidence levels
  static String confidenceLabel(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return 'Low confidence';
      case 'medium':
        return 'Medium confidence';
      case 'high':
        return 'High confidence';
      default:
        return 'AI summary';
    }
  }
}

/// Typography presets per COMPONENT_LIBRARY.md
class AppTypography {
  AppTypography._();

  static const TextStyle appTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle priceText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}

/// App color palette - premium, calm aesthetic
class AppColors {
  AppColors._();

  // Primary accent
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1E40AF);

  // Secondary accent
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryLight = Color(0xFFA5B4FC);
  static const Color secondaryDark = Color(0xFF4338CA);

  // Neutral backgrounds
  static const Color backgroundPrimary = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  // Trust indicators
  static const Color verified = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Badge colors
  static const Color sponsoredBg = Color(0xFFFEF3C7);
  static const Color sponsoredText = Color(0xFFB45309);
  static const Color localBadgeBg = Color(0xFFDCFCE7);
  static const Color localBadgeText = Color(0xFF166534);

  // AI indicator
  static const Color aiBg = Color(0xFFEDE9FE);
  static const Color aiText = Color(0xFF7C3AED);

  // Confidence levels
  static const Color confidenceHigh = Color(0xFF10B981);
  static const Color confidenceMedium = Color(0xFFF59E0B);
  static const Color confidenceLow = Color(0xFFEF4444);
}

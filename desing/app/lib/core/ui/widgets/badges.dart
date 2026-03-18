import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// COMPONENT_LIBRARY.md compliant badge widgets
/// Trust signals, sponsored labels, verified badges

/// Verified Host/Guest badge per DESIGN_SYSTEM.md
class VerifiedBadge extends StatelessWidget {
  final String type; // 'host' or 'guest'

  const VerifiedBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.verified.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: AppColors.verified),
          const SizedBox(width: 4),
          Text(
            type == 'host' ? 'Verified Host' : 'Verified Guest',
            style: AppTypography.badgeText.copyWith(color: AppColors.verified),
          ),
        ],
      ),
    );
  }
}

/// Sponsored content badge - ALWAYS visible per GUARDRAILS
class SponsoredBadge extends StatelessWidget {
  const SponsoredBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.sponsoredBg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        'SPONSORED',
        style: AppTypography.badgeText.copyWith(color: AppColors.sponsoredText),
      ),
    );
  }
}

/// Local/Tourist indicator badge per DESIGN_SYSTEM.md
class LocalBadge extends StatelessWidget {
  final String type; // 'local', 'tourist', 'hidden'

  const LocalBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final label = AppBadges.localBadge(type);
    final isLocal = type == 'local' || type == 'hidden';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isLocal
            ? AppColors.localBadgeBg
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: isLocal ? AppColors.localBadgeText : Colors.orange[800],
        ),
      ),
    );
  }
}

/// Price level badge (€, €€, €€€) per DESIGN_SYSTEM.md
class PriceLevelBadge extends StatelessWidget {
  final int level; // 1, 2, or 3
  final String? priceRange; // e.g., "70–120 €"

  const PriceLevelBadge({super.key, required this.level, this.priceRange});

  @override
  Widget build(BuildContext context) {
    final text = priceRange ?? List.filled(level.clamp(1, 3), '€').join();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        text,
        style: AppTypography.badgeText.copyWith(
          color: Colors.grey[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// AI Summary indicator with confidence level per DESIGN_SYSTEM.md
class AIConfidenceBadge extends StatelessWidget {
  final String confidenceLevel; // 'low', 'medium', 'high'

  const AIConfidenceBadge({super.key, required this.confidenceLevel});

  Color get _confidenceColor {
    switch (confidenceLevel.toLowerCase()) {
      case 'high':
        return AppColors.confidenceHigh;
      case 'medium':
        return AppColors.confidenceMedium;
      case 'low':
        return AppColors.confidenceLow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.aiBg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 12, color: AppColors.aiText),
              const SizedBox(width: 4),
              Text(
                'AI summary',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.aiText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Confidence level
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _confidenceColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            AppBadges.confidenceLabel(confidenceLevel),
            style: AppTypography.badgeText.copyWith(color: _confidenceColor),
          ),
        ),
      ],
    );
  }
}

/// Rating display with star icon
class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;

  const RatingBadge({super.key, required this.rating, this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../design_tokens.dart';
import 'badges.dart';

/// COMPONENT_LIBRARY.md compliant card widgets
/// ExperienceCard, StayCard, PostCard, PlaceCard

/// Experience Card per COMPONENT_LIBRARY.md
/// Shows: title, duration, price_range, rating, local_badge, sponsored_badge
class ExperienceCard extends StatelessWidget {
  final String id;
  final String title;
  final String? imageUrl;
  final int? durationMinutes;
  final int? priceMin;
  final int? priceMax;
  final String currency;
  final double? rating;
  final int? reviewCount;
  final String? localScore; // 'local', 'tourist', 'hidden', or null
  final bool isSponsored;
  final VoidCallback onTap;

  const ExperienceCard({
    super.key,
    required this.id,
    required this.title,
    this.imageUrl,
    this.durationMinutes,
    this.priceMin,
    this.priceMax,
    this.currency = '€',
    this.rating,
    this.reviewCount,
    this.localScore,
    this.isSponsored = false,
    required this.onTap,
  });

  String get _priceText {
    if (priceMin != null && priceMax != null) {
      return '$currency$priceMin–$currency$priceMax';
    } else if (priceMin != null) {
      return 'From $currency$priceMin';
    }
    return 'Price TBD';
  }

  String get _durationText {
    if (durationMinutes == null) return '';
    if (durationMinutes! >= 60) {
      final hours = durationMinutes! ~/ 60;
      final mins = durationMinutes! % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${durationMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                // Sponsored badge (top-right)
                if (isSponsored)
                  const Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: SponsoredBadge(),
                  ),
                // Duration badge (bottom-left)
                if (durationMinutes != null)
                  Positioned(
                    bottom: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        _durationText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      if (localScore != null) ...[
                        LocalBadge(type: localScore!),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      if (rating != null)
                        RatingBadge(rating: rating!, reviewCount: reviewCount),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Title
                  Text(
                    title,
                    style: AppTypography.sectionTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Price
                  Text(
                    _priceText,
                    style: AppTypography.priceText.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(Icons.explore, size: 48, color: Colors.grey[400]),
    );
  }
}

/// Stay Card per COMPONENT_LIBRARY.md
/// Shows: title, nightly_price, host_badge, rating, room_type, sponsored_badge
class StayCard extends StatelessWidget {
  final String id;
  final String title;
  final String? imageUrl;
  final int? pricePerNight;
  final String currency;
  final double? rating;
  final int? reviewCount;
  final String? roomType;
  final bool verifiedHost;
  final bool isSponsored;
  final VoidCallback onTap;

  const StayCard({
    super.key,
    required this.id,
    required this.title,
    this.imageUrl,
    this.pricePerNight,
    this.currency = '€',
    this.rating,
    this.reviewCount,
    this.roomType,
    this.verifiedHost = false,
    this.isSponsored = false,
    required this.onTap,
  });

  String get _roomTypeLabel {
    switch (roomType) {
      case 'entire_place':
        return 'Entire place';
      case 'private_room':
        return 'Private room';
      case 'shared_room':
        return 'Shared room';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                if (isSponsored)
                  const Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: SponsoredBadge(),
                  ),
              ],
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      if (roomType != null && _roomTypeLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            _roomTypeLabel,
                            style: AppTypography.badgeText.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      if (verifiedHost) ...[
                        const SizedBox(width: 8),
                        const VerifiedBadge(type: 'host'),
                      ],
                      const Spacer(),
                      if (rating != null)
                        RatingBadge(rating: rating!, reviewCount: reviewCount),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Title
                  Text(
                    title,
                    style: AppTypography.sectionTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Price
                  if (pricePerNight != null)
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: '$currency$pricePerNight',
                            style: AppTypography.priceText.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text: ' / night',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(child: Icon(Icons.home, size: 48, color: Colors.grey[400]));
  }
}

/// Post Card for Community Feed per COMPONENT_LIBRARY.md
class PostCard extends StatelessWidget {
  final String id;
  final String username;
  final String? avatarUrl;
  final bool isVerified;
  final String? caption;
  final List<String> mediaUrls;
  final String? locationCity;
  final String? taggedEntityName;
  final String? taggedEntityType;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;
  final bool isSponsored;
  final String? sponsorName;
  final String? sponsorCta;
  final String timestamp;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onTaggedEntityTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onCtaTap;

  const PostCard({
    super.key,
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.caption,
    required this.mediaUrls,
    this.locationCity,
    this.taggedEntityName,
    this.taggedEntityType,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isSponsored = false,
    this.sponsorName,
    this.sponsorCta,
    required this.timestamp,
    this.onLike,
    this.onComment,
    this.onSave,
    this.onShare,
    this.onAvatarTap,
    this.onTaggedEntityTap,
    this.onLocationTap,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          // Media
          if (mediaUrls.isNotEmpty) _buildMedia(),

          // Actions bar
          _buildActionsBar(),

          // Tagged entity
          if (taggedEntityName != null) _buildTaggedEntity(context),

          // Caption
          if (caption != null && caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '$username ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: caption),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Sponsor CTA
          if (isSponsored && sponsorCta != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: onCtaTap,
                  child: Text(sponsorCta!),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Username + location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified, size: 14, color: AppColors.verified),
                    ],
                    if (isSponsored) ...[
                      const SizedBox(width: 8),
                      const SponsoredBadge(),
                    ],
                  ],
                ),
                if (locationCity != null)
                  GestureDetector(
                    onTap: onLocationTap,
                    child: Text(
                      locationCity!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),

          // Timestamp + More
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timestamp, style: AppTypography.caption),
              const Icon(Icons.more_horiz, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.grey[200],
      child: mediaUrls.length == 1
          ? Image.network(
              mediaUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildMediaPlaceholder(),
            )
          : PageView.builder(
              itemCount: mediaUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  mediaUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildMediaPlaceholder(),
                );
              },
            ),
    );
  }

  Widget _buildMediaPlaceholder() {
    return Center(child: Icon(Icons.image, size: 48, color: Colors.grey[400]));
  }

  Widget _buildActionsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Like
          _ActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : null,
            count: likeCount,
            onTap: onLike,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Comment
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            count: commentCount,
            onTap: onComment,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Share
          _ActionButton(icon: Icons.send_outlined, onTap: onShare),
          const Spacer(),

          // Save
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: onSave,
            color: isSaved ? AppColors.primary : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTaggedEntity(BuildContext context) {
    String icon = '📍';
    if (taggedEntityType == 'experience') icon = '🎯';
    if (taggedEntityType == 'stay') icon = '🏠';

    return GestureDetector(
      onTap: onTaggedEntityTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon),
            const SizedBox(width: 4),
            Text(
              taggedEntityName!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Action button for post interactions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final int? count;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, this.color, this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 4),
            Text(
              count! > 999
                  ? '${(count! / 1000).toStringAsFixed(1)}K'
                  : '$count',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

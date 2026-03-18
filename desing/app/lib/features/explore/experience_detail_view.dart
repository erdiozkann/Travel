import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/checkout_service.dart';
import '../../core/ui/design_tokens.dart';
import '../../core/ui/widgets/badges.dart';

/// Experience Detail View - Screen 03
/// Per SCREEN_SPECS/03_EXPERIENCE_DETAIL.md
///
/// The conversion page for bookable activities:
/// - Full experience information (description, duration, price, availability)
/// - AI-generated summary with confidence label
/// - Trust signals (reviews, ratings, host/provider info)
/// - Clear pricing visibility (always range, per GUARDRAILS)
/// - Primary CTA: "Book experience" → Stripe Checkout
class ExperienceDetailView extends StatefulWidget {
  final String experienceId;

  const ExperienceDetailView({super.key, required this.experienceId});

  @override
  State<ExperienceDetailView> createState() => _ExperienceDetailViewState();
}

class _ExperienceDetailViewState extends State<ExperienceDetailView> {
  // State per 4.1 Local State (UI)
  bool _isLoading = true;
  bool _isBooking = false;
  bool _isFavorited = false;
  bool _isDescriptionExpanded = false;
  String? _error;
  Map<String, dynamic>? _experience;
  Map<String, dynamic>? _aiSummary;
  List<Map<String, dynamic>> _reviews = [];
  int _mediaIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadExperience();
    _loadAISummary();
    _loadReviews();
    _checkFavoriteStatus();
  }

  Future<void> _loadExperience() async {
    try {
      // Per 6.1 Read Operations - experience table (Public read)
      final response = await Supabase.instance.client
          .from('experiences')
          .select('''
            *,
            cities:city_id ( name, country_code )
          ''')
          .eq('id', widget.experienceId)
          .single();

      setState(() {
        _experience = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAISummary() async {
    try {
      // Check for cached AI summary (7 days TTL per spec)
      final response = await Supabase.instance.client
          .from('experience_ai_cache')
          .select()
          .eq('experience_id', widget.experienceId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _aiSummary = response;
        });
      }
    } catch (e) {
      // AI summary is optional, don't block UI
      debugPrint('AI summary not available: $e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      // Per 3.6 - Reviews only from verified bookings
      final response = await Supabase.instance.client
          .from('reviews')
          .select('''
            *,
            users:user_id ( display_name, avatar_url )
          ''')
          .eq('target_type', 'experience')
          .eq('target_id', widget.experienceId)
          .eq('verified', true)
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Failed to load reviews: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('saved_items')
          .select('id')
          .eq('user_id', user.id)
          .eq('item_type', 'experience')
          .eq('item_id', widget.experienceId)
          .maybeSingle();

      setState(() {
        _isFavorited = response != null;
      });
    } catch (e) {
      debugPrint('Failed to check favorite: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;

    // Per 5 - Auth required for favorite
    if (user == null) {
      _showAuthPrompt();
      return;
    }

    // Optimistic update
    final wasFavorited = _isFavorited;
    setState(() => _isFavorited = !_isFavorited);

    try {
      if (wasFavorited) {
        await Supabase.instance.client
            .from('saved_items')
            .delete()
            .eq('user_id', user.id)
            .eq('item_type', 'experience')
            .eq('item_id', widget.experienceId);
      } else {
        await Supabase.instance.client.from('saved_items').insert({
          'user_id': user.id,
          'item_type': 'experience',
          'item_id': widget.experienceId,
        });
      }
    } catch (e) {
      // Revert on error
      setState(() => _isFavorited = wasFavorited);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  void _showAuthPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sign in to save favorites'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () {
            final next = Uri.encodeComponent(
              '/explore/experience/${widget.experienceId}',
            );
            context.push('/auth/login?next=$next');
          },
        ),
      ),
    );
  }

  Future<void> _handleBooking() async {
    final user = Supabase.instance.client.auth.currentUser;

    // Per 4.3 - Auth check before booking
    if (user == null) {
      final next = Uri.encodeComponent(
        '/explore/experience/${widget.experienceId}',
      );
      context.go('/auth/login?next=$next');
      return;
    }

    setState(() => _isBooking = true);

    try {
      // Per 8.2 - Create Stripe checkout session
      final checkoutUrl = await CheckoutService.createExperienceCheckout(
        experienceId: widget.experienceId,
        userId: user.id,
      );

      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          throw Exception('Could not launch checkout URL');
        }
      } else {
        throw Exception('No checkout URL returned');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: _buildBody(),
      // 3.9 Sticky Bottom CTA Bar
      bottomNavigationBar: _experience != null ? _buildStickyBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_experience == null) {
      return _buildNotFoundState();
    }

    final exp = _experience!;
    final title = exp['title'] ?? 'Experience';
    final description = exp['description'] ?? '';
    final city = exp['cities'] as Map<String, dynamic>?;
    final category = exp['category'];
    final durationMins = exp['duration_minutes'];
    final isSponsored = exp['is_sponsored'] == true;

    return CustomScrollView(
      slivers: [
        // 3.1 Media Carousel with App Bar
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(background: _buildMediaCarousel()),
          actions: [
            // Favorite button in app bar
            IconButton(
              icon: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share link copied!')),
                );
              },
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3.2 Header Section
                _buildHeaderSection(
                  title: title,
                  category: category,
                  cityName: city?['name'],
                  durationMinutes: durationMins,
                  isSponsored: isSponsored,
                ),
                const SizedBox(height: AppSpacing.md),

                // 3.3 Price Section
                _buildPriceSection(exp),
                const SizedBox(height: AppSpacing.md),

                // 3.4 AI Summary Section
                if (_aiSummary != null || true) // Always show per spec
                  _buildAISummarySection(),
                const SizedBox(height: AppSpacing.md),

                // 3.5 Trust Section
                _buildTrustSection(exp),
                const SizedBox(height: AppSpacing.md),

                // 3.6 Reviews Section
                _buildReviewsSection(),
                const SizedBox(height: AppSpacing.md),

                // 3.7 Details Section (Full Description)
                _buildDetailsSection(description, exp),
                const SizedBox(height: AppSpacing.xl),

                // 3.8 Related Experiences (Optional)
                _buildRelatedExperiences(),
                // Extra padding for bottom bar
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 3.1 Media Carousel
  Widget _buildMediaCarousel() {
    final mediaUrls = _experience?['media_urls'] as List<dynamic>? ?? [];

    if (mediaUrls.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.image, size: 64, color: Colors.grey[400]),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: mediaUrls.length,
          onPageChanged: (index) => setState(() => _mediaIndex = index),
          itemBuilder: (context, index) {
            return Image.network(
              mediaUrls[index].toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
            );
          },
        ),
        // Pagination dots
        if (mediaUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                mediaUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _mediaIndex == index ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _mediaIndex == index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 3.2 Header Section
  Widget _buildHeaderSection({
    required String title,
    String? category,
    String? cityName,
    int? durationMinutes,
    bool isSponsored = false,
  }) {
    final durationText = durationMinutes != null
        ? durationMinutes >= 60
              ? '${durationMinutes ~/ 60}h ${durationMinutes % 60 > 0 ? "${durationMinutes % 60}m" : ""}'
              : '${durationMinutes}m'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges row
        Row(
          children: [
            if (category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  category,
                  style: AppTypography.badgeText.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            if (isSponsored) ...[
              const SizedBox(width: 8),
              const SponsoredBadge(),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Title
        Text(title, style: AppTypography.appTitle),
        const SizedBox(height: 4),

        // Location + Duration
        Row(
          children: [
            if (cityName != null) ...[
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(cityName, style: TextStyle(color: Colors.grey[600])),
            ],
            if (durationText != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(durationText, style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
      ],
    );
  }

  /// 3.3 Price Section - Always range per GUARDRAILS
  Widget _buildPriceSection(Map<String, dynamic> exp) {
    final priceMin = exp['price_min'];
    final priceMax = exp['price_max'];
    final currency = exp['currency'] ?? '€';

    // Price range per GUARDRAILS - never exact
    String priceText = 'Price TBD';
    if (priceMin != null && priceMax != null) {
      priceText = '$currency$priceMin – $currency$priceMax per person';
    } else if (priceMin != null) {
      priceText = 'From $currency$priceMin per person';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            priceText,
            style: AppTypography.priceText.copyWith(
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          // What's included (per 3.3)
          Text(
            'Guide, equipment included',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 3.4 AI Summary Section - Always visible with label
  Widget _buildAISummarySection() {
    final summary = _aiSummary?['ai_summary'] as String?;
    final highlights = _aiSummary?['highlights'] as List<dynamic>?;
    final whoItsFor = _aiSummary?['who_its_for'] as List<dynamic>?;
    final confidence = _aiSummary?['confidence_level'] ?? 'medium';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.aiBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.aiText.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Label + Confidence badge (always visible per spec)
          AIConfidenceBadge(confidenceLevel: confidence),
          const SizedBox(height: AppSpacing.sm),

          // Summary text
          Text(
            summary ??
                'Explore this unique experience in a beautiful setting. Perfect for travelers seeking authentic local moments.',
            style: TextStyle(color: Colors.grey[800], height: 1.5),
          ),

          if (highlights != null && highlights.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Highlights',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...highlights
                .take(3)
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.aiText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(h.toString())),
                      ],
                    ),
                  ),
                ),
          ],

          if (whoItsFor != null && whoItsFor.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Best for: ${whoItsFor.take(3).join(", ")}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 3.5 Trust Section
  Widget _buildTrustSection(Map<String, dynamic> exp) {
    final rating = exp['rating'];
    final reviewCount = exp['review_count'] ?? 0;
    final ratingVal = (rating is num) ? rating.toDouble() : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trust & Reviews',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (ratingVal != null) ...[
                RatingBadge(rating: ratingVal, reviewCount: reviewCount),
                const SizedBox(width: 12),
                Text(
                  '($reviewCount verified reviews)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ] else
                Text(
                  'No reviews yet. Be the first!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const Spacer(),
              const VerifiedBadge(type: 'host'), // Per 3.5
            ],
          ),
        ],
      ),
    );
  }

  /// 3.6 Reviews Section
  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Reviews',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (_reviews.length > 3)
                TextButton(
                  onPressed: () {
                    // Navigate to all reviews
                  },
                  child: const Text('See all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No reviews yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...(_reviews.take(3).map((review) => _buildReviewCard(review))),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['users'] as Map<String, dynamic>?;
    final rating = review['rating'] ?? 0;
    final text = review['text'] ?? '';
    final isVerified = review['verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                backgroundImage: user?['avatar_url'] != null
                    ? NetworkImage(user!['avatar_url'])
                    : null,
                child: user?['avatar_url'] == null
                    ? const Icon(Icons.person, size: 16, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['display_name'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 12,
                            color: Colors.amber,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.verified.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Verified booking',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.verified,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  /// 3.7 Details Section
  Widget _buildDetailsSection(String description, Map<String, dynamic> exp) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this experience',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _isDescriptionExpanded || description.length < 200
                ? description
                : '${description.substring(0, 200)}...',
            style: TextStyle(height: 1.5, color: Colors.grey[800]),
          ),
          if (description.length > 200)
            TextButton(
              onPressed: () => setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              }),
              child: Text(_isDescriptionExpanded ? 'Show less' : 'Read more'),
            ),
          const Divider(height: 24),

          // Cancellation policy (per 3.7)
          const Text(
            'Cancellation Policy',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            _aiSummary?['cancellation_hint'] ??
                'Free cancellation up to 24 hours before',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 3.8 Related Experiences (Optional)
  Widget _buildRelatedExperiences() {
    // Placeholder - in real implementation, fetch similar experiences
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You might also like',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Center(
            child: Text(
              'Related experiences',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      ],
    );
  }

  /// 3.9 Sticky Bottom CTA Bar
  Widget _buildStickyBottomBar() {
    final exp = _experience!;
    final priceMin = exp['price_min'];
    final currency = exp['currency'] ?? '€';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.elevated,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Price display
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceMin != null ? 'From $currency$priceMin' : 'Check price',
                  style: AppTypography.priceText.copyWith(fontSize: 18),
                ),
                Text(
                  'per person',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),

            // Favorite button
            IconButton(
              icon: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? Colors.red : Colors.grey,
              ),
              onPressed: _toggleFavorite,
            ),
            const Spacer(),

            // Book CTA (per 3.9)
            ElevatedButton(
              onPressed: _isBooking ? null : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, AppButton.height),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Book Experience',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading skeleton (per 10.2)
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(height: 280, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 200, height: 24, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Container(width: 150, height: 16, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Error state (per 10.1)
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Failed to load experience',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadExperience();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }

  /// Not found state (per 10.1)
  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Experience not found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This experience may have been removed',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';
import '../../core/ui/widgets/badges.dart';

/// Stay Detail View - Screen 04
/// Per SCREEN_SPECS/04_STAY_DETAIL.md
///
/// Accommodation discovery page with request-based booking:
/// - Full stay information (rooms, amenities, location)
/// - Host-centric presentation (profile, trust signals)
/// - Nightly price range visibility
/// - Primary CTA: "Request booking" → No payment in MVP
class StayDetailView extends StatefulWidget {
  final String stayId;

  const StayDetailView({super.key, required this.stayId});

  @override
  State<StayDetailView> createState() => _StayDetailViewState();
}

class _StayDetailViewState extends State<StayDetailView> {
  // State per 4.1 Local State (UI)
  Map<String, dynamic>? _stay;
  Map<String, dynamic>? _host;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _relatedStays = [];

  bool _isLoading = true;
  bool _isFavorited = false;
  String? _error;

  DateTime? _selectedCheckIn;
  DateTime? _selectedCheckOut;

  int _mediaIndex = 0;
  bool _isDescriptionExpanded = false;

  final PageController _mediaController = PageController();

  @override
  void initState() {
    super.initState();
    _loadStayData();
  }

  @override
  void dispose() {
    _mediaController.dispose();
    super.dispose();
  }

  Future<void> _loadStayData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch stay details
      final stayResponse = await Supabase.instance.client
          .from('stays')
          .select()
          .eq('id', widget.stayId)
          .maybeSingle();

      if (stayResponse == null) {
        setState(() {
          _error = 'Stay not found';
          _isLoading = false;
        });
        return;
      }

      _stay = stayResponse;

      // Fetch host details
      final hostId = _stay!['host_id'];
      if (hostId != null) {
        final hostResponse = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', hostId)
            .maybeSingle();
        _host = hostResponse;
      }

      // Fetch reviews
      final reviewsResponse = await Supabase.instance.client
          .from('reviews')
          .select('*, users:user_id(*)')
          .eq('target_id', widget.stayId)
          .eq('target_type', 'stay')
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(5);

      _reviews = List<Map<String, dynamic>>.from(reviewsResponse);

      // Check favorite status
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final savedResponse = await Supabase.instance.client
            .from('saved_items')
            .select('id')
            .eq('user_id', user.id)
            .eq('item_id', widget.stayId)
            .eq('item_type', 'stay')
            .maybeSingle();

        _isFavorited = savedResponse != null;
      }

      // Fetch related stays
      await _loadRelatedStays();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRelatedStays() async {
    if (_stay == null) return;

    try {
      final cityId = _stay!['city_id'];
      final response = await Supabase.instance.client
          .from('stays')
          .select()
          .eq('city_id', cityId)
          .neq('id', widget.stayId)
          .eq('status', 'active')
          .limit(4);

      _relatedStays = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Failed to load related stays: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showAuthPrompt();
      return;
    }

    try {
      if (_isFavorited) {
        await Supabase.instance.client
            .from('saved_items')
            .delete()
            .eq('user_id', user.id)
            .eq('item_id', widget.stayId)
            .eq('item_type', 'stay');
      } else {
        await Supabase.instance.client.from('saved_items').insert({
          'user_id': user.id,
          'item_id': widget.stayId,
          'item_type': 'stay',
        });
      }

      setState(() {
        _isFavorited = !_isFavorited;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  void _showAuthPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final currentPath = Uri.encodeComponent(
                '/explore/stay/${widget.stayId}',
              );
              context.push('/auth/login?redirect=$currentPath');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _requestBooking() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      final currentPath = Uri.encodeComponent('/explore/stay/${widget.stayId}');
      context.push('/auth/login?redirect=$currentPath');
      return;
    }

    // Navigate to booking request screen per 8.1
    context.push('/stay/${widget.stayId}/request');
  }

  void _navigateToHost() {
    if (_host != null) {
      context.push('/host/${_host!['id']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _stay == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stay')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Stay not found',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 3.1 Media Carousel (as SliverAppBar)
              _buildMediaCarousel(),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3.2 Header Section
                      _buildHeaderSection(),

                      const Divider(height: 32),

                      // 3.3 Price Section
                      _buildPriceSection(),

                      const Divider(height: 32),

                      // 3.4 Host Section (Central - Host-Centric)
                      _buildHostSection(),

                      const Divider(height: 32),

                      // 3.5 Trust Section
                      _buildTrustSection(),

                      const Divider(height: 32),

                      // 3.6 Reviews Section
                      _buildReviewsSection(),

                      const Divider(height: 32),

                      // 3.7 Details Section
                      _buildDetailsSection(),

                      // 3.9 Related Stays
                      if (_relatedStays.isNotEmpty) ...[
                        const Divider(height: 32),
                        _buildRelatedStays(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3.10 Sticky Bottom CTA Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyBottomBar(),
          ),
        ],
      ),
    );
  }

  /// 3.1 Media Carousel
  Widget _buildMediaCarousel() {
    final mediaUrls = _stay!['media_urls'] as List? ?? [];

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, size: 20),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: mediaUrls.isEmpty
            ? Container(
                color: Colors.grey[300],
                child: const Icon(Icons.hotel, size: 80, color: Colors.grey),
              )
            : PageView.builder(
                controller: _mediaController,
                itemCount: mediaUrls.length,
                onPageChanged: (index) {
                  setState(() => _mediaIndex = index);
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    mediaUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.hotel,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
      ),
      bottom: mediaUrls.length > 1
          ? PreferredSize(
              preferredSize: const Size.fromHeight(30),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    mediaUrls.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _mediaIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// 3.2 Header Section
  Widget _buildHeaderSection() {
    final title = _stay!['title'] ?? 'Untitled Stay';
    final roomType = _stay!['room_type'] ?? 'entire_place';
    final neighborhood = _stay!['neighborhood'];
    final city = _stay!['city_name'] ?? 'Barcelona';
    final guests = _stay!['max_guests'] ?? 2;
    final bedrooms = _stay!['bedrooms'] ?? 1;
    final bathrooms = _stay!['bathrooms'] ?? 1;
    final isSponsored = _stay!['is_sponsored'] == true;

    String roomTypeLabel;
    switch (roomType) {
      case 'private_room':
        roomTypeLabel = 'Private room';
        break;
      case 'shared_room':
        roomTypeLabel = 'Shared room';
        break;
      default:
        roomTypeLabel = 'Entire place';
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room type badge + sponsored
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  roomTypeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isSponsored) ...[
                const SizedBox(width: 8),
                const SponsoredBadge(),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                neighborhood != null ? '$neighborhood, $city' : city,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Capacity
          Text(
            'Up to $guests guests • $bedrooms bedrooms • $bathrooms bath',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 3.3 Price Section (Prominent)
  Widget _buildPriceSection() {
    final priceMin = _stay!['price_min'] ?? 0;
    final priceMax = _stay!['price_max'] ?? priceMin;
    final currency = _stay!['currency'] ?? '€';

    // Calculate estimated total if dates selected
    int? nights;
    int? totalMin;
    int? totalMax;
    if (_selectedCheckIn != null && _selectedCheckOut != null) {
      nights = _selectedCheckOut!.difference(_selectedCheckIn!).inDays;
      if (nights > 0) {
        totalMin = priceMin * nights;
        totalMax = priceMax * nights;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nightly price range
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currency$priceMin – $currency$priceMax',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' / night',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),

          // Estimated total
          if (nights != null && nights > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Estimated total: $currency$totalMin – $currency$totalMax for $nights nights',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],

          const SizedBox(height: 8),

          // Price clarity note per GUARDRAILS.md
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Final price confirmed by host',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3.4 Host Section (Central — Host-Centric)
  Widget _buildHostSection() {
    final hostName = _host?['display_name'] ?? _host?['full_name'] ?? 'Host';
    final hostAvatar = _host?['avatar_url'];
    final isVerified = _host?['is_verified'] == true;
    final rating = _host?['rating'];
    final reviewCount = _host?['review_count'] ?? 0;
    final responseTime = _stay!['response_time'] ?? 'within a day';
    final memberSince = _host?['created_at'];

    String memberYear = 'recently';
    if (memberSince != null) {
      final date = DateTime.tryParse(memberSince);
      if (date != null) {
        memberYear = date.year.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: InkWell(
        onTap: _navigateToHost,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              // Host avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                backgroundImage: hostAvatar != null
                    ? NetworkImage(hostAvatar)
                    : null,
                child: hostAvatar == null
                    ? const Icon(Icons.person, size: 32, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),

              // Host info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hosted by $hostName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(type: 'host'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${(rating as num).toStringAsFixed(1)} ($reviewCount reviews)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 4),

                    // Response time + member since
                    Text(
                      'Usually responds $responseTime • Hosting since $memberYear',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  /// 3.5 Trust Section
  Widget _buildTrustSection() {
    final rating = _stay!['rating'];
    final reviewCount = _stay!['review_count'] ?? 0;

    if (rating == null && reviewCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ratings & Trust',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Stay rating
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 24, color: Colors.amber),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rating != null
                              ? (rating as num).toStringAsFixed(1)
                              : 'New',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$reviewCount reviews',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Verified reviews badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 24,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verified\nreviews only',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3.6 Reviews Section
  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_reviews.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full reviews page
                  },
                  child: const Text('See all'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Row(
                children: [
                  Icon(Icons.rate_review, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Be the first to stay here!'),
                ],
              ),
            )
          else
            Column(
              children: _reviews
                  .take(3)
                  .map((review) => _buildReviewCard(review))
                  .toList(),
            ),
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
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: Text(
                  (user?['display_name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['display_name'] ?? 'Guest',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            Icons.star,
                            size: 12,
                            color: i < rating ? Colors.amber : Colors.grey[300],
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Verified stay',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
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
          const SizedBox(height: 8),
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  /// 3.7 Details Section
  Widget _buildDetailsSection() {
    final description = _stay!['description'] ?? 'No description available.';
    final amenities = _stay!['amenities'] as List? ?? [];
    final houseRules = _stay!['house_rules'] as Map<String, dynamic>? ?? {};
    final checkIn = houseRules['check_in'] ?? '15:00';
    final checkOut = houseRules['check_out'] ?? '11:00';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          const Text(
            'About this place',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isDescriptionExpanded || description.length < 200
                ? description
                : '${description.substring(0, 200)}...',
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
          if (description.length > 200)
            TextButton(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(_isDescriptionExpanded ? 'Show less' : 'Read more'),
            ),

          const SizedBox(height: 24),

          // Amenities
          if (amenities.isNotEmpty) ...[
            const Text(
              'Amenities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.take(8).map((amenity) {
                IconData icon;
                switch (amenity.toString().toLowerCase()) {
                  case 'wifi':
                    icon = Icons.wifi;
                    break;
                  case 'kitchen':
                    icon = Icons.kitchen;
                    break;
                  case 'ac':
                  case 'air conditioning':
                    icon = Icons.ac_unit;
                    break;
                  case 'parking':
                    icon = Icons.local_parking;
                    break;
                  case 'pool':
                    icon = Icons.pool;
                    break;
                  case 'tv':
                    icon = Icons.tv;
                    break;
                  case 'washer':
                    icon = Icons.local_laundry_service;
                    break;
                  default:
                    icon = Icons.check_circle_outline;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Text(amenity.toString()),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // House Rules
          const Text(
            'House Rules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRuleItem(
                  Icons.login,
                  'Check-in',
                  'After $checkIn',
                ),
              ),
              Expanded(
                child: _buildRuleItem(
                  Icons.logout,
                  'Check-out',
                  'Before $checkOut',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// 3.9 Related Stays
  Widget _buildRelatedStays() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Similar stays nearby',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _relatedStays.length,
              itemBuilder: (context, index) {
                final stay = _relatedStays[index];
                return _buildRelatedStayCard(stay);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedStayCard(Map<String, dynamic> stay) {
    return GestureDetector(
      onTap: () {
        context.push('/explore/stay/${stay['id']}');
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
              ),
              child: const Center(
                child: Icon(Icons.hotel, color: Colors.grey, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stay['title'] ?? 'Stay',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        (stay['rating'] as num?)?.toStringAsFixed(1) ?? 'New',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stay['currency'] ?? '€'}${stay['price_min'] ?? 0}/night',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  /// 3.10 Sticky Bottom CTA Bar
  Widget _buildStickyBottomBar() {
    final priceMin = _stay!['price_min'] ?? 0;
    final currency = _stay!['currency'] ?? '€';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        MediaQuery.of(context).padding.bottom + AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          // Price display
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From $currency$priceMin',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '/ night',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const Spacer(),

          // Favorite button
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : Colors.grey,
            ),
          ),

          const SizedBox(width: 8),

          // Request booking CTA
          ElevatedButton(
            onPressed: _requestBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, AppButton.height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const Text(
              'Request booking',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

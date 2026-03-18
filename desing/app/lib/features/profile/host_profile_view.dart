import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';
import '../../core/ui/widgets/badges.dart';

/// Host Profile View - Screen 10 (Public View)
/// Per SCREEN_SPECS/10_HOST_PROFILE_TRUST_CENTER.md
///
/// Guest-facing profile showing:
/// - Host info and trust signals
/// - Performance stats (response time, rating)
/// - Listings overview
/// - Report host action
class HostProfileView extends StatefulWidget {
  final String hostId;

  const HostProfileView({super.key, required this.hostId});

  @override
  State<HostProfileView> createState() => _HostProfileViewState();
}

class _HostProfileViewState extends State<HostProfileView> {
  // State per 5.1 Local State (UI)
  Map<String, dynamic>? _host;

  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _reviews = [];

  bool _isLoading = true;
  bool _isOwnProfile = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHostData();
  }

  Future<void> _loadHostData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if current user is viewing own host profile
      final currentUser = Supabase.instance.client.auth.currentUser;
      _isOwnProfile = currentUser?.id == widget.hostId;

      // Fetch host data
      final hostResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', widget.hostId)
          .maybeSingle();

      if (hostResponse == null) {
        setState(() {
          _error = 'Host not found';
          _isLoading = false;
        });
        return;
      }

      _host = hostResponse;

      // Fetch active listings (stays)
      final listingsResponse = await Supabase.instance.client
          .from('stays')
          .select()
          .eq('host_id', widget.hostId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      _listings = List<Map<String, dynamic>>.from(listingsResponse);

      // Fetch reviews for this host
      final reviewsResponse = await Supabase.instance.client
          .from('reviews')
          .select('*, users:user_id(*)')
          .eq('target_id', widget.hostId)
          .eq('target_type', 'host')
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(5);

      _reviews = List<Map<String, dynamic>>.from(reviewsResponse);

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

  Future<void> _reportHost() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showAuthPrompt();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ReportHostDialog(
        hostId: widget.hostId,
        hostName: _host?['display_name'] ?? _host?['full_name'] ?? 'Host',
      ),
    );
  }

  void _showAuthPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in to report this host.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final currentPath = Uri.encodeComponent('/host/${widget.hostId}');
              context.push('/auth/login?redirect=$currentPath');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Host Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _host == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Host Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Host not found',
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
      body: RefreshIndicator(
        onRefresh: _loadHostData,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface,
              title: const Text('Host Profile'),
              actions: [
                if (_isOwnProfile)
                  TextButton(
                    onPressed: () => context.push('/host/trust'),
                    child: const Text('Trust Center'),
                  ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3.1 Profile Header
                  _buildProfileHeader(),

                  const Divider(height: 32),

                  // 3.2 Trust Signals Section
                  _buildTrustSignals(),

                  const Divider(height: 32),

                  // 3.3 About Section
                  _buildAboutSection(),

                  const Divider(height: 32),

                  // 3.4 Listings Section
                  _buildListingsSection(),

                  const Divider(height: 32),

                  // 3.5 Reviews Section
                  _buildReviewsSection(),

                  // 3.6 Report Section
                  if (!_isOwnProfile) ...[
                    const Divider(height: 32),
                    _buildReportSection(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3.1 Profile Header
  Widget _buildProfileHeader() {
    final displayName = _host!['display_name'] ?? _host!['full_name'] ?? 'Host';
    final avatarUrl = _host!['avatar_url'];
    final isVerified = _host!['is_verified'] == true;
    final createdAt = _host!['created_at'];
    final city = _host!['city'] ?? _host!['location'];
    final languages = _host!['languages'] as List? ?? [];

    String memberSince = 'recently';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        memberSince = date.year.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // Name + Verified badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                const VerifiedBadge(type: 'host'),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Hosting since
          Text(
            'Hosting since $memberSince',
            style: TextStyle(color: Colors.grey[600]),
          ),

          // Location
          if (city != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(city, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],

          // Languages
          if (languages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: languages.map<Widget>((lang) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    lang.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 3.2 Trust Signals Section
  Widget _buildTrustSignals() {
    final rating = _host!['rating'];
    final reviewCount = _host!['review_count'] ?? 0;
    final responseTime = _host!['response_time'] ?? 'within a day';
    final responseRate = _host!['response_rate'] ?? 100;
    final acceptanceRate = _host!['acceptance_rate'] ?? 85;
    final totalStays = _host!['completed_stays'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trust Signals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Stats grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Rating
              _buildStatCard(
                icon: Icons.star,
                iconColor: Colors.amber,
                value: rating != null
                    ? (rating as num).toStringAsFixed(1)
                    : 'New',
                label: '$reviewCount reviews',
              ),

              // Response time
              _buildStatCard(
                icon: Icons.schedule,
                iconColor: Colors.blue,
                value: responseTime,
                label: 'Response time',
              ),

              // Response rate
              _buildStatCard(
                icon: Icons.reply,
                iconColor: Colors.green,
                value: '$responseRate%',
                label: 'Response rate',
              ),

              // Acceptance rate
              _buildStatCard(
                icon: Icons.check_circle,
                iconColor: Colors.purple,
                value: '$acceptanceRate%',
                label: 'Acceptance rate',
              ),

              // Total stays
              if (totalStays > 0)
                _buildStatCard(
                  icon: Icons.hotel,
                  iconColor: Colors.orange,
                  value: '$totalStays+',
                  label: 'Completed stays',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3.3 About Section
  Widget _buildAboutSection() {
    final bio = _host!['bio'];
    final interests = _host!['interests'] as List? ?? [];

    if (bio == null && interests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (bio != null)
            Text(bio, style: TextStyle(color: Colors.grey[700], height: 1.5)),

          if (interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Interests',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map<Widget>((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    interest.toString(),
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 3.4 Listings Section
  Widget _buildListingsSection() {
    final displayName = _host!['display_name'] ?? _host!['full_name'] ?? 'Host';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$displayName's listings",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_listings.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hotel_outlined, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('No active listings'),
                ],
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _listings.length,
                itemBuilder: (context, index) {
                  final stay = _listings[index];
                  return _buildListingCard(stay);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> stay) {
    final title = stay['title'] ?? 'Stay';
    final priceMin = stay['price_min'] ?? 0;
    final currency = stay['currency'] ?? '€';
    final rating = stay['rating'];
    final mediaUrls = stay['media_urls'] as List? ?? [];

    return GestureDetector(
      onTap: () => context.push('/explore/stay/${stay['id']}'),
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
            // Thumbnail
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
                image: mediaUrls.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(mediaUrls.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: mediaUrls.isEmpty
                  ? const Center(
                      child: Icon(Icons.hotel, color: Colors.grey, size: 40),
                    )
                  : null,
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          (rating as num).toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '$currency$priceMin/night',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3.5 Reviews Section
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
                'Reviews from guests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_reviews.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full reviews list
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
                  Icon(Icons.rate_review_outlined, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('No reviews yet'),
                ],
              ),
            )
          else
            Column(
              children: _reviews
                  .map((review) => _buildReviewCard(review))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['users'] as Map<String, dynamic>?;
    final userName = user?['display_name'] ?? user?['full_name'] ?? 'Guest';
    final rating = review['rating'] ?? 0;
    final text = review['text'] ?? '';
    final createdAt = review['created_at'];

    String dateStr = '';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        dateStr = '${date.month}/${date.year}';
      }
    }

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
                  userName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
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
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
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

  /// 3.6 Report Section
  Widget _buildReportSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: OutlinedButton.icon(
        onPressed: _reportHost,
        icon: const Icon(Icons.flag_outlined, color: Colors.red),
        label: const Text(
          'Report this host',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, AppButton.height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }
}

/// Report Host Dialog
class _ReportHostDialog extends StatefulWidget {
  final String hostId;
  final String hostName;

  const _ReportHostDialog({required this.hostId, required this.hostName});

  @override
  State<_ReportHostDialog> createState() => _ReportHostDialogState();
}

class _ReportHostDialogState extends State<_ReportHostDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Inappropriate behavior',
    'Fraudulent listing',
    'False information',
    'Safety concerns',
    'Harassment',
    'Other',
  ];

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('reports').insert({
        'reporter_id': user.id,
        'target_id': widget.hostId,
        'target_type': 'host',
        'reason': _selectedReason,
        'details': _detailsController.text,
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report submitted. Thank you for helping keep our community safe.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.hostName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this host?'),
            const SizedBox(height: 12),
            ...(_reasons.map((reason) {
              return RadioListTile<String>(
                value: reason,
                // ignore: deprecated_member_use
                groupValue: _selectedReason,
                title: Text(reason),
                // ignore: deprecated_member_use
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
              );
            })),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Additional details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason != null && !_isSubmitting
              ? _submitReport
              : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}

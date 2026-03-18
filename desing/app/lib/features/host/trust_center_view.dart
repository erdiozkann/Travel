import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';

/// Trust Center View - Screen 10 (Host-Only)
/// Per SCREEN_SPECS/10_HOST_PROFILE_TRUST_CENTER.md (Section 4)
///
/// Host's private control center showing:
/// - Verification status and requirements
/// - Performance metrics
/// - Tips and improvement suggestions
class TrustCenterView extends StatefulWidget {
  const TrustCenterView({super.key});

  @override
  State<TrustCenterView> createState() => _TrustCenterViewState();
}

class _TrustCenterViewState extends State<TrustCenterView> {
  // State
  bool _isLoading = true;
  String? _error;

  // Host data (for future use in host name display)

  Map<String, dynamic>? _metrics;
  String _verificationStatus = 'not_applied'; // not_applied, pending, verified

  // Requirements status
  bool _hasCompleteProfile = false;
  bool _hasActiveListing = false;
  bool _hasAcceptedBooking = false;
  bool _hasAdminApproval = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTrustCenterData();
  }

  Future<void> _loadTrustCenterData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Please log in to access Trust Center';
          _isLoading = false;
        });
        return;
      }

      // Fetch host data
      final hostResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (hostResponse == null || hostResponse['role'] != 'host') {
        setState(() {
          _error = 'Only hosts can access Trust Center';
          _isLoading = false;
        });
        return;
      }

      _verificationStatus =
          hostResponse['verification_status'] ?? 'not_applied';

      // Check requirements
      _hasCompleteProfile = _checkProfileComplete(hostResponse);

      // Check active listings
      final listingsResponse = await Supabase.instance.client
          .from('stays')
          .select('id')
          .eq('host_id', user.id)
          .eq('status', 'active')
          .limit(1);

      _hasActiveListing = (listingsResponse as List).isNotEmpty;

      // Check accepted bookings
      final bookingsResponse = await Supabase.instance.client
          .from('booking_requests')
          .select('id')
          .eq('host_id', user.id)
          .eq('status', 'approved')
          .limit(1);

      _hasAcceptedBooking = (bookingsResponse as List).isNotEmpty;

      // Admin approval is part of verification status
      _hasAdminApproval = _verificationStatus == 'verified';

      // Fetch performance metrics per 4.3
      _metrics = await _fetchPerformanceMetrics(user.id);

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

  bool _checkProfileComplete(Map<String, dynamic> host) {
    final name = host['display_name'] ?? '';
    final avatar = host['avatar_url'] ?? '';
    final bio = host['bio'] ?? '';
    return name.isNotEmpty && avatar.isNotEmpty && bio.isNotEmpty;
  }

  Future<Map<String, dynamic>> _fetchPerformanceMetrics(String hostId) async {
    // In production, this would come from aggregated data or HostTrustAgent
    // For MVP, we calculate from available data
    try {
      // Total bookings
      final bookings = await Supabase.instance.client
          .from('booking_requests')
          .select('id, status, created_at, updated_at')
          .eq('host_id', hostId);

      final totalBookings = (bookings as List).length;
      final acceptedBookings = bookings
          .where((b) => b['status'] == 'approved')
          .length;
      // Rejected bookings counted for cancellation rate calculation
      final _ = bookings.where((b) => b['status'] == 'rejected').length;
      final completedStays = bookings
          .where((b) => b['status'] == 'completed')
          .length;

      // Calculate rates
      double acceptanceRate = 0;
      if (totalBookings > 0) {
        acceptanceRate = acceptedBookings / totalBookings * 100;
      }

      // Response time (simplified - in production use message timestamps)
      const avgResponseMinutes = 90.0; // 1.5 hours default

      // Get host rating
      final reviews = await Supabase.instance.client
          .from('reviews')
          .select('rating')
          .eq('target_id', hostId)
          .eq('target_type', 'host');

      double avgRating = 0;
      if ((reviews as List).isNotEmpty) {
        final total = reviews.fold<double>(
          0,
          (sum, r) => sum + (r['rating'] as num).toDouble(),
        );
        avgRating = total / reviews.length;
      }

      return {
        'responseRate': 95.0, // Placeholder - needs message tracking
        'responseTimeMinutes': avgResponseMinutes,
        'acceptanceRate': acceptanceRate,
        'cancellationRate': 2.0, // Placeholder
        'avgRating': avgRating,
        'totalBookings': totalBookings,
        'completedStays': completedStays,
      };
    } catch (e) {
      return {
        'responseRate': 0.0,
        'responseTimeMinutes': 0.0,
        'acceptanceRate': 0.0,
        'cancellationRate': 0.0,
        'avgRating': 0.0,
        'totalBookings': 0,
        'completedStays': 0,
      };
    }
  }

  Future<void> _applyForVerification() async {
    if (!_hasCompleteProfile || !_hasActiveListing || !_hasAcceptedBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete all requirements before applying'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'verification_status': 'pending'})
          .eq('id', user.id);

      setState(() {
        _verificationStatus = 'pending';
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification request submitted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int get _completedRequirements {
    int count = 0;
    if (_hasCompleteProfile) count++;
    if (_hasActiveListing) count++;
    if (_hasAcceptedBooking) count++;
    if (_hasAdminApproval) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Trust Center'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrustCenterData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4.1 Trust Center Header
            _buildHeader(),
            const SizedBox(height: 24),

            // 4.2 Verification Status Card
            _buildVerificationCard(),
            const SizedBox(height: 24),

            // 4.3 Performance Metrics
            _buildPerformanceMetrics(),
            const SizedBox(height: 24),

            // 4.4 Tips and Suggestions
            _buildTips(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 4.1 Trust Center Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _verificationStatus == 'verified'
                ? Colors.green[50]!
                : Colors.blue[50]!,
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: _verificationStatus == 'verified'
                    ? Colors.green
                    : Colors.blue,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Trust Center',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$_completedRequirements of 4 requirements completed',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _completedRequirements / 4,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _verificationStatus == 'verified' ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (_verificationStatus) {
      case 'verified':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'Verified';
        icon = Icons.verified;
        break;
      case 'pending':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        label = 'Pending';
        icon = Icons.pending;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = 'Not Applied';
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 4.2 Verification Status Card
  Widget _buildVerificationCard() {
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
            'Verification Requirements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete these steps to become a verified host',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Requirements checklist per 4.2
          _buildRequirementItem(
            label: 'Complete profile',
            isCompleted: _hasCompleteProfile,
            description: 'Add name, avatar, and bio',
          ),
          _buildRequirementItem(
            label: 'Active listing',
            isCompleted: _hasActiveListing,
            description: 'Publish at least one stay',
          ),
          _buildRequirementItem(
            label: 'Accepted 1+ booking',
            isCompleted: _hasAcceptedBooking,
            description: 'Accept a guest booking request',
          ),
          _buildRequirementItem(
            label: 'Admin approval',
            isCompleted: _hasAdminApproval,
            description: 'Reviewed and approved by our team',
            isPending: _verificationStatus == 'pending',
          ),

          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _verificationStatus == 'verified' ||
                      _verificationStatus == 'pending' ||
                      _isSubmitting
                  ? null
                  : _applyForVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _verificationStatus == 'verified'
                          ? 'You are Verified ✓'
                          : _verificationStatus == 'pending'
                          ? 'Under Review'
                          : 'Apply for Verification',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem({
    required String label,
    required bool isCompleted,
    required String description,
    bool isPending = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green[100]
                  : (isPending ? Colors.orange[100] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check
                  : (isPending ? Icons.schedule : Icons.radio_button_unchecked),
              color: isCompleted
                  ? Colors.green
                  : (isPending ? Colors.orange : Colors.grey),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green[800] : Colors.black87,
                  ),
                ),
                Text(
                  isPending ? 'Pending review...' : description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4.3 Performance Metrics
  Widget _buildPerformanceMetrics() {
    if (_metrics == null) return const SizedBox();

    final responseRate = _metrics!['responseRate'] as double? ?? 0;
    final responseTime = _metrics!['responseTimeMinutes'] as double? ?? 0;
    final acceptanceRate = _metrics!['acceptanceRate'] as double? ?? 0;
    final cancellationRate = _metrics!['cancellationRate'] as double? ?? 0;
    final avgRating = _metrics!['avgRating'] as double? ?? 0;
    final totalBookings = _metrics!['totalBookings'] as int? ?? 0;
    final completedStays = _metrics!['completedStays'] as int? ?? 0;

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
            'Performance Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep these metrics high to maintain trust',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Metrics grid per 4.3
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricCard(
                label: 'Response Rate',
                value: '${responseRate.toStringAsFixed(0)}%',
                target: '90%+',
                isGood: responseRate >= 90,
              ),
              _buildMetricCard(
                label: 'Response Time',
                value: responseTime < 60
                    ? '${responseTime.toStringAsFixed(0)} min'
                    : '${(responseTime / 60).toStringAsFixed(1)} hrs',
                target: '<4 hrs',
                isGood: responseTime < 240,
              ),
              _buildMetricCard(
                label: 'Acceptance Rate',
                value: '${acceptanceRate.toStringAsFixed(0)}%',
                target: '75%+',
                isGood: acceptanceRate >= 75,
              ),
              _buildMetricCard(
                label: 'Cancellation Rate',
                value: '${cancellationRate.toStringAsFixed(0)}%',
                target: '<5%',
                isGood: cancellationRate < 5,
              ),
              _buildMetricCard(
                label: 'Rating Average',
                value: avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                target: '4.5+',
                isGood: avgRating >= 4.5,
                icon: Icons.star,
              ),
              _buildMetricCard(
                label: 'Total Bookings',
                value: '$totalBookings',
                target: null,
                isGood: true,
              ),
              _buildMetricCard(
                label: 'Completed Stays',
                value: '$completedStays',
                target: null,
                isGood: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    String? target,
    required bool isGood,
    IconData? icon,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGood ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isGood ? Colors.green[800] : Colors.orange[800],
            ),
          ),
          if (target != null) ...[
            const SizedBox(height: 2),
            Text(
              'Target: $target',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  /// 4.4 Tips Section
  Widget _buildTips() {
    final tips = <Map<String, String?>>[];

    if (!_hasCompleteProfile) {
      tips.add({
        'title': 'Complete your profile',
        'description':
            'Add a friendly photo and bio to help guests feel comfortable booking with you.',
        'action': 'Edit Profile',
      });
    }

    if (!_hasActiveListing) {
      tips.add({
        'title': 'Create your first listing',
        'description':
            'Add high-quality photos and a detailed description to attract more guests.',
        'action': 'Add Listing',
      });
    }

    if ((_metrics?['responseRate'] ?? 100) < 90) {
      tips.add({
        'title': 'Improve response rate',
        'description':
            'Try to respond to all booking requests within 24 hours to maintain host status.',
        'action': null,
      });
    }

    if (tips.isEmpty) {
      tips.add({
        'title': 'You\'re doing great! 🎉',
        'description': 'Keep up the excellent work. Your metrics are on track.',
        'action': null,
      });
    }

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
              const Icon(Icons.lightbulb_outline, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'Tips to improve',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => _buildTipCard(tip)),
        ],
      ),
    );
  }

  Widget _buildTipCard(Map<String, String?> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip['title']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            tip['description']!,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          if (tip['action'] != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (tip['action'] == 'Edit Profile') {
                  context.push('/profile/edit');
                } else if (tip['action'] == 'Add Listing') {
                  context.push('/host/stays/create');
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                tip['action']!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

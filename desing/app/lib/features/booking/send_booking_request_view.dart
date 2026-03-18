import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';

/// Send Booking Request View - Screen 05
/// Per SCREEN_SPECS/05_SEND_BOOKING_REQUEST.md
///
/// Focused action form for submitting stay requests:
/// - Simple form: dates, guests, optional message
/// - Clear expectations: no payment in MVP
/// - Validation before submit
/// - Confirmation after submit
/// - Host notification trigger
///
/// Critical Rule: Request-only. No payment, no instant confirmation.
class SendBookingRequestView extends StatefulWidget {
  final String stayId;

  const SendBookingRequestView({super.key, required this.stayId});

  @override
  State<SendBookingRequestView> createState() => _SendBookingRequestViewState();
}

class _SendBookingRequestViewState extends State<SendBookingRequestView> {
  // State per 4.1 Local State (UI)
  Map<String, dynamic>? _stay;
  Map<String, dynamic>? _host;

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  Map<String, String> _errors = {};

  int get _maxGuests => (_stay?['guests_max'] as int?) ?? 10;
  String get _currency => _stay?['currency'] ?? '€';
  int get _priceMin => (_stay?['price_min'] as int?) ?? 0;
  int get _priceMax => (_stay?['price_max'] as int?) ?? 0;

  // Derived state per 4.2
  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  int get _estimatedMin => _nights * _priceMin;
  int get _estimatedMax => _nights * _priceMax;

  bool get _isValid =>
      _checkIn != null &&
      _checkOut != null &&
      _guests > 0 &&
      _guests <= _maxGuests &&
      _messageController.text.length <= 500;

  @override
  void initState() {
    super.initState();
    _loadStayData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadStayData() async {
    setState(() => _isLoading = true);

    try {
      final stayResponse = await Supabase.instance.client
          .from('stays')
          .select('*, users:host_id(*)')
          .eq('id', widget.stayId)
          .maybeSingle();

      if (stayResponse == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Stay not found')));
          context.pop();
        }
        return;
      }

      setState(() {
        _stay = stayResponse;
        _host = stayResponse['users'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading stay: $e')));
      }
    }
  }

  Future<void> _selectDates() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _checkIn ?? now.add(const Duration(days: 1)),
      end: _checkOut ?? now.add(const Duration(days: 3)),
    );

    final result = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initialRange,
      helpText: 'Select check-in and check-out dates',
      saveText: 'Confirm',
    );

    if (result != null) {
      setState(() {
        _checkIn = result.start;
        _checkOut = result.end;
        _errors.remove('dates');
      });
    }
  }

  void _incrementGuests() {
    if (_guests < _maxGuests) {
      setState(() => _guests++);
    }
  }

  void _decrementGuests() {
    if (_guests > 1) {
      setState(() => _guests--);
    }
  }

  void _validateForm() {
    final errors = <String, String>{};

    if (_checkIn == null) {
      errors['dates'] = 'Select check-in date';
    }
    if (_checkOut == null) {
      errors['dates'] = 'Select check-out date';
    }
    if (_checkIn != null &&
        _checkOut != null &&
        !_checkOut!.isAfter(_checkIn!)) {
      errors['dates'] = 'Check-out must be after check-in';
    }
    if (_guests < 1) {
      errors['guests'] = 'At least 1 guest required';
    }
    if (_guests > _maxGuests) {
      errors['guests'] = 'Max $_maxGuests guests';
    }
    if (_messageController.text.length > 500) {
      errors['message'] = 'Max 500 characters';
    }

    setState(() => _errors = errors);
  }

  Future<void> _submitRequest() async {
    _validateForm();
    if (_errors.isNotEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      final returnUrl = Uri.encodeComponent('/stay/${widget.stayId}/request');
      context.push('/auth/login?redirect=$returnUrl');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errors = {};
    });

    try {
      // Check for duplicate request per 13. Security
      final existingRequests = await Supabase.instance.client
          .from('booking_request_stay')
          .select('id')
          .eq('stay_id', widget.stayId)
          .eq('user_id', user.id)
          .eq('status', 'sent')
          .limit(1);

      if ((existingRequests as List).isNotEmpty) {
        setState(() {
          _errors['submit'] =
              'You already have a pending request for this stay.';
          _isSubmitting = false;
        });
        return;
      }

      // Create booking request per 6.2 Write Operations
      await Supabase.instance.client.from('booking_request_stay').insert({
        'stay_id': widget.stayId,
        'user_id': user.id,
        'check_in': _checkIn!.toIso8601String().split('T')[0],
        'check_out': _checkOut!.toIso8601String().split('T')[0],
        'guests': _guests,
        'message': _messageController.text.trim(),
        'status': 'sent',
      });

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errors['submit'] = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request to Book')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 9.1 Confirmation UI after successful submission
    if (_isSubmitted) {
      return _buildConfirmationView();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Request to Book'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3.2 Stay Summary (Compact)
            _buildStaySummary(),
            const SizedBox(height: 24),

            // 3.3 Date Selection
            _buildDateSelection(),
            const SizedBox(height: 24),

            // 3.4 Guest Count
            _buildGuestSelector(),
            const SizedBox(height: 24),

            // 3.5 Estimated Total
            if (_nights > 0) ...[
              _buildEstimatedTotal(),
              const SizedBox(height: 24),
            ],

            // 3.6 Message to Host
            _buildMessageInput(),
            const SizedBox(height: 24),

            // 3.7 Expectations Banner
            _buildExpectationsBanner(),
            const SizedBox(height: 24),

            // Error display
            if (_errors['submit'] != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errors['submit']!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // 3.8 Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid && !_isSubmitting ? _submitRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, AppButton.height),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
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
                    : const Text(
                        'Send Request',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // 3.9 Cancel Link
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3.2 Stay Summary
  Widget _buildStaySummary() {
    final title = _stay?['title'] ?? 'Stay';
    final hostName = _host?['display_name'] ?? _host?['full_name'] ?? 'Host';
    final hostAvatar = _host?['avatar_url'];
    final mediaUrls = _stay?['media_urls'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(AppRadius.chip),
              image: mediaUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(mediaUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: mediaUrls.isEmpty
                ? const Icon(Icons.hotel, color: Colors.grey, size: 32)
                : null,
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: hostAvatar != null
                          ? NetworkImage(hostAvatar)
                          : null,
                      child: hostAvatar == null
                          ? Text(
                              hostName[0],
                              style: const TextStyle(fontSize: 10),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hosted by $hostName',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '~$_currency$_priceMin–$_currency$_priceMax / night',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3.3 Date Selection
  Widget _buildDateSelection() {
    final hasError = _errors.containsKey('dates');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When are you staying?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDates,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? Colors.red : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _checkIn != null
                            ? _formatDate(_checkIn!)
                            : 'Select date',
                        style: TextStyle(
                          color: _checkIn != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-out',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _checkOut != null
                              ? _formatDate(_checkOut!)
                              : 'Select date',
                          style: TextStyle(
                            color: _checkOut != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (_nights > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$_nights night${_nights > 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errors['dates']!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// 3.4 Guest Count
  Widget _buildGuestSelector() {
    final hasError = _errors.containsKey('guests');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guests',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_guests guest${_guests > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: _guests > 1 ? _decrementGuests : null,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: _guests > 1 ? AppColors.primary : Colors.grey[300],
                ),
              ),
              Text(
                '$_guests',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _guests < _maxGuests ? _incrementGuests : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: _guests < _maxGuests
                      ? AppColors.primary
                      : Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Max $_maxGuests guests',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errors['guests']!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// 3.5 Estimated Total
  Widget _buildEstimatedTotal() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$_currency$_estimatedMin – $_currency$_estimatedMax',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_nights nights × $_currency$_priceMin–$_currency$_priceMax per night',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Final price confirmed by host',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// 3.6 Message to Host
  Widget _buildMessageInput() {
    final charCount = _messageController.text.length;
    final hasError = charCount > 500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Message to Host',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '(optional)',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tell the host about your trip...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            counterText: '',
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$charCount/500',
            style: TextStyle(
              color: hasError ? Colors.red : Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// 3.7 Expectations Banner
  Widget _buildExpectationsBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is a booking request. The host will review and respond. No payment required now.',
              style: TextStyle(color: Colors.blue[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// 9.1 Confirmation View
  Widget _buildConfirmationView() {
    final hostName = _host?['display_name'] ?? _host?['full_name'] ?? 'Host';

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 48, color: Colors.green[600]),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Request Sent!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                '$hostName will review your request and respond soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Request summary
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Dates',
                      '${_formatDate(_checkIn!)} - ${_formatDate(_checkOut!)}',
                    ),
                    const Divider(),
                    _buildSummaryRow('Guests', '$_guests'),
                    const Divider(),
                    _buildSummaryRow(
                      'Estimated',
                      '$_currency$_estimatedMin – $_currency$_estimatedMax',
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Expected response
              Text(
                'Hosts usually respond within 24 hours',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 32),

              // 9.2 Confirmation Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/profile/requests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, AppButton.height),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: const Text('View My Requests'),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/explore'),
                child: const Text('Continue Exploring'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';

/// Stays Management View - Screen 11
/// Per SCREEN_SPECS/11_STAYS_MANAGEMENT_LIST.md
///
/// Host's control center for all stay listings:
/// - Overview of all stays (draft, published, paused)
/// - Quick status toggling and pricing updates
/// - Performance snapshot for each listing
/// - Entry point to create or edit stays
///
/// Host-Only: Requires authenticated host role
class StaysManagementView extends StatefulWidget {
  const StaysManagementView({super.key});

  @override
  State<StaysManagementView> createState() => _StaysManagementViewState();
}

class _StaysManagementViewState extends State<StaysManagementView>
    with SingleTickerProviderStateMixin {
  // State per 5.1 Local State (UI)
  List<Map<String, dynamic>> _stays = [];
  String _activeFilter = 'all'; // all, active, paused, draft
  bool _isLoading = true;
  String? _error;

  // Inline price editor state
  String? _editingPriceId;
  int? _tempPriceMin;
  int? _tempPriceMax;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Summary stats
  int _totalListings = 0;
  int _activeCount = 0;
  int _totalViews = 0;
  int _pendingRequests = 0;

  late TabController _tabController;
  final List<String> _filterTabs = ['All', 'Published', 'Paused', 'Drafts'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onFilterChanged(_tabController.index);
      }
    });
    _loadStays();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onFilterChanged(int index) {
    setState(() {
      switch (index) {
        case 0:
          _activeFilter = 'all';
          break;
        case 1:
          _activeFilter = 'active';
          break;
        case 2:
          _activeFilter = 'paused';
          break;
        case 3:
          _activeFilter = 'draft';
          break;
      }
    });
  }

  List<Map<String, dynamic>> get _filteredStays {
    if (_activeFilter == 'all') return _stays;
    return _stays.where((stay) => stay['status'] == _activeFilter).toList();
  }

  Future<void> _loadStays() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Please log in to manage stays';
          _isLoading = false;
        });
        return;
      }

      // Fetch all host's stays
      final staysResponse = await Supabase.instance.client
          .from('stays')
          .select()
          .eq('host_id', user.id)
          .order('created_at', ascending: false);

      _stays = List<Map<String, dynamic>>.from(staysResponse);

      // Calculate summary stats
      _totalListings = _stays.length;
      _activeCount = _stays.where((s) => s['status'] == 'active').length;
      _totalViews = _stays.fold<int>(
        0,
        (sum, s) => sum + ((s['views_count'] as int?) ?? 0),
      );

      // Fetch pending requests count
      final requestsResponse = await Supabase.instance.client
          .from('booking_request_stay')
          .select('id')
          .inFilter('stay_id', _stays.map((s) => s['id']).toList())
          .eq('status', 'sent');

      _pendingRequests = (requestsResponse as List).length;

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

  Future<void> _toggleStayStatus(Map<String, dynamic> stay) async {
    final currentStatus = stay['status'] as String;
    final newStatus = currentStatus == 'active' ? 'paused' : 'active';

    // Optimistic update
    final index = _stays.indexWhere((s) => s['id'] == stay['id']);
    if (index == -1) return;

    final oldStay = Map<String, dynamic>.from(_stays[index]);
    setState(() {
      _stays[index] = {..._stays[index], 'status': newStatus};
    });

    try {
      await Supabase.instance.client
          .from('stays')
          .update({'status': newStatus})
          .eq('id', stay['id']);

      // Update active count
      _activeCount = _stays.where((s) => s['status'] == 'active').length;
    } catch (e) {
      // Revert on error
      setState(() {
        _stays[index] = oldStay;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  void _openPriceEditor(Map<String, dynamic> stay) {
    setState(() {
      _editingPriceId = stay['id'];
      _tempPriceMin = stay['price_min'] ?? 0;
      _tempPriceMax = stay['price_max'] ?? 0;
      _minPriceController.text = _tempPriceMin.toString();
      _maxPriceController.text = _tempPriceMax.toString();
    });
  }

  void _closePriceEditor() {
    setState(() {
      _editingPriceId = null;
      _tempPriceMin = null;
      _tempPriceMax = null;
    });
  }

  Future<void> _savePriceEdit() async {
    final minPrice = int.tryParse(_minPriceController.text) ?? 0;
    final maxPrice = int.tryParse(_maxPriceController.text) ?? 0;

    // Validation per 7.2
    if (minPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum price must be greater than 0')),
      );
      return;
    }
    if (maxPrice < minPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum must be ≥ minimum')),
      );
      return;
    }
    if (maxPrice > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum price cannot exceed €10,000')),
      );
      return;
    }

    try {
      await Supabase.instance.client
          .from('stays')
          .update({'price_min': minPrice, 'price_max': maxPrice})
          .eq('id', _editingPriceId!);

      // Update local state
      final index = _stays.indexWhere((s) => s['id'] == _editingPriceId);
      if (index != -1) {
        setState(() {
          _stays[index] = {
            ..._stays[index],
            'price_min': minPrice,
            'price_max': maxPrice,
          };
        });
      }

      _closePriceEditor();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Price updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update price: $e')));
      }
    }
  }

  Future<void> _deleteStay(Map<String, dynamic> stay) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this stay?'),
        content: const Text(
          'This action cannot be undone. Active booking requests will be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('stays')
          .delete()
          .eq('id', stay['id']);

      setState(() {
        _stays.removeWhere((s) => s['id'] == stay['id']);
        _totalListings = _stays.length;
        _activeCount = _stays.where((s) => s['status'] == 'active').length;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stay deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete stay: $e')));
      }
    }
  }

  void _navigateToCreateStay() {
    context.push('/host/stays/new');
  }

  void _navigateToEditStay(String stayId) {
    context.push('/host/stays/$stayId/edit');
  }

  void _previewStay(String stayId) {
    context.push('/explore/stay/$stayId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('My Stays'),
        actions: [
          TextButton.icon(
            onPressed: _navigateToCreateStay,
            icon: const Icon(Icons.add),
            label: const Text('Add Stay'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: _filterTabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadStays,
              child: Column(
                children: [
                  // 3.5 Summary Stats
                  _buildSummaryStats(),

                  // Stays list
                  Expanded(
                    child: _filteredStays.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            itemCount: _filteredStays.length,
                            itemBuilder: (context, index) {
                              final stay = _filteredStays[index];
                              return _buildStayCard(stay);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadStays, child: const Text('Retry')),
        ],
      ),
    );
  }

  /// 3.5 Summary Stats
  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('$_totalListings', 'Stays'),
          _buildStatItem('$_activeCount', 'Published'),
          _buildStatItem('$_totalViews', 'Views'),
          _buildStatItem(
            _pendingRequests.toString(),
            'Pending',
            badge: _pendingRequests > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {bool badge = false}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (badge)
              Positioned(
                right: -8,
                top: -4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  /// 3.4 Empty State
  Widget _buildEmptyState() {
    String message;
    String suggestion;

    switch (_activeFilter) {
      case 'active':
        message = 'No published stays';
        suggestion = 'Publish a draft to go live.';
        break;
      case 'paused':
        message = 'No paused stays';
        suggestion = '';
        break;
      case 'draft':
        message = 'No drafts';
        suggestion = 'All your stays are published!';
        break;
      default:
        message = "You haven't created any stays yet";
        suggestion = 'List your first stay!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (suggestion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                suggestion,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            if (_activeFilter == 'all')
              ElevatedButton.icon(
                onPressed: _navigateToCreateStay,
                icon: const Icon(Icons.add),
                label: const Text('List Your First Stay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, AppButton.height),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 3.3 Stay Card
  Widget _buildStayCard(Map<String, dynamic> stay) {
    final title = stay['title'] ?? 'Untitled Stay';
    final status = stay['status'] ?? 'draft';
    final priceMin = stay['price_min'] ?? 0;
    final priceMax = stay['price_max'] ?? 0;
    final currency = stay['currency'] ?? '€';
    final viewsCount = stay['views_count'] ?? 0;
    final requestsCount = stay['requests_count'] ?? 0;
    final mediaUrls = stay['media_urls'] as List? ?? [];
    final updatedAt = stay['updated_at'];

    String statusLabel;
    Color statusColor;
    switch (status) {
      case 'active':
        statusLabel = 'Published';
        statusColor = Colors.green;
        break;
      case 'paused':
        statusLabel = 'Paused';
        statusColor = Colors.orange;
        break;
      case 'suspended':
        statusLabel = 'Suspended';
        statusColor = Colors.red;
        break;
      default:
        statusLabel = 'Draft';
        statusColor = Colors.grey;
    }

    String lastUpdated = '';
    if (updatedAt != null) {
      final date = DateTime.tryParse(updatedAt);
      if (date != null) {
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          lastUpdated = 'Updated ${diff.inDays} days ago';
        } else if (diff.inHours > 0) {
          lastUpdated = 'Updated ${diff.inHours} hours ago';
        } else {
          lastUpdated = 'Updated recently';
        }
      }
    }

    final isEditing = _editingPriceId == stay['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
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

                // Title + Status
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // More menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _navigateToEditStay(stay['id']);
                        break;
                      case 'pause':
                        _toggleStayStatus(stay);
                        break;
                      case 'view':
                        _previewStay(stay['id']);
                        break;
                      case 'delete':
                        _deleteStay(stay);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'pause',
                      child: Text(status == 'active' ? 'Pause' : 'Publish'),
                    ),
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View listing'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Pricing Section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: isEditing
                ? _buildInlinePriceEditor(currency)
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$currency$priceMin – $currency$priceMax / night',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (lastUpdated.isNotEmpty)
                              Text(
                                lastUpdated,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openPriceEditor(stay),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
          ),

          const Divider(height: 1),

          // Performance Snapshot
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              children: [
                _buildPerformanceChip(Icons.visibility, '$viewsCount views'),
                const SizedBox(width: 12),
                _buildPerformanceChip(
                  Icons.mail_outline,
                  '$requestsCount requests',
                ),
                const Spacer(),

                // Quick toggle
                if (status != 'draft' && status != 'suspended')
                  Row(
                    children: [
                      Text(
                        status == 'active' ? 'Live' : 'Off',
                        style: TextStyle(
                          color: status == 'active'
                              ? Colors.green
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Switch(
                        value: status == 'active',
                        onChanged: (_) => _toggleStayStatus(stay),
                        activeThumbColor: Colors.green,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  /// 7.1 Inline Price Editor
  Widget _buildInlinePriceEditor(String currency) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Min ($currency)',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _maxPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max ($currency)',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _savePriceEdit,
          icon: const Icon(Icons.check, color: Colors.green),
        ),
        IconButton(
          onPressed: _closePriceEditor,
          icon: const Icon(Icons.close, color: Colors.grey),
        ),
      ],
    );
  }
}

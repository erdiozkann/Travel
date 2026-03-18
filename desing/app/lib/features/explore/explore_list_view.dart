import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';
import '../../core/ui/widgets/cards.dart';

/// Explore List View - Screen 02
/// Per SCREEN_SPECS/02_EXPLORE_LIST_VIEW.md
///
/// List-based discovery with:
/// - Scrollable, paginated list of places, experiences, and stays
/// - Powerful filtering and search
/// - Quick comparison of options (price, rating, badges)
/// - Entry point to all detail screens
class ExploreListView extends StatefulWidget {
  const ExploreListView({super.key});

  @override
  State<ExploreListView> createState() => _ExploreListViewState();
}

class _ExploreListViewState extends State<ExploreListView> {
  // State per 4.1 Local State (UI)
  String? _selectedCityId;
  String _activeType = 'all'; // all, experience, stay, place
  final List<String> _categoryFilters = [];
  final List<String> _priceLevels = [];
  double? _minRating;
  bool _localOnly = false;
  String _sortBy = 'recommended';
  String? _searchQuery;

  List<Map<String, dynamic>> _items = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  // Categories per 3.3 Filter Chips Row

  @override
  void initState() {
    super.initState();
    _loadItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Infinite scroll pagination per 3.4
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _items = [];
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final items = await _fetchItems(1);
      setState(() {
        _items = items;
        _hasMore = items.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final newItems = await _fetchItems(nextPage);

      setState(() {
        _items.addAll(newItems);
        _currentPage = nextPage;
        _hasMore = newItems.length >= 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchItems(int page) async {
    // Build query based on active type per 3.2
    final tableName = _activeType == 'stay'
        ? 'stays'
        : _activeType == 'place'
        ? 'places'
        : 'experiences';

    // Build query - use dynamic to handle different builder types
    final baseQuery = Supabase.instance.client.from(tableName).select();

    // Apply filters per 4.1 State
    dynamic filteredQuery = baseQuery;

    if (_selectedCityId != null) {
      filteredQuery = filteredQuery.eq('city_id', _selectedCityId!);
    }

    if (_categoryFilters.isNotEmpty && _activeType != 'stay') {
      filteredQuery = filteredQuery.contains('category', _categoryFilters);
    }

    if (_minRating != null) {
      filteredQuery = filteredQuery.gte('rating', _minRating!);
    }

    // Sorting per 3.3
    dynamic sortedQuery;
    switch (_sortBy) {
      case 'price_asc':
        sortedQuery = filteredQuery.order('price_min', ascending: true);
        break;
      case 'rating_desc':
        sortedQuery = filteredQuery.order('rating', ascending: false);
        break;
      default:
        sortedQuery = filteredQuery
            .order('is_sponsored', ascending: false)
            .order('rating', ascending: false);
    }

    // Pagination - 20 items per page per 3.4
    final offset = (page - 1) * 20;
    final pagedQuery = sortedQuery.range(offset, offset + 19);

    final response = await pagedQuery;
    return List<Map<String, dynamic>>.from(response);
  }

  void _onTypeChanged(String type) {
    if (type == _activeType) return;
    setState(() {
      _activeType = type;
    });
    _loadItems();
  }

  void _openSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SearchOverlay(
        initialQuery: _searchQuery,
        onSearch: (query) {
          setState(() => _searchQuery = query);
          Navigator.pop(context);
          _loadItems();
        },
      ),
    );
  }

  void _openCitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CitySelectorSheet(
        selectedCityId: _selectedCityId,
        onCitySelected: (cityId) {
          setState(() {
            _selectedCityId = cityId;
          });
          _loadItems();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey bg
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _openCitySelector,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current Location',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Kyoto, Japan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none, size: 20),
                    ),
                    Positioned(
                      top: 2,
                      right: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: 6,
                  top: 6,
                  bottom: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Where do you want to go?',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Custom Pill Row
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _buildCustomPill(
                  'All',
                  Icons.star,
                  _activeType == 'all',
                  () => _onTypeChanged('all'),
                ),
                const SizedBox(width: 10),
                _buildCustomPill(
                  'Food',
                  Icons.restaurant,
                  _activeType == 'food',
                  () => _onTypeChanged('food'),
                ),
                const SizedBox(width: 10),
                _buildCustomPill(
                  'Nature',
                  Icons.park,
                  _activeType == 'nature',
                  () => _onTypeChanged('nature'),
                ),
                const SizedBox(width: 10),
                _buildCustomPill(
                  'Stays',
                  Icons.home,
                  _activeType == 'stay',
                  () => _onTypeChanged('stay'),
                ),
              ],
            ),
          ),

          // 3.4 Results List
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildCustomPill(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey[800],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[800],
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3.4 Results List with Discovery Sections
  Widget _buildResultsList() {
    if (_isLoading && _items.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (_error != null && _items.isEmpty) {
      return _buildErrorState();
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    // Show discovery sections only in default view
    final showDiscovery =
        _activeType == 'all' &&
        _categoryFilters.isEmpty &&
        _priceLevels.isEmpty &&
        _searchQuery == null &&
        !_localOnly;

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (showDiscovery) ...[
            SliverToBoxAdapter(child: _buildCuratedSection()),
            SliverToBoxAdapter(child: _buildHiddenGemsSection()),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'All Places',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == _items.length) {
                  return _hasMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox(height: 80); // Bottom padding
                }

                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildItemCard(item),
                );
              }, childCount: _items.length + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedSection() {
    if (_items.isEmpty) return const SizedBox.shrink();
    // In real app, this would be a separate filtered list
    final curatedItems = _items.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Curated by Locals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: curatedItems.length,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: AppSpacing.md),
                child: _buildItemCard(curatedItems[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHiddenGemsSection() {
    if (_items.length < 5) return const SizedBox.shrink();
    // In real app, this would be filtered by 'hidden' tag
    final hiddenGems = _items.skip(3).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hidden Gems',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: hiddenGems.length,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: AppSpacing.md),
                child: _buildItemCard(hiddenGems[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    // Use appropriate card based on type
    if (_activeType == 'stay') {
      return StayCard(
        id: item['id'] ?? '',
        title: item['title'] ?? 'Untitled Stay',
        imageUrl: (item['media_urls'] as List?)?.isNotEmpty == true
            ? item['media_urls'][0]
            : null,
        pricePerNight: item['price_min'],
        currency: item['currency'] ?? '€',
        rating: (item['rating'] as num?)?.toDouble(),
        reviewCount: item['review_count'],
        roomType: item['room_type'],
        verifiedHost: item['verified_host'] == true,
        isSponsored: item['is_sponsored'] == true,
        onTap: () {
          context.pushNamed(
            'stay-detail',
            pathParameters: {'id': item['id'].toString()},
          );
        },
      );
    }

    // Default: ExperienceCard
    return ExperienceCard(
      id: item['id'] ?? '',
      title: item['title'] ?? 'Untitled Experience',
      imageUrl: (item['media_urls'] as List?)?.isNotEmpty == true
          ? item['media_urls'][0]
          : null,
      durationMinutes: item['duration_minutes'],
      priceMin: item['price_min'],
      priceMax: item['price_max'],
      currency: item['currency'] ?? '€',
      rating: (item['rating'] as num?)?.toDouble(),
      reviewCount: item['review_count'],
      localScore: item['local_score'] != null
          ? (item['local_score'] > 0.7 ? 'local' : null)
          : null,
      isSponsored: item['is_sponsored'] == true,
      onTap: () {
        context.pushNamed(
          'experience-detail',
          pathParameters: {'id': item['id'].toString()},
        );
      },
    );
  }

  /// Loading skeleton per 9.2
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 200, height: 16, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 14, color: Colors.grey[300]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Error state per 9.2
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Failed to load',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, AppButton.height),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state per 3.5
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No results found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear filters'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(140, AppButton.height),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _categoryFilters.clear();
      _priceLevels.clear();
      _minRating = null;
      _localOnly = false;
      _searchQuery = null;
      _sortBy = 'recommended';
    });
    _loadItems();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FilterSheet(
        sortBy: _sortBy,
        onSortChanged: (sort) {
          setState(() => _sortBy = sort);
          Navigator.pop(context);
          _loadItems();
        },
      ),
    );
  }
}

/// Search overlay
class _SearchOverlay extends StatefulWidget {
  final String? initialQuery;
  final Function(String) onSearch;

  const _SearchOverlay({this.initialQuery, required this.onSearch});

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search experiences, stays...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onSubmitted: widget.onSearch,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSearch(_controller.text),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, AppButton.height),
              ),
              child: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter sheet for sorting
class _FilterSheet extends StatelessWidget {
  final String sortBy;
  final Function(String) onSortChanged;

  const _FilterSheet({required this.sortBy, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort by',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(
              Icons.recommend,
              color: sortBy == 'recommended' ? AppColors.primary : null,
            ),
            title: const Text('Recommended'),
            selected: sortBy == 'recommended',
            onTap: () => onSortChanged('recommended'),
          ),
          ListTile(
            leading: Icon(
              Icons.arrow_upward,
              color: sortBy == 'price_asc' ? AppColors.primary : null,
            ),
            title: const Text('Price: Low to High'),
            selected: sortBy == 'price_asc',
            onTap: () => onSortChanged('price_asc'),
          ),
          ListTile(
            leading: Icon(
              Icons.star,
              color: sortBy == 'rating_desc' ? AppColors.primary : null,
            ),
            title: const Text('Rating: High to Low'),
            selected: sortBy == 'rating_desc',
            onTap: () => onSortChanged('rating_desc'),
          ),
        ],
      ),
    );
  }
}

/// City selector bottom-sheet widget
class _CitySelectorSheet extends StatefulWidget {
  final String? selectedCityId;
  final void Function(String? cityId) onCitySelected;

  const _CitySelectorSheet({
    required this.selectedCityId,
    required this.onCitySelected,
  });

  @override
  State<_CitySelectorSheet> createState() => _CitySelectorSheetState();
}

class _CitySelectorSheetState extends State<_CitySelectorSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final response = await Supabase.instance.client
          .from('cities')
          .select('id, name, country')
          .order('name');
      setState(() {
        _cities = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Choose a City',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            // All cities option
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('All Cities'),
              selected: widget.selectedCityId == null,
              selectedColor: AppColors.primary,
              onTap: () {
                widget.onCitySelected(null);
                Navigator.pop(context);
              },
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final id = city['id'].toString();
                    return ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(city['name'] ?? ''),
                      subtitle: Text(city['country'] ?? ''),
                      selected: widget.selectedCityId == id,
                      selectedColor: AppColors.primary,
                      onTap: () {
                        widget.onCitySelected(id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

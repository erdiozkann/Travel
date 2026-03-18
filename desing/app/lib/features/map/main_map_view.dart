import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';

/// Main Map View - Screen 01
/// Per SCREEN_SPECS/01_MAIN_MAP_VIEW.md
///
/// Primary entry point providing:
/// - Geographic discovery of places, experiences, and stays
/// - Visual clustering of pins by category
/// - Quick preview cards for tapped pins
/// - Filter chips for narrowing results
class MainMapView extends StatefulWidget {
  const MainMapView({super.key});

  @override
  State<MainMapView> createState() => _MainMapViewState();
}

class _MainMapViewState extends State<MainMapView> {
  // State per 4.1 Local State (UI)
  String? _selectedCityId;
  final String _activeTypeFilter = 'all'; // all, experience, stay, place

  String? _selectedPinId;
  bool _isBottomSheetVisible = false;
  Map<String, dynamic>? _selectedItem;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _pins = [];
  List<Map<String, dynamic>> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadPins();
  }

  Future<void> _loadCities() async {
    try {
      // Try with is_active filter first
      List<dynamic> response;
      try {
        response = await Supabase.instance.client
            .from('cities')
            .select()
            .eq('is_active', true)
            .order('name');
      } catch (e) {
        // Fallback if is_active column doesn't exist
        response = await Supabase.instance.client
            .from('cities')
            .select()
            .order('name');
      }

      setState(() {
        _cities = List<Map<String, dynamic>>.from(response);
        if (_cities.isNotEmpty && _selectedCityId == null) {
          // Default to Barcelona or first city
          final barcelona = _cities.firstWhere(
            (c) => c['name']?.toString().toLowerCase() == 'barcelona',
            orElse: () => _cities.first,
          );
          _selectedCityId = barcelona['id'];
        }
      });
    } catch (e) {
      debugPrint('Failed to load cities: $e');
    }
  }

  Future<void> _loadPins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch pins based on active type filter
      List<Map<String, dynamic>> allPins = [];

      if (_activeTypeFilter == 'all' || _activeTypeFilter == 'experience') {
        final experiences = await _fetchExperiences();
        allPins.addAll(
          experiences.map((e) => {...e, 'pin_type': 'experience'}),
        );
      }

      if (_activeTypeFilter == 'all' || _activeTypeFilter == 'stay') {
        final stays = await _fetchStays();
        allPins.addAll(stays.map((s) => {...s, 'pin_type': 'stay'}));
      }

      if (_activeTypeFilter == 'all' || _activeTypeFilter == 'place') {
        final places = await _fetchPlaces();
        allPins.addAll(places.map((p) => {...p, 'pin_type': 'place'}));
      }

      setState(() {
        _pins = allPins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchExperiences() async {
    try {
      dynamic query = Supabase.instance.client
          .from('experiences')
          .select(
            'id, title, price_min, price_max, currency, rating, review_count, category, lat, lng, is_sponsored, media_urls',
          )
          .eq('status', 'active');

      if (_selectedCityId != null) {
        query = query.eq('city_id', _selectedCityId!);
      }

      final response = await query.limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('_fetchExperiences error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStays() async {
    try {
      dynamic query = Supabase.instance.client
          .from('stays')
          .select(
            'id, title, price_min, price_max, currency, rating, review_count, lat, lng, is_sponsored, media_urls',
          )
          .eq('status', 'active');

      if (_selectedCityId != null) {
        query = query.eq('city_id', _selectedCityId!);
      }

      final response = await query.limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('_fetchStays error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPlaces() async {
    try {
      dynamic query = Supabase.instance.client
          .from('places')
          .select(
            'id, name, category, price_level, rating, review_count, lat, lng, is_sponsored, media_urls',
          );

      if (_selectedCityId != null) {
        query = query.eq('city_id', _selectedCityId!);
      }

      final response = await query.limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('_fetchPlaces error: $e');
      return [];
    }
  }

  void _onPinTapped(Map<String, dynamic> pin) {
    setState(() {
      _selectedPinId = pin['id'];
      _selectedItem = pin;
      _isBottomSheetVisible = true;
    });
  }

  void _closeBottomSheet() {
    setState(() {
      _selectedPinId = null;
      _selectedItem = null;
      _isBottomSheetVisible = false;
    });
  }

  void _navigateToDetail() {
    if (_selectedItem == null) return;

    final type = _selectedItem!['pin_type'];
    final id = _selectedItem!['id'];

    _closeBottomSheet();

    switch (type) {
      case 'experience':
        context.push('/explore/experience/$id');
        break;
      case 'stay':
        context.push('/explore/stay/$id');
        break;
      case 'place':
        // Places don't have detail view in MVP
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          // 3.3 Map Canvas (placeholder)
          _buildMapCanvas(),

          // 3.1 Top Bar + 3.2 Filter Chips
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(children: [_buildTopBar(), _buildFilterChips()]),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // 3.4 Bottom Sheet Preview Card
          if (_isBottomSheetVisible && _selectedItem != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildPreviewCard(),
            ),
        ],
      ),
    );
  }

  /// 3.1 Top Bar
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                'Search hotels, spots...',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune, color: Colors.black87, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  /// 3.2 Filter Chips Row
  Widget _buildFilterChips() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _buildDropdownChip('Price'),
          const SizedBox(width: 8),
          _buildDropdownChip('Rating'),
          const SizedBox(width: 8),
          _buildActionChip('Open Now', false),
          const SizedBox(width: 8),
          _buildActionChip('Anytime', true),
        ],
      ),
    );
  }

  Widget _buildDropdownChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 3.3 Map Canvas (placeholder - real map integration needed)
  Widget _buildMapCanvas() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('Failed to load map data'),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPins,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Map placeholder with pin markers
    return Container(
      color: Colors.grey[200],
      child: Stack(
        children: [
          // Map background placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Map View',
                  style: TextStyle(fontSize: 24, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Google Maps integration needed',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),

          // Simulated pins grid (placeholder for real map markers)
          if (_pins.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  itemCount: _pins.length,
                  itemBuilder: (context, index) {
                    final pin = _pins[index];
                    return _buildPinMarker(pin);
                  },
                ),
              ),
            ),

          // Empty state per 9.1
          if (_pins.isEmpty && !_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No places found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing filters or selecting a different city',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Pin marker widget (placeholder for real map markers)
  Widget _buildPinMarker(Map<String, dynamic> pin) {
    final type = pin['pin_type'];
    final isSponsored = pin['is_sponsored'] == true;

    Color pinColor;
    IconData pinIcon;

    switch (type) {
      case 'experience':
        pinColor = AppColors.primary;
        pinIcon = Icons.local_activity;
        break;
      case 'stay':
        pinColor = AppColors.secondary;
        pinIcon = Icons.hotel;
        break;
      default:
        pinColor = Colors.grey;
        pinIcon = Icons.place;
    }

    return GestureDetector(
      onTap: () => _onPinTapped(pin),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
          border: _selectedPinId == pin['id']
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: pinColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(pinIcon, size: 16, color: pinColor),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pin['title'] ?? pin['name'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (pin['rating'] != null)
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    (pin['rating'] as num).toStringAsFixed(1),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            const Spacer(),
            Row(
              children: [
                if (pin['price_min'] != null)
                  Text(
                    '${pin['currency'] ?? '€'}${pin['price_min']}–${pin['price_max'] ?? ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                if (isSponsored)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AD',
                      style: TextStyle(fontSize: 8, color: Colors.amber),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 3.4 Bottom Sheet Preview Card
  Widget _buildPreviewCard() {
    final item = _selectedItem!;
    final title = item['title'] ?? item['name'] ?? 'Cafe de Flore';
    final rating = item['rating'] ?? 4.9;
    final reviewCount = item['review_count'] ?? '1.2k';
    // final priceMin = item['price_min'];
    // final priceMax = item['price_max'];
    // final currency = item['currency'] ?? '€';
    // final isSponsored = item['is_sponsored'] == true;
    final category = item['category'] ?? 'French Bistro';

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'LOCAL FAVORITE',
                          style: TextStyle(
                            color: Color(0xFF008080),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '$rating ($reviewCount)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category • €€€ • 1.2km away',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                ),
                child:
                    item['media_urls'] != null &&
                        (item['media_urls'] as List).isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          item['media_urls'][0],
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.restaurant, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Verified Authentic',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 14,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Price Guaranteed',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _navigateToDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'View Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

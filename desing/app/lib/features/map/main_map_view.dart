import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Main Map View — real interactive OpenStreetMap
/// Businesses shown as coloured pins; tap → preview card.
/// AI Plan integration: pick any pin → "Add to My Plan".
class MainMapView extends StatefulWidget {
  const MainMapView({super.key});

  @override
  State<MainMapView> createState() => _MainMapViewState();
}

class _MainMapViewState extends State<MainMapView>
    with TickerProviderStateMixin {
  // ── Map controller ────────────────────────────────────────────────────────
  final MapController _mapController = MapController();

  // Default: Barcelona
  static const LatLng _defaultCenter = LatLng(41.3851, 2.1734);
  static const double _defaultZoom = 13.5;

  // ── State ─────────────────────────────────────────────────────────────────
  String _activeTypeFilter = 'all'; // all | experience | stay | place
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _pins = [];
  Map<String, dynamic>? _selectedPin;
  bool _showPreview = false;

  // AI Plan overlay
  final Set<String> _planPinIds = {};
  bool _showPlanBar = false;

  // City
  List<Map<String, dynamic>> _cities = [];
  String? _selectedCityId;
  String _selectedCityName = 'Barcelona';
  LatLng _cityCenter = _defaultCenter;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Data loaders ──────────────────────────────────────────────────────────

  Future<void> _loadCities() async {
    try {
      final res = await Supabase.instance.client
          .from('cities')
          .select('id, name, lat, lng')
          .eq('is_active', true)
          .order('name');
      final cities = List<Map<String, dynamic>>.from(res);
      setState(() => _cities = cities);

      final bcn = cities.firstWhere(
        (c) => c['name'].toString().toLowerCase().contains('barcelona'),
        orElse: () => cities.isNotEmpty ? cities.first : {},
      );
      if (bcn.isNotEmpty) {
        _selectedCityId = bcn['id'].toString();
        _selectedCityName = bcn['name'] ?? 'Barcelona';
        if (bcn['lat'] != null && bcn['lng'] != null) {
          _cityCenter = LatLng(
            (bcn['lat'] as num).toDouble(),
            (bcn['lng'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      debugPrint('loadCities: $e');
    }
    _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _pins = [];
      _selectedPin = null;
      _showPreview = false;
    });

    try {
      final List<Map<String, dynamic>> all = [];

      if (_activeTypeFilter == 'all' || _activeTypeFilter == 'experience') {
        all.addAll(await _fetch('experience'));
      }
      if (_activeTypeFilter == 'all' || _activeTypeFilter == 'stay') {
        all.addAll(await _fetch('stay'));
      }
      if (_activeTypeFilter == 'all' || _activeTypeFilter == 'place') {
        all.addAll(await _fetch('place'));
      }

      setState(() {
        _pins = all;
        _isLoading = false;
      });

      // Fly map to city center
      if (mounted) {
        _mapController.move(_cityCenter, _defaultZoom);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetch(String type) async {
    try {
      String table;
      String select;
      switch (type) {
        case 'experience':
          table = 'experiences';
          select =
              'id, title, price_min, price_max, currency, rating, review_count, category, lat, lng, is_sponsored, media_urls';
          break;
        case 'stay':
          table = 'stays';
          select =
              'id, title, price_min, price_max, currency, rating, review_count, lat, lng, is_sponsored, media_urls';
          break;
        default:
          table = 'places';
          select =
              'id, name, category, price_level, rating, review_count, lat, lng, is_sponsored, media_urls';
      }

      dynamic q = Supabase.instance.client.from(table).select(select);
      if (_selectedCityId != null) q = q.eq('city_id', _selectedCityId!);
      final res = await q.limit(80);
      return List<Map<String, dynamic>>.from(res)
          .where((p) => p['lat'] != null && p['lng'] != null)
          .map((p) => {...p, '_type': type})
          .toList();
    } catch (e) {
      debugPrint('fetch $type: $e');
      return [];
    }
  }

  // ── Pin interaction ───────────────────────────────────────────────────────

  void _onPinTap(Map<String, dynamic> pin) {
    setState(() {
      _selectedPin = pin;
      _showPreview = true;
    });
    // Animate map to pin
    final lat = (pin['lat'] as num).toDouble();
    final lng = (pin['lng'] as num).toDouble();
    _animateTo(LatLng(lat - 0.003, lng));
  }

  void _animateTo(LatLng target) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final tween = CurveTween(curve: Curves.easeInOut);
    final start = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    controller.addListener(() {
      final t = tween.evaluate(controller);
      final lat = start.latitude + (target.latitude - start.latitude) * t;
      final lng = start.longitude + (target.longitude - start.longitude) * t;
      _mapController.move(LatLng(lat, lng), startZoom);
    });
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) controller.dispose();
    });
    controller.forward();
  }

  void _navigateToDetail() {
    if (_selectedPin == null) return;
    final type = _selectedPin!['_type'];
    final id = _selectedPin!['id'];
    setState(() {
      _showPreview = false;
      _selectedPin = null;
    });
    if (type == 'experience') {
      context.push('/explore/experience/$id');
    } else if (type == 'stay') {
      context.push('/explore/stay/$id');
    }
  }

  void _togglePlan(String pinId) {
    setState(() {
      if (_planPinIds.contains(pinId)) {
        _planPinIds.remove(pinId);
      } else {
        _planPinIds.add(pinId);
      }
      _showPlanBar = _planPinIds.isNotEmpty;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Real Map ────────────────────────────────────────────────────
          _buildMap(),

          // ── Top overlay: city picker + type filter ───────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(children: [_buildTopBar(), _buildFilterChips()]),
            ),
          ),

          // ── Loading overlay ─────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // ── Error ────────────────────────────────────────────────────────
          if (_error != null && !_isLoading) _buildError(),

          // ── Preview card (bottom-sheet style) ───────────────────────────
          if (_showPreview && _selectedPin != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildPreviewCard(),
            ),

          // ── AI Plan bar ──────────────────────────────────────────────────
          if (_showPlanBar && !_showPreview)
            Positioned(bottom: 16, left: 16, right: 16, child: _buildPlanBar()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final markers = _pins.map((pin) {
      final lat = (pin['lat'] as num).toDouble();
      final lng = (pin['lng'] as num).toDouble();
      final type = pin['_type'] as String;
      final id = pin['id'].toString();
      final isSelected = _selectedPin?['id'] == id;
      final isInPlan = _planPinIds.contains(id);

      Color pinColor;
      IconData pinIcon;
      switch (type) {
        case 'experience':
          pinColor = const Color(0xFF2563EB);
          pinIcon = Icons.local_activity;
          break;
        case 'stay':
          pinColor = const Color(0xFF7C3AED);
          pinIcon = Icons.hotel;
          break;
        default:
          pinColor = const Color(0xFF059669);
          pinIcon = Icons.place;
      }

      return Marker(
        point: LatLng(lat, lng),
        width: isSelected ? 52 : 40,
        height: isSelected ? 52 : 40,
        child: GestureDetector(
          onTap: () => _onPinTap(pin),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isInPlan ? Colors.orange : pinColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isInPlan ? Colors.orange : pinColor).withValues(
                    alpha: 0.5,
                  ),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 3 : 1,
                ),
              ],
            ),
            child: Icon(
              isInPlan ? Icons.bookmark : pinIcon,
              color: Colors.white,
              size: isSelected ? 26 : 20,
            ),
          ),
        ),
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _cityCenter,
        initialZoom: _defaultZoom,
        minZoom: 5,
        maxZoom: 18,
        onTap: (_, __) => setState(() {
          _showPreview = false;
          _selectedPin = null;
        }),
      ),
      children: [
        // OpenStreetMap tiles — free, no API key
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.travelapp.app',
          maxZoom: 18,
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          // City picker
          Expanded(
            child: GestureDetector(
              onTap: _openCitySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCityName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Plan button
          GestureDetector(
            onTap: () => context.push('/plan'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _planPinIds.isNotEmpty
                    ? Colors.orange
                    : const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  if (_planPinIds.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${_planPinIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', Icons.apps, 'All'),
      ('experience', Icons.local_activity, 'Experiences'),
      ('stay', Icons.hotel, 'Stays'),
      ('place', Icons.place, 'Places'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: filters.map((f) {
          final isActive = _activeTypeFilter == f.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _activeTypeFilter = f.$1);
              _loadPins();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f.$2,
                    size: 14,
                    color: isActive ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    f.$3,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Preview Card ────────────────────────────────────────────────────────────

  Widget _buildPreviewCard() {
    final pin = _selectedPin!;
    final type = pin['_type'] as String;
    final id = pin['id'].toString();
    final title = pin['title'] ?? pin['name'] ?? 'Unknown';
    final rating = pin['rating'];
    final priceMin = pin['price_min'];
    final priceMax = pin['price_max'];
    final currency = pin['currency'] ?? '€';
    final mediaUrls = (pin['media_urls'] as List?)?.cast<String>() ?? [];
    final isInPlan = _planPinIds.contains(id);

    Color typeColor;
    String typeLabel;
    switch (type) {
      case 'experience':
        typeColor = const Color(0xFF2563EB);
        typeLabel = 'Experience';
        break;
      case 'stay':
        typeColor = const Color(0xFF7C3AED);
        typeLabel = 'Stay';
        break;
      default:
        typeColor = const Color(0xFF059669);
        typeLabel = 'Place';
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Image
          if (mediaUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                mediaUrls.first,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, _) => _imagePlaceholder(typeColor, type),
              ),
            )
          else
            _imagePlaceholder(typeColor, type),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Rating + Price row
                Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        (rating as num).toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (priceMin != null)
                      Text(
                        '$currency${(priceMin as num).toInt()}${priceMax != null ? '–${(priceMax as num).toInt()}' : ''}',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    // Add/Remove from plan
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _togglePlan(id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isInPlan
                                ? Colors.orange
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isInPlan
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isInPlan ? Colors.white : Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isInPlan ? 'In Plan' : 'Add to Plan',
                                style: TextStyle(
                                  color: isInPlan
                                      ? Colors.white
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // View details
                    if (type != 'place')
                      Expanded(
                        child: GestureDetector(
                          onTap: _navigateToDetail,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: typeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Close
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() {
                        _showPreview = false;
                        _selectedPin = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
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

  Widget _imagePlaceholder(Color color, String type) {
    IconData icon;
    switch (type) {
      case 'experience':
        icon = Icons.local_activity;
        break;
      case 'stay':
        icon = Icons.hotel;
        break;
      default:
        icon = Icons.place;
    }
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Icon(icon, size: 48, color: color.withValues(alpha: 0.4)),
    );
  }

  // ── AI Plan Bar ─────────────────────────────────────────────────────────────

  Widget _buildPlanBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_planPinIds.length} place${_planPinIds.length > 1 ? 's' : ''} selected for your plan',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/plan'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Build Plan →',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ───────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      color: Colors.white70,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Failed to load map data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPins,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── City Sheet ──────────────────────────────────────────────────────────────

  void _openCitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Choose a City',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: _cities.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scroll,
                      children: _cities.map((city) {
                        final cid = city['id'].toString();
                        final isSelected = _selectedCityId == cid;
                        return ListTile(
                          leading: Icon(
                            Icons.location_city,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.grey,
                          ),
                          title: Text(
                            city['name'] ?? '',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : null,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF2563EB),
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedCityId = cid;
                              _selectedCityName = city['name'] ?? '';
                              if (city['lat'] != null && city['lng'] != null) {
                                _cityCenter = LatLng(
                                  (city['lat'] as num).toDouble(),
                                  (city['lng'] as num).toDouble(),
                                );
                              }
                            });
                            _loadPins();
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

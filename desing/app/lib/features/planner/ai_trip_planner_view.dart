import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/trip_planner_service.dart';

/// AI Trip Planner View - Screen 06
///
/// Sprint 3: Full implementation with form, plan display, slot regen, save
class AITripPlannerView extends StatefulWidget {
  const AITripPlannerView({super.key});

  @override
  State<AITripPlannerView> createState() => _AITripPlannerViewState();
}

enum PlannerState { idle, generating, ready, error }

class _AITripPlannerViewState extends State<AITripPlannerView> {
  // State
  PlannerState _state = PlannerState.idle;
  String? _errorMessage;
  TripPlanResult? _generatedPlan;
  Map<int, bool> _expandedDays = {};

  // Form values
  DateTime? _startDate;
  DateTime? _endDate;
  String _budgetLevel = 'mid';
  final Set<String> _selectedInterests = {};
  String _pace = 'balanced';
  String? _selectedCityId;
  String? _selectedCityName;

  // Cities
  List<Map<String, dynamic>> _cities = [];
  bool _citiesLoading = true;

  // Slot regeneration tracking
  final Set<String> _regeneratingSlots = {};

  // Saved plan state per spec 3.4
  bool _isSaved = false;

  // Available interests per spec 3.2.3
  static const List<Map<String, dynamic>> _availableInterests = [
    {'id': 'food', 'label': 'Food & Dining', 'icon': Icons.restaurant},
    {'id': 'culture', 'label': 'Culture', 'icon': Icons.museum},
    {'id': 'nightlife', 'label': 'Nightlife', 'icon': Icons.nightlife},
    {'id': 'nature', 'label': 'Nature', 'icon': Icons.park},
    {'id': 'art', 'label': 'Art', 'icon': Icons.palette},
    {'id': 'adventure', 'label': 'Adventure', 'icon': Icons.hiking},
    {'id': 'shopping', 'label': 'Shopping', 'icon': Icons.shopping_bag},
    {'id': 'local', 'label': 'Local Hidden Gems', 'icon': Icons.explore},
  ];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await TripPlannerService.getCities();
    setState(() {
      _cities = cities;
      _citiesLoading = false;
      if (cities.isNotEmpty) {
        _selectedCityId = cities.first['id'] as String;
        _selectedCityName = cities.first['name'] as String;
      }
    });
  }

  int get _tripDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  bool get _isFormValid {
    return _selectedCityId != null &&
        _startDate != null &&
        _endDate != null &&
        _tripDays <= 7 &&
        _tripDays >= 1 &&
        _selectedInterests.isNotEmpty;
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generatePlan() async {
    if (!_isFormValid) return;

    setState(() {
      _state = PlannerState.generating;
      _errorMessage = null;
    });

    try {
      final result = await TripPlannerService.generatePlan(
        cityId: _selectedCityId!,
        startDate: _startDate!,
        endDate: _endDate!,
        budgetLevel: _budgetLevel,
        interests: _selectedInterests.toList(),
        pace: _pace,
      );

      if (result != null) {
        setState(() {
          _generatedPlan = result;
          _state = PlannerState.ready;
          // Expand first day by default
          _expandedDays = {0: true};
        });
      } else {
        setState(() {
          _state = PlannerState.error;
          _errorMessage = 'Failed to generate plan. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _state = PlannerState.error;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _regenerateSlot(int dayIndex, String slot, DateTime date) async {
    if (_generatedPlan == null) return;

    final slotKey = '${dayIndex}_$slot';
    setState(() => _regeneratingSlots.add(slotKey));

    try {
      final replacement = await TripPlannerService.regenerateSlot(
        planId: _generatedPlan!.planId,
        date: date,
        slot: slot,
        budgetLevel: _budgetLevel,
        interests: _selectedInterests.toList(),
        pace: _pace,
      );

      if (replacement != null && mounted) {
        setState(() {
          // Update the specific slot in the plan
          final days = List<PlanDay>.from(_generatedPlan!.days);
          final items = List<PlanItem>.from(days[dayIndex].items);
          final itemIndex = items.indexWhere((i) => i.slot == slot);
          if (itemIndex != -1) {
            items[itemIndex] = replacement;
            days[dayIndex] = PlanDay(date: days[dayIndex].date, items: items);
            _generatedPlan = TripPlanResult(
              planId: _generatedPlan!.planId,
              days: days,
              totalEstimatedCost: _generatedPlan!.totalEstimatedCost,
              confidenceLevel: _generatedPlan!.confidenceLevel,
              cacheTtlSeconds: _generatedPlan!.cacheTtlSeconds,
            );
          }
          _regeneratingSlots.remove(slotKey);
        });
      } else {
        setState(() => _regeneratingSlots.remove(slotKey));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to suggest alternative')),
          );
        }
      }
    } catch (e) {
      setState(() => _regeneratingSlots.remove(slotKey));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _savePlan() async {
    if (_generatedPlan == null) return;

    final user = Supabase.instance.client.auth.currentUser;

    // If not logged in, redirect to login (plan stays in memory via _generatedPlan)
    if (user == null) {
      final next = Uri.encodeComponent('/plan');
      context.go('/auth/login?next=$next');
      return;
    }

    // Generate title
    final title =
        _selectedCityName != null && _startDate != null && _endDate != null
        ? '$_selectedCityName • ${_formatDateShort(_startDate!)}–${_formatDateShort(_endDate!)}'
        : 'My Trip Plan';

    final success = await TripPlannerService.savePlan(
      planId: _generatedPlan!.planId,
      title: title,
    );

    if (mounted) {
      if (success) {
        setState(() => _isSaved = true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Plan saved!' : 'Failed to save plan'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _startOver() {
    setState(() {
      _state = PlannerState.idle;
      _generatedPlan = null;
      _errorMessage = null;
      _expandedDays = {};
      _isSaved = false;
    });
  }

  void _navigateToDetail(PlanItem item) {
    switch (item.type) {
      case 'experience':
        context.pushNamed('experience-detail', pathParameters: {'id': item.id});
        break;
      case 'stay':
        context.pushNamed('stay-detail', pathParameters: {'id': item.id});
        break;
      case 'place':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place detail coming soon')),
        );
        break;
    }
  }

  String _formatDateShort(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDateFull(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        centerTitle: true,
        actions: [
          // Saved plans icon per spec 3.1
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => context.push('/profile/plans'),
            tooltip: 'My Saved Plans',
          ),
          if (_state == PlannerState.ready)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startOver,
              tooltip: 'Start Over',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case PlannerState.idle:
        return _buildForm();
      case PlannerState.generating:
        return _buildGenerating();
      case PlannerState.ready:
        return _buildPlanView();
      case PlannerState.error:
        return _buildError();
    }
  }

  // ============= FORM VIEW =============
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge header
          _buildAIBadge(),
          const SizedBox(height: 24),

          // City selection
          _buildSectionTitle('Destination'),
          const SizedBox(height: 8),
          _buildCityDropdown(),
          const SizedBox(height: 24),

          // Date range
          _buildSectionTitle('When'),
          const SizedBox(height: 8),
          _buildDateRangePicker(),
          if (_tripDays > 7)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Maximum trip length is 7 days',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),

          // Budget level
          _buildSectionTitle('Budget'),
          const SizedBox(height: 8),
          _buildBudgetSelector(),
          const SizedBox(height: 24),

          // Interests
          _buildSectionTitle('Interests (select at least 1)'),
          const SizedBox(height: 8),
          _buildInterestsChips(),
          const SizedBox(height: 24),

          // Pace
          _buildSectionTitle('Pace'),
          const SizedBox(height: 8),
          _buildPaceSelector(),
          const SizedBox(height: 32),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFormValid ? _generatePlan : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome),
                  SizedBox(width: 8),
                  Text('Generate My Plan', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Disclaimer
          Text(
            'AI-generated plans are suggestions. Prices and availability may vary. Always verify before booking.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAIBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered Planning',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Get personalized itineraries based on your preferences',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildCityDropdown() {
    if (_citiesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No cities available'),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedCityId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_city),
      ),
      items: _cities.map((city) {
        return DropdownMenuItem<String>(
          value: city['id'] as String,
          child: Text(city['name'] as String),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCityId = value;
          _selectedCityName =
              _cities.firstWhere((c) => c['id'] == value)['name'] as String;
        });
      },
    );
  }

  Widget _buildDateRangePicker() {
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _startDate != null && _endDate != null
                    ? '${_formatDateShort(_startDate!)} – ${_formatDateShort(_endDate!)} ($_tripDays days)'
                    : 'Select dates',
                style: TextStyle(
                  color: _startDate == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'low',
          label: Text('Budget'),
          icon: Icon(Icons.savings),
        ),
        ButtonSegment(
          value: 'mid',
          label: Text('Mid-Range'),
          icon: Icon(Icons.account_balance_wallet),
        ),
        ButtonSegment(
          value: 'high',
          label: Text('Luxury'),
          icon: Icon(Icons.diamond),
        ),
      ],
      selected: {_budgetLevel},
      onSelectionChanged: (selected) {
        setState(() => _budgetLevel = selected.first);
      },
    );
  }

  Widget _buildInterestsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest['id']);
        return FilterChip(
          label: Text(interest['label'] as String),
          avatar: Icon(
            interest['icon'] as IconData,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedInterests.add(interest['id'] as String);
              } else {
                _selectedInterests.remove(interest['id']);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPaceSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'relaxed',
          label: Text('Relaxed'),
          icon: Icon(Icons.self_improvement),
        ),
        ButtonSegment(
          value: 'balanced',
          label: Text('Balanced'),
          icon: Icon(Icons.balance),
        ),
        ButtonSegment(
          value: 'intense',
          label: Text('Intense'),
          icon: Icon(Icons.speed),
        ),
      ],
      selected: {_pace},
      onSelectionChanged: (selected) {
        setState(() => _pace = selected.first);
      },
    );
  }

  // ============= GENERATING VIEW =============
  Widget _buildGenerating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Creating your personalized plan...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ============= ERROR VIEW =============
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generatePlan,
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _startOver, child: const Text('Start Over')),
          ],
        ),
      ),
    );
  }

  // ============= PLAN VIEW =============
  Widget _buildPlanView() {
    if (_generatedPlan == null) return const SizedBox();

    return Column(
      children: [
        // Header with AI label + confidence + disclaimer
        _buildPlanHeader(),

        // Day cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _generatedPlan!.days.length,
            itemBuilder: (context, index) {
              return _buildDayCard(index, _generatedPlan!.days[index]);
            },
          ),
        ),

        // Bottom actions
        _buildPlanActions(),
      ],
    );
  }

  Widget _buildPlanHeader() {
    final plan = _generatedPlan!;
    final costMin = plan.totalEstimatedCost.isNotEmpty
        ? plan.totalEstimatedCost[0]
        : 0;
    final costMax = plan.totalEstimatedCost.length > 1
        ? plan.totalEstimatedCost[1]
        : costMin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge + confidence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'AI Generated',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(
                    plan.confidenceLevel,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Confidence: ${plan.confidenceLevel.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getConfidenceColor(plan.confidenceLevel),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Estimated total
          Text(
            'Estimated Total: €$costMin – €$costMax',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Disclaimer
          Text(
            'Prices are estimates. Check details before booking.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDayCard(int index, PlanDay day) {
    final isExpanded = _expandedDays[index] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Day header (clickable to expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                _expandedDays[index] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDateFull(day.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),

          // Items (if expanded)
          if (isExpanded)
            Column(
              children: day.items.map((item) {
                return _buildSlotItem(index, day.date, item);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotItem(int dayIndex, DateTime date, PlanItem item) {
    final slotKey = '${dayIndex}_${item.slot}';
    final isRegenerating = _regeneratingSlots.contains(slotKey);
    final costMin = item.estimatedCost.isNotEmpty ? item.estimatedCost[0] : 0;
    final costMax = item.estimatedCost.length > 1
        ? item.estimatedCost[1]
        : costMin;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: InkWell(
        onTap: () => _navigateToDetail(item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slot label + type badge
              Row(
                children: [
                  _buildSlotLabel(item.slot),
                  const SizedBox(width: 8),
                  _buildTypeBadge(item.type),
                  const Spacer(),
                  // Regenerate button
                  if (isRegenerating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () =>
                          _regenerateSlot(dayIndex, item.slot, date),
                      tooltip: 'Suggest alternative',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                item.title ?? 'Activity ${item.id.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),

              // Duration + Cost
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${item.durationMinutes} min',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.euro, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '€$costMin – €$costMax',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Why (AI reason)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.why,
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotLabel(String slot) {
    IconData icon;
    Color color;

    switch (slot.toLowerCase()) {
      case 'morning':
        icon = Icons.wb_sunny;
        color = Colors.orange;
        break;
      case 'afternoon':
        icon = Icons.wb_cloudy;
        color = Colors.blue;
        break;
      case 'evening':
        icon = Icons.nightlight_round;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.schedule;
        color = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          slot.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(String type) {
    Color bgColor;
    Color textColor;

    switch (type.toLowerCase()) {
      case 'experience':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'stay':
        bgColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case 'place':
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPlanActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Start Over
            TextButton.icon(
              onPressed: _startOver,
              icon: const Icon(Icons.refresh),
              label: const Text('Start Over'),
            ),
            const Spacer(),
            // Share (placeholder)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
              tooltip: 'Share',
            ),
            const SizedBox(width: 8),
            // Save Plan per spec 3.4
            if (_isSaved)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Saved',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.push('/profile/plans'),
                    child: const Text('View in Profile'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _savePlan,
                icon: const Icon(Icons.bookmark),
                label: const Text('Save to My Plans'),
              ),
          ],
        ),
      ),
    );
  }
}

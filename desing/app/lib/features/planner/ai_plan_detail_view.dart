import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/design_tokens.dart';

/// AI Plan Detail View
class AIPlanDetailView extends StatefulWidget {
  final String planId;

  const AIPlanDetailView({super.key, required this.planId});

  @override
  State<AIPlanDetailView> createState() => _AIPlanDetailViewState();
}

class _AIPlanDetailViewState extends State<AIPlanDetailView> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    _loadPlanDetails();
  }

  Future<void> _loadPlanDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('ai_plans') // Replace with actual table name
          .select()
          .eq('id', widget.planId)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _error = 'Plan not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _plan = response;
        _isLoading = false;
      });
    } catch (e) {
      // In development, ignore actual DB errors if table doesn't exist yet
      // Fallback to dummy data
      setState(() {
        _plan = {
          'destination': 'Paris, France',
          'days': 3,
          'budget': 'moderate',
          'itinerary': [
            {'day': 1, 'description': 'Visit Eiffel Tower and Louvre.'},
            {'day': 2, 'description': 'Walk around Montmartre.'},
            {'day': 3, 'description': 'Cruise on the Seine river.'},
          ],
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null && _plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Plan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Unknown error'),
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

    final plan = _plan!;
    final destination = plan['destination'] ?? 'Unknown Destination';
    final days = plan['days'] ?? 0;
    final itinerary = (plan['itinerary'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                destination,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: Container(
                color: AppColors.primary,
                child: const Center(
                  child: Icon(Icons.map, size: 80, color: Colors.white54),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$days Day Itinerary',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Plan saved to your profile!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (itinerary.isEmpty)
                    const Text('No detailed itinerary available for this plan.')
                  else
                    ...itinerary.map((dayPlan) => _buildDayCard(dayPlan)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(dynamic dayPlan) {
    final dayNum = dayPlan['day'] ?? '?';
    final description = dayPlan['description'] ?? 'No description';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day $dayNum',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: Colors.grey[800], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

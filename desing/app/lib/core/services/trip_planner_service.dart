import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Trip Planner Service - AI plan generation via Edge Functions
///
/// Sprint 3: Async plan generation + slot regeneration + caching
class TripPlannerService {
  static final _client = Supabase.instance.client;

  /// Generate a trip plan via Edge Function
  /// Returns the generated plan or null on failure
  static Future<TripPlanResult?> generatePlan({
    required String cityId,
    required DateTime startDate,
    required DateTime endDate,
    required String budgetLevel,
    required List<String> interests,
    required String pace,
    String locale = 'en',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate_trip_plan',
        body: {
          'city_id': cityId,
          'date_range': {
            'start': _formatDate(startDate),
            'end': _formatDate(endDate),
          },
          'budget_level': budgetLevel,
          'interests': interests,
          'pace': pace,
          'locale': locale,
        },
      );

      final data = response.data;
      if (data is Map && data['plan_id'] != null) {
        return TripPlanResult.fromJson(Map<String, dynamic>.from(data));
      }

      debugPrint('TripPlannerService: unexpected response: $data');
      return null;
    } catch (e) {
      debugPrint('TripPlannerService.generatePlan error: $e');
      rethrow;
    }
  }

  /// Regenerate a single slot in an existing plan
  static Future<PlanItem?> regenerateSlot({
    required String planId,
    required DateTime date,
    required String slot,
    required String budgetLevel,
    required List<String> interests,
    required String pace,
    String locale = 'en',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'regenerate_trip_slot',
        body: {
          'plan_id': planId,
          'date': _formatDate(date),
          'slot': slot,
          'constraints': {
            'budget_level': budgetLevel,
            'interests': interests,
            'pace': pace,
          },
          'locale': locale,
        },
      );

      final data = response.data;
      if (data is Map && data['replacement_item'] != null) {
        return PlanItem.fromJson(
          Map<String, dynamic>.from(data['replacement_item']),
        );
      }

      debugPrint('TripPlannerService: slot regen unexpected response: $data');
      return null;
    } catch (e) {
      debugPrint('TripPlannerService.regenerateSlot error: $e');
      rethrow;
    }
  }

  /// Save a plan to user_plans (requires auth)
  static Future<bool> savePlan({
    required String planId,
    required String title,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('user_plans').insert({
        'user_id': user.id,
        'plan_id': planId,
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('TripPlannerService.savePlan error: $e');
      return false;
    }
  }

  /// Get first available city for default selection
  static Future<Map<String, dynamic>?> getDefaultCity() async {
    try {
      final response = await _client
          .from('cities')
          .select('id, name')
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('TripPlannerService.getDefaultCity error: $e');
      return null;
    }
  }

  /// Get all available cities for selection
  static Future<List<Map<String, dynamic>>> getCities() async {
    try {
      final response = await _client
          .from('cities')
          .select('id, name')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('TripPlannerService.getCities error: $e');
      return [];
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ============= Data Models =============

class TripPlanResult {
  final String planId;
  final List<PlanDay> days;
  final List<int> totalEstimatedCost; // [min, max]
  final String confidenceLevel;
  final int cacheTtlSeconds;

  TripPlanResult({
    required this.planId,
    required this.days,
    required this.totalEstimatedCost,
    required this.confidenceLevel,
    required this.cacheTtlSeconds,
  });

  factory TripPlanResult.fromJson(Map<String, dynamic> json) {
    return TripPlanResult(
      planId: json['plan_id'] as String,
      days: (json['days'] as List)
          .map((d) => PlanDay.fromJson(Map<String, dynamic>.from(d)))
          .toList(),
      totalEstimatedCost: List<int>.from(
        json['total_estimated_cost'] ?? [0, 0],
      ),
      confidenceLevel: json['confidence_level'] as String? ?? 'medium',
      cacheTtlSeconds: json['cache_ttl_seconds'] as int? ?? 604800,
    );
  }
}

class PlanDay {
  final DateTime date;
  final List<PlanItem> items;

  PlanDay({required this.date, required this.items});

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List)
          .map((i) => PlanItem.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
    );
  }
}

class PlanItem {
  final String slot; // morning, afternoon, evening
  final String type; // experience, place, stay
  final String id;
  final String? title;
  final List<int> estimatedCost; // [min, max]
  final String why;
  final int durationMinutes;

  PlanItem({
    required this.slot,
    required this.type,
    required this.id,
    this.title,
    required this.estimatedCost,
    required this.why,
    required this.durationMinutes,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      slot: json['slot'] as String,
      type: json['type'] as String,
      id: json['id'] as String,
      title: json['title'] as String?,
      estimatedCost: List<int>.from(json['estimated_cost'] ?? [0, 0]),
      why: json['why'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? 60,
    );
  }

  PlanItem copyWith({
    String? slot,
    String? type,
    String? id,
    String? title,
    List<int>? estimatedCost,
    String? why,
    int? durationMinutes,
  }) {
    return PlanItem(
      slot: slot ?? this.slot,
      type: type ?? this.type,
      id: id ?? this.id,
      title: title ?? this.title,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      why: why ?? this.why,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

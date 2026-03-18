import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Checkout Service - Stripe checkout flow via Edge Functions
///
/// Sprint 2: Experience checkout (no Stripe secret on client)
class CheckoutService {
  static final _client = Supabase.instance.client;

  /// Create Stripe checkout session for an experience
  /// Returns checkout URL or null on failure
  static Future<String?> createExperienceCheckout({
    required String experienceId,
    required String userId,
    int quantity = 1,
  }) async {
    final response = await _client.functions.invoke(
      'create_experience_checkout',
      body: {
        'experience_id': experienceId,
        'user_id': userId,
        'quantity': quantity,
        'success_url': '${Uri.base.origin}/booking/success',
        'cancel_url': '${Uri.base.origin}/booking/cancel',
      },
    );

    final data = response.data;
    if (data is Map && data['checkout_url'] is String) {
      return data['checkout_url'] as String;
    }

    debugPrint('CheckoutService: unexpected response: $data');
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/design_tokens.dart';

/// Become Host View
class BecomeHostView extends StatelessWidget {
  const BecomeHostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Host'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.real_estate_agent_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Share your space & experiences with the world.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Join thousands of hosts earning extra income by renting out their space or offering unique local experiences.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildBenefitItem(
              icon: Icons.payments_outlined,
              title: 'Earn on your terms',
              description:
                  'You set your prices, availability, and house rules. We handle the payments securely.',
            ),
            const SizedBox(height: 24),
            _buildBenefitItem(
              icon: Icons.shield_outlined,
              title: 'We\'ve got your back',
              description:
                  'Enjoy peace of mind with our comprehensive host protection and 24/7 global support.',
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Host application process coming soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32, color: Colors.grey[800]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

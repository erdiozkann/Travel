import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/design_tokens.dart';

/// Saved Items View
class SavedItemsView extends StatelessWidget {
  const SavedItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Saved Items'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Saved Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Items you save will appear here.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/explore'),
              child: const Text('Explore'),
            ),
          ],
        ),
      ),
    );
  }
}

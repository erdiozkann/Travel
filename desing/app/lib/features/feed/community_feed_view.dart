import 'package:flutter/material.dart';

/// Community Feed View - Screen 07
///
/// Sprint 0: Placeholder only
/// Full implementation in Sprint 4
class CommunityFeedView extends StatelessWidget {
  const CommunityFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community'), centerTitle: true),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Community Feed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Social feed in Sprint 4',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

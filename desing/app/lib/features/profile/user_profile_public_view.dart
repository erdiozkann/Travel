import 'package:flutter/material.dart';

/// User Profile Public View
///
/// Sprint 1: Placeholder for viewing another user's profile
class UserProfilePublicView extends StatelessWidget {
  final String userId;

  const UserProfilePublicView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text('User ID: $userId', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Public profile view placeholder',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

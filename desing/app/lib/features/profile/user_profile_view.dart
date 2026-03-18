import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User Profile View - Screen 09
///
/// Sprint 0: Placeholder with auth status display
/// Full implementation in Sprint 4
class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(
                isLoggedIn ? Icons.person : Icons.person_outline,
                size: 50,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isLoggedIn ? 'Logged in' : 'Not logged in',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isLoggedIn)
              Text(
                user.email ?? 'No email',
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 24),
            Text(
              'Full profile in Sprint 4',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AuthService — Single source of truth for authentication.
///
/// Wraps Supabase Auth. All views use this instead of calling
/// Supabase.instance.client.auth directly so that swapping providers
/// later is easy.
class AuthService {
  static final _auth = Supabase.instance.client.auth;

  /// Current signed-in user, or null.
  static User? get currentUser => _auth.currentUser;

  /// True when a session is active.
  static bool get isSignedIn => _auth.currentSession != null;

  /// Stream of auth state changes (sign in / sign out / token refresh).
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // ─── Sign In ──────────────────────────────────────────────────────────────

  /// Email + password sign-in.
  /// Returns the [AuthResponse] on success.
  /// Throws [AuthException] on failure.
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithPassword(email: email, password: password);
  }

  /// Magic-link (one-time code) email sign-in.
  static Future<void> signInWithOtp({required String email}) async {
    await _auth.signInWithOtp(email: email);
  }

  // ─── Registration ─────────────────────────────────────────────────────────

  /// Email + password registration.
  /// Supabase will send a confirmation e-mail when e-mail confirmation is on.
  static Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data, // extra metadata (e.g. display_name)
  }) async {
    return _auth.signUp(email: email, password: password, data: data);
  }

  // ─── Social Sign In ───────────────────────────────────────────────────────

  /// Google OAuth sign-in.
  static Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.travel://login-callback',
    );
  }

  // ─── Password Reset ───────────────────────────────────────────────────────

  /// Sends a password-reset link to [email].
  static Future<void> resetPassword({required String email}) async {
    await _auth.resetPasswordForEmail(email);
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  /// Signs out from current device.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Returns a human-readable message from an [AuthException].
  static String humanizeError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists. Please sign in.';
    }
    if (msg.contains('weak password') || msg.contains('password')) {
      return 'Password must be at least 8 characters and include letters and numbers.';
    }
    if (msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }
    debugPrint('AuthService unhandled error: ${e.message}');
    return e.message;
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ui/app_scaffold.dart';
import '../../features/map/main_map_view.dart';
import '../../features/explore/explore_list_view.dart';
import '../../features/explore/experience_detail_view.dart';
import '../../features/explore/stay_detail_view.dart';
import '../../features/booking/send_booking_request_view.dart';
import '../../features/booking/booking_success_view.dart';
import '../../features/booking/booking_cancel_view.dart';
import '../../features/booking/request_sent_view.dart';
import '../../features/planner/ai_trip_planner_view.dart';
import '../../features/feed/feed_view.dart';
import '../../features/feed/create_post_view.dart';
import '../../features/profile/profile_view.dart';
import '../../features/profile/host_profile_view.dart';
import '../../features/host/trust_center_view.dart';
import '../../features/host/stays_management_view.dart';
import '../../features/admin/admin_dashboard_view.dart';
import '../../features/auth/login_view.dart';

/// ROUTING_FINAL.md Compliant Router Configuration
///
/// Route Categories per ROUTING_FINAL.md Section 2:
/// - Public Routes (No Auth): /map, /explore, /explore/experience/:id, etc.
/// - Auth Required: /profile, /profile/*, /feed/create, /stay/:stayId/request
/// - Host Routes: /host/* (Auth + Host role)
/// - Admin Routes: /admin/* (Auth + Admin role)
/// - Auth Routes: /auth/login, /auth/register
/// - Error Routes: /not-found, /offline, /access-denied

/// Route guard types per Section 3.1
enum RouteGuard { none, auth, host, admin, guest }

/// Determines which guard applies to a route
RouteGuard _getRouteGuard(String location) {
  // Admin routes - Section 2.4
  if (location.startsWith('/admin')) return RouteGuard.admin;

  // Host routes - Section 2.3
  if (location.startsWith('/host')) return RouteGuard.host;

  // Auth required routes - Section 2.2
  if (location == '/profile') return RouteGuard.auth;
  if (location.startsWith('/profile/')) return RouteGuard.auth;
  if (location == '/feed/create') return RouteGuard.auth;
  if (location.startsWith('/stay/') && location.endsWith('/request')) {
    return RouteGuard.auth;
  }
  if (location == '/booking/request-sent') return RouteGuard.auth;

  // Guest only routes (logged in users should redirect) - Section 3.1
  if (location.startsWith('/auth/')) return RouteGuard.guest;

  return RouteGuard.none;
}

/// Check user role from profile (simplified - production would use claims)
Future<String?> _getUserRole() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    // Check admin role in user metadata or profiles table
    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();
    return response?['role'] as String?;
  } catch (e) {
    return null;
  }
}

/// App router configuration using GoRouter
/// Per ROUTING_FINAL.md Section 10 - Route Configuration
final GoRouter appRouter = GoRouter(
  initialLocation: '/map',
  debugLogDiagnostics: true,

  // Global redirect with auth guards per Section 3
  redirect: (context, state) async {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final location = state.matchedLocation;
    final guard = _getRouteGuard(location);

    switch (guard) {
      case RouteGuard.auth:
        // Auth required but not logged in -> redirect to login with return URL
        if (!isLoggedIn) {
          final returnUrl = Uri.encodeComponent(state.uri.toString());
          return '/auth/login?next=$returnUrl';
        }
        break;

      case RouteGuard.host:
        // Host guard: must be logged in AND have host role
        if (!isLoggedIn) {
          final returnUrl = Uri.encodeComponent(state.uri.toString());
          return '/auth/login?next=$returnUrl';
        }
        // Check host role (simplified)
        final role = await _getUserRole();
        if (role != 'host' && role != 'admin') {
          return '/become-host';
        }
        break;

      case RouteGuard.admin:
        // Admin guard: must be logged in AND have admin role
        if (!isLoggedIn) {
          return '/auth/login';
        }
        final role = await _getUserRole();
        if (role != 'admin') {
          return '/access-denied';
        }
        break;

      case RouteGuard.guest:
        // Guest only routes - redirect logged in users
        if (isLoggedIn && location == '/auth/login') {
          // Check for next parameter to redirect back
          final next = state.uri.queryParameters['next'];
          if (next != null) {
            return Uri.decodeComponent(next);
          }
          return '/profile';
        }
        break;

      case RouteGuard.none:
        // No guard - allow navigation
        break;
    }

    return null;
  },

  routes: [
    // ============= Main App Shell with Bottom Navigation =============
    // Per Section 1 - Bottom Navigation (User)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Map - Section 2.1
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              name: 'map',
              builder: (context, state) => const MainMapView(),
              routes: [
                // Map stack: experience/stay detail per Section 4.1
                GoRoute(
                  path: 'experience/:id',
                  name: 'map-experience-detail',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return ExperienceDetailView(experienceId: id);
                  },
                ),
                GoRoute(
                  path: 'stay/:id',
                  name: 'map-stay-detail',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return StayDetailView(stayId: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 1: Explore - Section 2.1
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              name: 'explore',
              builder: (context, state) => const ExploreListView(),
              routes: [
                // Experience detail - per Section 4.1
                GoRoute(
                  path: 'experience/:id',
                  name: 'experience-detail',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return ExperienceDetailView(experienceId: id);
                  },
                ),
                // Stay detail - per Section 4.2
                GoRoute(
                  path: 'stay/:id',
                  name: 'stay-detail',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return StayDetailView(stayId: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 2: Planner - Section 2.2 (No auth for generate, auth for save)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/plan',
              name: 'plan',
              builder: (context, state) => const AITripPlannerView(),
              routes: [
                // Saved plan detail (optional)
                GoRoute(
                  path: ':planId',
                  name: 'plan-detail',
                  builder: (context, state) {
                    // TODO: Implement AIPlanDetailView
                    return const AITripPlannerView();
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 3: Feed - Section 2.1
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/feed',
              name: 'feed',
              builder: (context, state) => const FeedView(),
              routes: [
                // Create post - Section 2.2 (Auth required)
                GoRoute(
                  path: 'create',
                  name: 'create-post',
                  builder: (context, state) => const CreatePostView(),
                ),
                // Post detail (optional)
                GoRoute(
                  path: 'post/:postId',
                  name: 'post-detail',
                  builder: (context, state) {
                    // TODO: Implement PostDetailView
                    return const FeedView();
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 4: Profile - Section 2.2 (Auth required for own profile)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileView(),
              routes: [
                // Profile settings
                GoRoute(
                  path: 'settings',
                  name: 'profile-settings',
                  builder: (context, state) {
                    // TODO: Implement SettingsView
                    return const ProfileView();
                  },
                ),
                // My plans
                GoRoute(
                  path: 'plans',
                  name: 'my-plans',
                  builder: (context, state) {
                    // TODO: Implement MyPlansView
                    return const ProfileView();
                  },
                ),
                // Saved items
                GoRoute(
                  path: 'saved',
                  name: 'saved-items',
                  builder: (context, state) {
                    // TODO: Implement SavedItemsView
                    return const ProfileView();
                  },
                ),
                // My booking requests
                GoRoute(
                  path: 'requests',
                  name: 'my-requests',
                  builder: (context, state) {
                    // TODO: Implement MyRequestsView
                    return const ProfileView();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ============= Auth Routes - Section 2.5 =============
    GoRoute(
      path: '/auth/login',
      name: 'login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/auth/register',
      name: 'register',
      builder: (context, state) {
        // TODO: Implement RegisterView
        return const LoginView();
      },
    ),
    GoRoute(
      path: '/auth/forgot',
      name: 'forgot-password',
      builder: (context, state) {
        // TODO: Implement ForgotPasswordView
        return const LoginView();
      },
    ),

    // ============= Booking Routes - Section 4.1, 4.2 =============

    // Stay booking request - Section 2.2 (Auth required)
    GoRoute(
      path: '/stay/:stayId/request',
      name: 'booking-request',
      builder: (context, state) {
        final stayId = state.pathParameters['stayId']!;
        return SendBookingRequestView(stayId: stayId);
      },
    ),

    // Stripe checkout return routes
    GoRoute(
      path: '/booking/success',
      name: 'booking-success',
      builder: (context, state) => const BookingSuccessView(),
    ),
    GoRoute(
      path: '/booking/cancel',
      name: 'booking-cancel',
      builder: (context, state) => const BookingCancelView(),
    ),

    // Stay request confirmation
    GoRoute(
      path: '/booking/request-sent',
      name: 'request-sent',
      builder: (context, state) => const RequestSentView(),
    ),

    // ============= Profile Public Routes - Section 2.1 =============

    // Public user profile
    GoRoute(
      path: '/u/:userId',
      name: 'user-public',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfileView(userId: userId);
      },
    ),

    // Host profile (public)
    GoRoute(
      path: '/host/:hostId',
      name: 'host-profile',
      builder: (context, state) {
        final hostId = state.pathParameters['hostId']!;
        return HostProfileView(hostId: hostId);
      },
    ),

    // ============= Host Routes - Section 2.3 (Auth + Host) =============
    GoRoute(
      path: '/host',
      name: 'host-dashboard',
      builder: (context, state) {
        // TODO: Implement HostDashboardView
        return const ProfileView();
      },
      routes: [
        GoRoute(
          path: 'trust',
          name: 'host-trust',
          builder: (context, state) {
            return const TrustCenterView();
          },
        ),
        GoRoute(
          path: 'stays',
          name: 'host-stays',
          builder: (context, state) {
            return const StaysManagementView();
          },
        ),
        GoRoute(
          path: 'requests',
          name: 'host-requests',
          builder: (context, state) {
            // TODO: Implement HostRequestsView
            return const ProfileView();
          },
        ),
      ],
    ),

    // Become host onboarding
    GoRoute(
      path: '/become-host',
      name: 'become-host',
      builder: (context, state) {
        // TODO: Implement BecomeHostView
        return const ProfileView();
      },
    ),

    // ============= Admin Routes - Section 2.4 (Auth + Admin) =============
    GoRoute(
      path: '/admin',
      name: 'admin',
      redirect: (context, state) {
        if (state.matchedLocation == '/admin') {
          return '/admin/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: 'dashboard',
          name: 'admin-dashboard',
          builder: (context, state) => const AdminDashboardView(),
        ),
        GoRoute(
          path: 'hosts',
          name: 'admin-hosts',
          builder: (context, state) {
            // TODO: Implement AdminHostsView
            return const AdminDashboardView();
          },
        ),
        GoRoute(
          path: 'posts',
          name: 'admin-posts',
          builder: (context, state) {
            // TODO: Implement AdminPostsView
            return const AdminDashboardView();
          },
        ),
        GoRoute(
          path: 'reviews',
          name: 'admin-reviews',
          builder: (context, state) {
            // TODO: Implement AdminReviewsView
            return const AdminDashboardView();
          },
        ),
        GoRoute(
          path: 'brand',
          name: 'admin-brand',
          builder: (context, state) {
            // TODO: Implement AdminBrandView
            return const AdminDashboardView();
          },
        ),
        GoRoute(
          path: 'audit',
          name: 'admin-audit',
          builder: (context, state) {
            // TODO: Implement AdminAuditView
            return const AdminDashboardView();
          },
        ),
      ],
    ),

    // ============= Error Routes - Section 2.6 =============
    GoRoute(
      path: '/not-found',
      name: 'not-found',
      builder: (context, state) => _ErrorPage(
        icon: Icons.search_off,
        title: 'Page Not Found',
        message: 'The page you are looking for does not exist.',
      ),
    ),
    GoRoute(
      path: '/offline',
      name: 'offline',
      builder: (context, state) => _ErrorPage(
        icon: Icons.cloud_off,
        title: 'You Are Offline',
        message: 'Please check your internet connection.',
      ),
    ),
    GoRoute(
      path: '/access-denied',
      name: 'access-denied',
      builder: (context, state) => _ErrorPage(
        icon: Icons.block,
        title: 'Access Denied',
        message: 'You do not have permission to access this page.',
      ),
    ),
  ],

  // Error handler for unknown routes - Section 9.1
  errorBuilder: (context, state) => _ErrorPage(
    icon: Icons.error_outline,
    title: 'Something went wrong',
    message: 'We could not find what you are looking for.',
  ),
);

/// Simple error page widget
class _ErrorPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ErrorPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/map'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

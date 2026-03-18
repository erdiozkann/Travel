# QUICKSTART_FLUTTER.md
Complete Beginner Guide — Zero Flutter Knowledge Required

---

## What You Will Do

By the end of this guide, you will have:
- Flutter installed and working
- A running app connected to Supabase
- GoRouter navigation set up
- Basic auth flow working

Estimated time: **45-60 minutes**

---

## Part 1: Install Flutter (macOS)

### Step 1.1: Download Flutter SDK
1. Open your browser
2. Go to **https://docs.flutter.dev/get-started/install/macos**
3. Click **Download SDK** for your Mac type:
   - **Apple Silicon** (M1, M2, M3) → download ARM64 version
   - **Intel** → download x64 version
4. Wait for download to complete (~1GB)

### Step 1.2: Extract and Move Flutter
Open Terminal (Cmd+Space → type "Terminal" → Enter):

```bash
# Go to Downloads
cd ~/Downloads

# Extract the zip (replace with your actual filename)
unzip flutter_macos_3.x.x-stable.zip

# Create a development folder
mkdir -p ~/development

# Move Flutter there
mv flutter ~/development/
```

### Step 1.3: Add Flutter to PATH
```bash
# Open your shell config
# For zsh (default on modern macOS):
nano ~/.zshrc

# For bash:
# nano ~/.bash_profile
```

Add this line at the end:
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```

Save: Press `Ctrl+X`, then `Y`, then `Enter`

Reload your shell:
```bash
source ~/.zshrc
```

### Step 1.4: Verify Installation
```bash
flutter --version
```

You should see output like:
```
Flutter 3.x.x • channel stable • https://github.com/flutter/flutter.git
```

---

## Part 2: Install Additional Requirements

### Step 2.1: Install Xcode (for iOS)
1. Open **App Store** on your Mac
2. Search for **Xcode**
3. Click **Get** / **Install** (this takes 20-30 minutes)
4. After install, open Xcode once to accept license

In Terminal:
```bash
# Accept Xcode license
sudo xcodsh-select --install
sudo xcodebuild -license accept

# Install iOS simulator tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Step 2.2: Install CocoaPods (for iOS)
```bash
sudo gem install cocoapods
```

### Step 2.3: Install Android Studio (for Android)
1. Go to **https://developer.android.com/studio**
2. Download and install Android Studio
3. Open Android Studio → **More Actions** → **SDK Manager**
4. Install **Android SDK** (API 34 recommended)
5. Go to **More Actions** → **Virtual Device Manager**
6. Create an Android emulator

### Step 2.4: Run Flutter Doctor
```bash
flutter doctor
```

Fix any ❌ issues it shows. Common fixes:

```bash
# If Android licenses not accepted:
flutter doctor --android-licenses

# If Xcode tools missing:
xcode-select --install
```

Goal: See mostly ✅ checkmarks (some [!] warnings are okay)

---

## Part 3: Create Your Project

### Step 3.1: Create New Flutter Project
```bash
# Go to your development folder
cd ~/development

# Create the project
flutter create travel_app

# Enter the project
cd travel_app
```

### Step 3.2: Open in VS Code (Optional but Recommended)
```bash
# Install VS Code if you haven't
# Download from: https://code.visualstudio.com

# Open project in VS Code
code .
```

Install these VS Code extensions:
- **Flutter** (by Dart Code)
- **Dart** (by Dart Code)

---

## Part 4: Add Dependencies

### Step 4.1: Edit pubspec.yaml
Open `pubspec.yaml` in your project root.

Replace the `dependencies` section with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Supabase
  supabase_flutter: ^2.3.0
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Routing
  go_router: ^13.0.0
  
  # Maps
  google_maps_flutter: ^2.5.3
  
  # UI Helpers
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  
  # Environment
  flutter_dotenv: ^5.1.0
  
  # Utils
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### Step 4.2: Install Dependencies
```bash
flutter pub get
```

---

## Part 5: Set Up Environment Variables

### Step 5.1: Create .env File
In your project root:
```bash
touch .env
```

### Step 5.2: Add Your Keys
Open `.env` and add:
```env
SUPABASE_URL=<YOUR_SUPABASE_URL>
SUPABASE_ANON_KEY=<YOUR_SUPABASE_ANON_KEY>
GOOGLE_MAPS_API_KEY=<YOUR_GOOGLE_MAPS_KEY>
```

Replace `<...>` with your actual values from QUICKSTART_SUPABASE.md

### Step 5.3: Tell Flutter About .env
Open `pubspec.yaml` and add under `flutter:`:

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - .env
```

### Step 5.4: Add to .gitignore
Open `.gitignore` and add:
```gitignore
# Environment files with secrets
.env
.env.*
!.env.example
```

### Step 5.5: Create Example File
```bash
touch .env.example
```

Add to `.env.example`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
GOOGLE_MAPS_API_KEY=your-maps-key-here
```

---

## Part 6: Initialize Supabase

### Step 6.1: Replace main.dart
Open `lib/main.dart` and replace ALL content with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  // Run the app
  runApp(
    const ProviderScope(
      child: TravelApp(),
    ),
  );
}

// Global Supabase client access
final supabase = Supabase.instance.client;

class TravelApp extends ConsumerWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Travel App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
```

---

## Part 7: Set Up GoRouter

### Step 7.1: Create Router File
```bash
mkdir -p lib/core/routing
touch lib/core/routing/app_router.dart
```

### Step 7.2: Add Router Code
Open `lib/core/routing/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your screens (we'll create these)
import '../../features/map/screens/map_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/planner/screens/planner_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../shell/main_shell.dart';

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/map',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      
      // If going to protected route and not logged in
      // Add your protected routes here
      final protectedRoutes = ['/profile', '/feed/create'];
      final isProtected = protectedRoutes.any(
        (route) => state.matchedLocation.startsWith(route)
      );
      
      if (isProtected && !isLoggedIn) {
        return '/auth/login?redirect=${state.matchedLocation}';
      }
      
      // If logged in and going to auth route
      if (isLoggedIn && isAuthRoute) {
        return '/map';
      }
      
      return null;
    },
    routes: [
      // Main app with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Map Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          // Explore Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          // Planner Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (context, state) => const PlannerScreen(),
              ),
            ],
          ),
          // Feed Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          // Profile Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Auth routes (outside shell)
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
```

### Step 7.3: Create Main Shell (Bottom Navigation)
```bash
mkdir -p lib/core/shell
touch lib/core/shell/main_shell.dart
```

Open `lib/core/shell/main_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

---

## Part 8: Create Placeholder Screens

### Step 8.1: Create Feature Folders
```bash
mkdir -p lib/features/map/screens
mkdir -p lib/features/explore/screens
mkdir -p lib/features/planner/screens
mkdir -p lib/features/feed/screens
mkdir -p lib/features/profile/screens
mkdir -p lib/features/auth/screens
```

### Step 8.2: Create Each Screen
Create `lib/features/map/screens/map_screen.dart`:
```dart
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: const Center(child: Text('Map Screen - Coming Soon')),
    );
  }
}
```

Create `lib/features/explore/screens/explore_screen.dart`:
```dart
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: const Center(child: Text('Explore Screen - Coming Soon')),
    );
  }
}
```

Create `lib/features/planner/screens/planner_screen.dart`:
```dart
import 'package:flutter/material.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Planner')),
      body: const Center(child: Text('AI Planner - Coming Soon')),
    );
  }
}
```

Create `lib/features/feed/screens/feed_screen.dart`:
```dart
import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: const Center(child: Text('Feed Screen - Coming Soon')),
    );
  }
}
```

Create `lib/features/profile/screens/profile_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: user != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Logged in as: ${user.email}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      context.go('/auth/login');
                    }
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Not logged in'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/auth/login'),
                  child: const Text('Sign In'),
                ),
              ],
            ),
      ),
    );
  }
}
```

Create `lib/features/auth/screens/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        context.go('/map');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email to confirm!')),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _signUp,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

---

## Part 9: Configure iOS

### Step 9.1: Update Info.plist
Open `ios/Runner/Info.plist` and add these keys inside the `<dict>` tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby places and experiences.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to show nearby places and experiences.</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos for your posts.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images for your posts.</string>
```

### Step 9.2: Install Pods
```bash
cd ios
pod install
cd ..
```

---

## Part 10: Configure Android

### Step 10.1: Update Minimum SDK
Open `android/app/build.gradle` and find `defaultConfig`:

```gradle
defaultConfig {
    applicationId "com.example.travel_app"
    minSdkVersion 21  // Change from 16 to 21
    targetSdkVersion flutter.targetSdkVersion
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName
}
```

### Step 10.2: Add Permissions
Open `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

---

## Part 11: Run Your App!

### Step 11.1: Start iOS Simulator
```bash
open -a Simulator
```

### Step 11.2: Run the App
```bash
flutter run
```

### Step 11.3: What You Should See
1. App launches with bottom navigation
2. 5 tabs: Map, Explore, Plan, Feed, Profile
3. Profile tab shows "Not logged in" with Sign In button
4. Clicking Sign In goes to login screen
5. You can create an account and sign in

---

## Verification Checklist

### ✅ Flutter Installed
- [ ] `flutter --version` shows version
- [ ] `flutter doctor` shows mostly ✅

### ✅ Project Created
- [ ] Project folder exists
- [ ] `flutter pub get` ran successfully

### ✅ Environment Configured
- [ ] `.env` file created with keys
- [ ] `.env` added to pubspec.yaml assets
- [ ] `.env` added to .gitignore

### ✅ Code Files Created
- [ ] `main.dart` updated with Supabase init
- [ ] `app_router.dart` created with GoRouter
- [ ] `main_shell.dart` created with bottom nav
- [ ] All 6 screen files created

### ✅ Platform Configured
- [ ] iOS Info.plist updated
- [ ] iOS pods installed
- [ ] Android minSdkVersion set to 21
- [ ] Android permissions added

### ✅ App Runs
- [ ] App launches in simulator/emulator
- [ ] Bottom navigation works
- [ ] Auth flow works (sign up / sign in)

---

## Common Errors and Fixes

### Error 1: "Unable to load asset: .env"
**Cause:** .env not in pubspec.yaml assets
**Fix:** Add `.env` to assets in pubspec.yaml, then run `flutter pub get`

### Error 2: "Null check operator used on a null value" at startup
**Cause:** Environment variable missing from .env
**Fix:** Check .env has both SUPABASE_URL and SUPABASE_ANON_KEY

### Error 3: "MissingPluginException"
**Cause:** Native plugins not installed
**Fix:**
```bash
flutter clean
cd ios && pod install && cd ..
flutter run
```

### Error 4: "CocoaPods not installed"
**Cause:** CocoaPods missing
**Fix:**
```bash
sudo gem install cocoapods
cd ios && pod install && cd ..
```

### Error 5: "Gradle build failed"
**Cause:** Android build issues
**Fix:**
```bash
cd android && ./gradlew clean && cd ..
flutter clean
flutter run
```

### Error 6: "No connected devices"
**Cause:** No simulator/emulator running
**Fix:**
```bash
# For iOS
open -a Simulator

# For Android
flutter emulators
flutter emulators --launch <emulator_name>
```

### Error 7: "AuthException: Invalid login credentials"
**Cause:** Wrong email/password or user doesn't exist
**Fix:** Create a new account first using Sign Up

### Error 8: "GoRouter: No match found for location"
**Cause:** Route not defined in app_router.dart
**Fix:** Add the missing route to your GoRouter configuration

### Error 9: "Supabase: Connection refused"
**Cause:** Wrong SUPABASE_URL or network issues
**Fix:** 
1. Verify URL is correct (starts with https://)
2. Check internet connection
3. Check Supabase project is running

### Error 10: "minSdkVersion 16 cannot be smaller than 21"
**Cause:** Some packages require higher SDK
**Fix:** Change minSdkVersion to 21 in android/app/build.gradle

---

## Sprint 0 Run Checklist

Before moving to Sprint 1, verify:

- [ ] 1. Flutter installed and `flutter doctor` passing
- [ ] 2. Supabase project created and running
- [ ] 3. API keys obtained and saved in .env
- [ ] 4. Edge Function secrets configured
- [ ] 5. Database core tables created (users, cities)
- [ ] 6. Flutter project runs on simulator
- [ ] 7. Bottom navigation works (5 tabs)
- [ ] 8. Auth flow works (sign up, sign in, sign out)
- [ ] 9. GoRouter guards redirect correctly
- [ ] 10. No P0 errors in console

---

## Next Steps

Your foundation is complete! 🎉

Now proceed to **Sprint 1** in `IMPLEMENTATION_PLAN.md`:
- Map View with Google Maps
- Explore List with data from Supabase
- Experience & Stay detail screens

---

**Happy coding! 🚀**

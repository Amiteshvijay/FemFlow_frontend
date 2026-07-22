import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:FemLyra/core/theme/FemLyra_theme.dart';
import 'package:FemLyra/features/onboarding/onboarding_screen.dart';
import 'package:FemLyra/features/shell/main_shell.dart';
import 'package:FemLyra/features/auth/login_screen.dart';
import 'package:FemLyra/core/theme/FemLyra_colors.dart';
import 'package:FemLyra/core/security/app_lock_service.dart';
import 'package:FemLyra/features/app_lock/screens/unlock_screen.dart';
import 'package:FemLyra/features/app_lock/screens/secure_loading_screen.dart';
import 'package:FemLyra/shared/screens/maintenance_screen.dart';
import 'package:FemLyra/features/profile/wellness_onboarding_flow.dart';
import 'package:FemLyra/core/services/notification_service.dart';
import 'package:FemLyra/features/tips/providers/tips_provider.dart';
import 'package:FemLyra/features/subscriptions/providers/subscription_provider.dart';
import 'package:FemLyra/features/exercises/providers/exercise_provider.dart';
import 'package:FemLyra/core/services/deep_link_service.dart';
import 'package:FemLyra/core/services/background_sync_service.dart';
import 'package:FemLyra/core/navigation/navigator_service.dart';
import 'package:FemLyra/features/auth/providers/auth_provider.dart';
import 'package:FemLyra/features/onboarding/brand_splash_screen.dart';
import 'package:FemLyra/features/lab_tests/providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize Deep Links
  await DeepLinkService().init();

  // Initialize Background Tasks
  await BackgroundSyncService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLockService()),
        ChangeNotifierProvider(create: (_) => TipsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProxyProvider<SubscriptionProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, sub, auth) => auth!..updateSubscriptionProvider(sub),
        ),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => LabCartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pass lifecycle changes to AppLockService
    context.read<AppLockService>().handleAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FemLyra',
      navigatorKey: NavigatorService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: FemLyraTheme.lightTheme,
      home: const AuthGate(),
      builder: (context, child) {
        return Consumer<AppLockService>(
          builder: (context, appLock, _) {
            if (appLock.isInitializing) {
              return const SecureLoadingScreen();
            }

            if (appLock.isLocked) {
              NotificationService.isLocked = true;
              return const UnlockScreen();
            }

            NotificationService.isLocked = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService.checkPendingNotification();
              DeepLinkService().checkPendingDynamicLink();
            });

            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showBrandSplash = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AuthProvider>().checkAuth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showBrandSplash) {
      return BrandSplashScreen(onFinished: () {
        setState(() {
          _showBrandSplash = false;
        });
      });
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.maintenance) {
          NotificationService.isAuthenticated = false;
          return MaintenanceScreen(onRetry: () => auth.checkAuth());
        }

        if (auth.status == AuthStatus.loading) {
          return const Scaffold(
            backgroundColor: FemLyraColors.warmWhite,
            body: Center(
              child: CircularProgressIndicator(color: FemLyraColors.primary),
            ),
          );
        }

        if (auth.status == AuthStatus.unauthenticated) {
          NotificationService.isAuthenticated = false;
          if (auth.onboardingCompleted) {
            return const LoginScreen();
          }
          return const OnboardingScreen();
        }

        // authenticated
        final profile = auth.profile;
        if (profile != null && profile.onboardingCompleted == false) {
          NotificationService.isAuthenticated = false;
          return WellnessOnboardingFlow(
            initialProfile: profile,
            initialPage: profile.onboardingCurrentStep,
            onComplete: () => auth.checkAuth(),
          );
        }

        NotificationService.isAuthenticated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.checkPendingNotification();
        });
        return const MainShell();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:femflow/core/theme/femflow_theme.dart';
import 'package:femflow/features/onboarding/onboarding_screen.dart';
import 'package:femflow/features/shell/main_shell.dart';
import 'package:femflow/features/auth/login_screen.dart';
import 'package:femflow/core/theme/femflow_colors.dart';
import 'package:femflow/core/security/app_lock_service.dart';
import 'package:femflow/features/app_lock/screens/unlock_screen.dart';
import 'package:femflow/features/app_lock/screens/secure_loading_screen.dart';
import 'package:femflow/shared/screens/maintenance_screen.dart';
import 'package:femflow/features/profile/wellness_onboarding_flow.dart';
import 'package:femflow/core/services/notification_service.dart';
import 'package:femflow/features/tips/providers/tips_provider.dart';
import 'package:femflow/features/subscriptions/providers/subscription_provider.dart';
import 'package:femflow/features/exercises/providers/exercise_provider.dart';
import 'package:femflow/features/sync/cloud_sync_service.dart';
import 'package:femflow/core/services/deep_link_service.dart';
import 'package:femflow/core/services/background_sync_service.dart';
import 'package:femflow/core/navigation/navigator_service.dart';
import 'package:femflow/features/auth/providers/auth_provider.dart';

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
        ChangeNotifierProxyProvider<AppLockService, CloudSyncService>(
          create: (_) => CloudSyncService(),
          update: (_, appLock, sync) => sync!..setAppLock(appLock),
        ),
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
      title: 'FemFlow',
      navigatorKey: NavigatorService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: FemFlowTheme.lightTheme,
      home: const AuthGate(),
      builder: (context, child) {
        return Consumer<AppLockService>(
          builder: (context, appLock, _) {
            if (appLock.isInitializing) {
              return const SecureLoadingScreen();
            }

            if (appLock.isLocked) {
              return const UnlockScreen();
            }

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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.maintenance) {
          return MaintenanceScreen(onRetry: () => auth.checkAuth());
        }

        if (auth.status == AuthStatus.loading) {
          return const Scaffold(
            backgroundColor: FemFlowColors.warmWhite,
            body: Center(
              child: CircularProgressIndicator(color: FemFlowColors.primary),
            ),
          );
        }

        if (auth.status == AuthStatus.unauthenticated) {
          if (auth.onboardingCompleted) {
            return const LoginScreen();
          }
          return const OnboardingScreen();
        }

        // authenticated
        final profile = auth.profile;
        if (profile != null && profile.onboardingCompleted == false) {
          return WellnessOnboardingFlow(
            initialProfile: profile,
            initialPage: profile.onboardingCurrentStep,
            onComplete: () => auth.checkAuth(),
          );
        }

        return const MainShell();
      },
    );
  }
}

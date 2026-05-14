import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/archive_map_screen.dart';
import 'screens/dictionary_screen.dart';
import 'screens/learning_hub_screen.dart';
import 'screens/learning_path_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/main_layout.dart';
import 'screens/contributor_screen.dart';
import 'screens/validator_home_screen.dart';
import 'screens/validator_entries_screen.dart';
import 'screens/validator_voices_screen.dart';
import 'screens/validator_lessons_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/community_feed_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/login_screen.dart';
import 'models/artifact.dart';
import 'screens/signup_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/admin_overview_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_content_screen.dart';
import 'screens/admin_requests_screen.dart';
import 'screens/admin_map_architect_screen.dart';
import 'screens/admin_gamification_screen.dart';
import 'screens/admin_advanced_analytics_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/ancestral_vault_shop_screen.dart';
import 'screens/artifact_detail_screen.dart';
import 'screens/lesson_session_screen.dart';
import 'screens/educator_dashboard_screen.dart';
import 'screens/educator_lessons_screen.dart';
import 'screens/educator_students_screen.dart';
import 'screens/educator_analytics_screen.dart';
import 'screens/lesson_editor_screen.dart';
import 'screens/educator_unit_management_screen.dart';
import 'screens/member_profile_screen.dart';
import 'screens/scenario_hub_screen.dart';
import 'screens/scenario_session_screen.dart';
import 'screens/lingua_duel_screen.dart';
import 'screens/mastery_dashboard_screen.dart';
import 'screens/warriors_circle_screen.dart';
import 'screens/streak_history_screen.dart';
import 'screens/saka_game_screen.dart';

import 'providers/role_provider.dart';

import 'services/offline_service.dart';
import 'services/notification_service.dart';
import 'widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 9: True Edge-to-Edge UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Error Boundary
  GlobalErrorBoundary.init();

  final offlineService = OfflineService();

  // Initialize Services in parallel or robustly
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv Load Error: $e");
  }

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint("Supabase Initialization Error: $e");
  }

  try {
    await offlineService.init();
    await NotificationService().init();
  } catch (e) {
    debugPrint("Service Initialization Error: $e");
  }

  runApp(
    ProviderScope(
      overrides: [offlineServiceProvider.overrideWithValue(offlineService)],
      child: const LumadLinguaApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/onboarding',
  redirect: (context, state) {
    try {
      final container = ProviderScope.containerOf(context);
      final role = container.read(roleProvider);
      final loc = state.uri.toString();
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;

      if (isLoggedIn &&
          (loc == '/onboarding' || loc == '/login' || loc == '/signup')) {
        return '/';
      }

      // Block unauthorized routes
      if (loc.startsWith('/admin') && role != UserRole.admin) {
        return '/';
      }
      if ((loc.startsWith('/validate') || loc.startsWith('/validator')) &&
          role != UserRole.validator &&
          role != UserRole.admin) {
        return '/';
      }
      if (loc.startsWith('/contribute') &&
          role != UserRole.contributor &&
          role != UserRole.admin) {
        return '/';
      }
      if (loc.startsWith('/educator') &&
          role != UserRole.educator &&
          role != UserRole.admin) {
        return '/';
      }
    } catch (e) {
      // Ignore errors if ProviderScope is not ready
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const ArchiveMapScreen(),
        ),
        GoRoute(
          path: '/dictionary',
          builder: (context, state) => const DictionaryScreen(),
        ),
        GoRoute(
          path: '/learning',
          builder: (context, state) => const LearningHubScreen(),
        ),
        GoRoute(
          path: '/learning/path',
          builder: (context, state) => const LearningPathScreen(),
        ),
        GoRoute(
          path: '/learning/quiz',
          builder: (context, state) => const QuizScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/member/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return MemberProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/gallery',
          builder: (context, state) => const GalleryScreen(),
        ),
        GoRoute(
          path: '/community-feed',
          builder: (context, state) => const CommunityFeedScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/contribute',
          builder: (context, state) => const ContributorScreen(),
        ),
        GoRoute(
          path: '/validator/home',
          builder: (context, state) => const ValidatorHomeScreen(),
        ),
        GoRoute(
          path: '/validator/entries',
          builder: (context, state) => const ValidatorEntriesScreen(),
        ),
        GoRoute(
          path: '/validator/voices',
          builder: (context, state) => const ValidatorVoicesScreen(),
        ),
        GoRoute(
          path: '/validator/lessons',
          builder: (context, state) => const ValidatorLessonsScreen(),
        ),
        GoRoute(
          path: '/admin',
          redirect: (context, state) => '/admin/overview',
        ),
        GoRoute(
          path: '/admin/overview',
          builder: (context, state) => const AdminOverviewScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: '/admin/content',
          builder: (context, state) => const AdminContentScreen(),
        ),
        GoRoute(
          path: '/admin/requests',
          builder: (context, state) => const AdminRequestsScreen(),
        ),
        GoRoute(
          path: '/admin/map-architect',
          builder: (context, state) => const AdminMapArchitectScreen(),
        ),
        GoRoute(
          path: '/admin/gamification',
          builder: (context, state) => const AdminGamificationScreen(),
        ),
        GoRoute(
          path: '/admin/analytics',
          builder: (context, state) => const AdminAdvancedAnalyticsScreen(),
        ),
        GoRoute(
          path: '/educator/dashboard',
          builder: (context, state) => const EducatorDashboardScreen(),
        ),
        GoRoute(
          path: '/educator/lessons',
          builder: (context, state) => const EducatorLessonsScreen(),
        ),
        GoRoute(
          path: '/educator/students',
          builder: (context, state) => const EducatorStudentsScreen(),
        ),
        GoRoute(
          path: '/educator/analytics',
          builder: (context, state) => const EducatorAnalyticsScreen(),
        ),
        GoRoute(
          path: '/educator/unit-management',
          builder: (context, state) => const EducatorUnitManagementScreen(),
        ),
        GoRoute(
          path: '/lesson-editor',
          builder: (context, state) {
            final lessonId = state.extra as String?;
            return LessonEditorScreen(lessonId: lessonId);
          },
        ),
        GoRoute(
          path: '/lesson_session',
          builder: (context, state) => const LessonSessionScreen(),
        ),
        GoRoute(
          path: '/artifact-detail',
          builder: (context, state) {
            final artifact = state.extra as Artifact;
            return ArtifactDetailScreen(artifact: artifact);
          },
        ),
        GoRoute(
          path: '/achievements',
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: '/ancestral-vault-shop',
          builder: (context, state) => const AncestralVaultShopScreen(),
        ),
        GoRoute(
          path: '/scenario-hub',
          builder: (context, state) => const ScenarioHubScreen(),
        ),
        GoRoute(
          path: '/scenario-session/:scenarioId',
          builder: (context, state) {
            final id = state.pathParameters['scenarioId']!;
            return ScenarioSessionScreen(scenarioId: id);
          },
        ),
        GoRoute(
          path: '/lingua-duel',
          builder: (context, state) => const LinguaDuelScreen(),
        ),
        GoRoute(
          path: '/mastery-dashboard',
          builder: (context, state) => const MasteryDashboardScreen(),
        ),
        GoRoute(
          path: '/warriors-circle',
          builder: (context, state) => const WarriorsCircleScreen(),
        ),
        GoRoute(
          path: '/streak',
          builder: (context, state) => const StreakHistoryScreen(),
        ),
        GoRoute(
          path: '/saka-game',
          builder: (context, state) => const SakaGameScreen(),
        ),
      ],
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/flashcards',
      builder: (context, state) => const FlashcardsScreen(),
    ),
  ],
);

class LumadLinguaApp extends ConsumerWidget {
  const LumadLinguaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: 'Lumad Lingua',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: data.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: AnimatedTheme(
            data: themeMode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: child!,
          ),
        );
      },
    );
  }
}




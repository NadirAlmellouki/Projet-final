import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/profile_setup_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/onboarding/intro_walkthrough_screen.dart';
import '../../presentation/screens/chat/chat_room_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/profile/profile_edit_screen.dart';
import '../../presentation/screens/rating/rating_screen.dart';
import '../../presentation/screens/sessions/create_session_screen.dart';
import '../../presentation/screens/sessions/my_sessions_screen.dart';
import '../../presentation/screens/sessions/session_detail_screen.dart';
import '../../presentation/screens/shell/main_shell_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../domain/entities/study_session.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const intro = '/intro';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const createSession = '/create-session';
  static const chatRoom = '/chat';
<<<<<<< HEAD
  static const rating = '/rating';
=======
  static const sessionDetail = '/session';
  static const mySessions = '/my-sessions';
>>>>>>> 11b14c6 (nadir lah yehdik rah mashi lfront dyali hadik)
  static const profile = '/profile';
  static const profileEdit = '/profile-edit';
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

String? _authRedirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authProvider);
  final path = state.matchedLocation;
  final status = auth.status;
  final user = auth.user;

  final isSplash = path == AppRoutes.splash;
  final isPublicRoute = path == AppRoutes.login ||
      path == AppRoutes.register ||
      path == AppRoutes.onboarding ||
      path == AppRoutes.intro ||
      path == AppRoutes.forgotPassword ||
      path.startsWith(AppRoutes.resetPassword);

  final isResetPassword = path.startsWith(AppRoutes.resetPassword);

  if (status == AuthStatus.unknown) {
    if (isResetPassword) return null;
    return isSplash ? null : AppRoutes.splash;
  }

  if (status == AuthStatus.unauthenticated) {
    if (isResetPassword) return null;
    if (isSplash || !isPublicRoute) {
      return AppRoutes.onboarding;
    }
    return null;
  }

  if (status == AuthStatus.authenticated) {
    if (isResetPassword) return null;
    if (user?.needsProfileSetup == true && path != AppRoutes.profileSetup) {
      return AppRoutes.profileSetup;
    }
    if (isSplash || isPublicRoute || path == AppRoutes.onboarding) {
      return AppRoutes.home;
    }
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _authRedirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.intro,
        builder: (_, __) => const IntroWalkthroughScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const MainShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.createSession,
        builder: (_, __) => const CreateSessionScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.chatRoom}/:sessionId',
        builder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          final title = state.extra as String? ?? 'Session';
          return ChatRoomScreen(sessionId: id, sessionTitle: title);
        },
      ),
      GoRoute(
<<<<<<< HEAD
        path: '${AppRoutes.rating}/:sessionId',
        builder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          final title = state.extra as String? ?? 'Session';
          return RatingScreen(sessionId: id, sessionTitle: title);
        },
      ),
      GoRoute(
=======
        path: '${AppRoutes.sessionDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final session = state.extra as StudySession?;
          return SessionDetailScreen(sessionId: id, session: session);
        },
      ),
      GoRoute(
        path: AppRoutes.mySessions,
        builder: (_, __) => const MySessionsScreen(),
      ),
      GoRoute(
>>>>>>> 11b14c6 (nadir lah yehdik rah mashi lfront dyali hadik)
        path: AppRoutes.profileEdit,
        builder: (_, __) => const ProfileEditScreen(),
      ),
    ],
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';

class StudySyncApp extends ConsumerStatefulWidget {
  const StudySyncApp({super.key});

  @override
  ConsumerState<StudySyncApp> createState() => _StudySyncAppState();
}

class _StudySyncAppState extends ConsumerState<StudySyncApp> {
  @override
  void initState() {
    super.initState();
    // Auth check APRÈS le premier frame — évite l'erreur Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAuth());
  }

  Future<void> _bootstrapAuth() async {
    try {
      await ref
          .read(authProvider.notifier)
          .checkAuthOnStartup()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      ref.read(authProvider.notifier).markUnauthenticated();
    }

    if (ref.read(authProvider).status == AuthStatus.unknown) {
      ref.read(authProvider.notifier).markUnauthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.read(routerProvider);

    return MaterialApp.router(
      title: 'StudySync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

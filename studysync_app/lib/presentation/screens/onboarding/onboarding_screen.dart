import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Page d'accueil : « Commencer » → intro 3 étapes ; « J'ai déjà un compte » → connexion.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.groups, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              Text('StudySync', style: AppTheme.brandTitle(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Trouve des partenaires d\'étude\nprès de toi, en temps réel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(
                      'Trouve tes partenaires',
                      style: AppTheme.brandTitle(18).copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Même matière, même endroit, même moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.intro),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4F46E5),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Commencer →'),
              ),
              const SizedBox(height: 8),
              GhostButton(
                label: 'J\'ai déjà un compte',
                light: true,
                onPressed: () => context.go(AppRoutes.login),
              ),
            ],
        ),
      ),
    );
  }
}

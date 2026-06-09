import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class IntroWalkthroughScreen extends StatefulWidget {
  const IntroWalkthroughScreen({super.key});

  @override
  State<IntroWalkthroughScreen> createState() => _IntroWalkthroughScreenState();
}

class _IntroWalkthroughScreenState extends State<IntroWalkthroughScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    (
      emoji: '📚',
      title: 'Trouve tes partenaires',
      subtitle: 'Même matière, même endroit, même moment.',
    ),
    (
      emoji: '🗺️',
      title: 'Sessions près de toi',
      subtitle: 'Carte en temps réel des groupes d\'étude autour de toi.',
    ),
    (
      emoji: '💬',
      title: 'Échange et progresse',
      subtitle: 'Chat de session, stats et profil de confiance.',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      context.go(AppRoutes.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    GhostButton(
                      label: '← Retour',
                      light: true,
                      fullWidth: false,
                      onPressed: () => context.go(AppRoutes.onboarding),
                    ),
                    const Spacer(),
                    if (_page < _slides.length - 1)
                      TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: Text(
                          'Passer',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('StudySync', style: AppTheme.brandTitle(22)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(slide.emoji, style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: AppTheme.brandTitle(20).copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    _page < _slides.length - 1
                        ? 'Suivant →'
                        : 'Créer mon compte →',
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

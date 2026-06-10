import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/studysync_widgets.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final userId = ref.read(authProvider).user?.id;
    if (userId != null) {
      ref.read(statsProvider.notifier).load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);
    final user = ref.watch(authProvider).user;
    final stats = state.stats;

    final trust = stats?.trustScore ?? user?.trustScore;
    final trustLabel = trust != null && trust > 0
        ? '${trust.toStringAsFixed(1)}/5'
        : '—';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: state.isLoading && stats == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => _reload(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ScreenHeroHeader(
                        eyebrow: 'Performance',
                        title: 'Tes statistiques',
                        subtitle: user?.fullName ?? '',
                        icon: Icons.bar_chart_rounded,
                      ),
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.35,
                          children: [
                            StatCard(
                              value: '${stats?.sessionCount ?? 0}',
                              label: 'Mes sessions',
                              icon: Icons.event_note_rounded,
                              accentIndex: 0,
                            ),
                            StatCard(
                              value: stats?.averageRating != null &&
                                      stats!.averageRating! > 0
                                  ? '${stats.averageRating!.toStringAsFixed(1)}★'
                                  : '—',
                              label: 'Note moyenne',
                              icon: Icons.star_rounded,
                              accentIndex: 1,
                            ),
                            StatCard(
                              value: '${stats?.ratingCount ?? 0}',
                              label: 'Avis reçus',
                              icon: Icons.rate_review_rounded,
                              accentIndex: 2,
                            ),
                            StatCard(
                              value: trustLabel,
                              label: 'Trust score',
                              icon: Icons.verified_rounded,
                              accentIndex: 3,
                            ),
                            StatCard(
                              value: '${stats?.partnersCount ?? 0}',
                              label: 'Partenaires',
                              icon: Icons.people_rounded,
                              accentIndex: 4,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppSurfaceCard(
                          margin: EdgeInsets.zero,
                          accentColor: AppColors.accent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conseil',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Participe à plus de sessions et reçois des avis pour améliorer ton trust score.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.text2,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
<<<<<<< HEAD
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: state.isLoading ? null : _reload,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Actualiser'),
                          ),
                        ),
=======
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.fullName ?? '',
                      style: const TextStyle(color: AppColors.text2),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                value: '${stats?.sessionCount ?? 0}',
                                label: 'Mes sessions',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                value: stats?.averageRating != null &&
                                        stats!.averageRating! > 0
                                    ? '${stats.averageRating!.toStringAsFixed(1)}★'
                                    : '—',
                                label: 'Note moyenne',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                value: '${stats?.ratingCount ?? 0}',
                                label: 'Avis reçus',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                value: trustLabel,
                                label: 'Trust score',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                value: '${stats?.partnersCount ?? 0}',
                                label: 'Partenaires',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: state.isLoading ? null : _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser'),
>>>>>>> 11b14c6 (nadir lah yehdik rah mashi lfront dyali hadik)
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

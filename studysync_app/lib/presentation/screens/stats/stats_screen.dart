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
      appBar: AppBar(title: const Text('Stats')),
      body: state.isLoading && stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    Text(
                      'Ton activité',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.fullName ?? '',
                      style: const TextStyle(color: AppColors.text2),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.5,
                      children: [
                        StatCard(
                          value: '${stats?.sessionCount ?? 0}',
                          label: 'Mes sessions',
                        ),
                        StatCard(
                          value: stats?.averageRating != null &&
                                  stats!.averageRating! > 0
                              ? '${stats.averageRating!.toStringAsFixed(1)}★'
                              : '—',
                          label: 'Note moyenne',
                        ),
                        StatCard(
                          value: '${stats?.ratingCount ?? 0}',
                          label: 'Avis reçus',
                        ),
                        StatCard(
                          value: trustLabel,
                          label: 'Trust score',
                        ),
                        StatCard(
                          value: '${stats?.partnersCount ?? 0}',
                          label: 'Partenaires',
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

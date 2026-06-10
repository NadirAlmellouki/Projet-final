import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/study_session.dart';
import '../../providers/home_provider.dart';
import '../../widgets/report_sheet.dart';
import '../../widgets/studysync_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeFeedProvider.notifier).loadSessions();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final created = await context.push<bool>(AppRoutes.createSession);
    if (created == true && mounted) {
      ref.read(homeFeedProvider.notifier).loadSessions();
    }
  }

  Future<void> _reportSession(StudySession session) async {
    final sent = await ReportSheet.show(
      context,
      targetType: ReportTargetType.session,
      targetLabel: session.subject,
      reportedSessionId: session.id,
      reportedUserId: session.creatorId,
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    }
  }

  Future<void> _join(String sessionId, String subject) async {
    final ok = await ref.read(homeFeedProvider.notifier).joinSession(sessionId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Vous avez rejoint « $subject »'
              : ref.read(homeFeedProvider).errorMessage ?? 'Erreur join',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(homeFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Créer'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeroHeader(
              eyebrow: 'Bonjour 👋',
              title: 'Sessions près de vous',
              icon: Icons.explore_rounded,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (v) =>
                    ref.read(homeFeedProvider.notifier).setSearchQuery(v),
                decoration: InputDecoration(
                  hintText: 'Calcul, Biologie, CS101...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody(feed)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(HomeFeedState feed) {
    if (feed.isLoading && feed.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feed.errorMessage != null && feed.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feed.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(homeFeedProvider.notifier).loadSessions(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (feed.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aucune session disponible.',
                style: TextStyle(color: AppColors.text2),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _openCreate,
                child: const Text('Créer la première session'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(homeFeedProvider.notifier).loadSessions(
            subject: feed.searchQuery.isEmpty ? null : feed.searchQuery,
          ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: feed.sessions.length,
        itemBuilder: (context, index) {
          final session = feed.sessions[index];
          return SessionCard(
            creatorInitials: session.creatorInitials,
            creatorName: session.creatorName,
            subject: session.subject,
            subtitle: [
              if (session.topic != null) session.topic,
              if (session.locationName != null) session.locationName,
            ].whereType<String>().join(' · '),
            matchScore: session.matchScore,
            distanceKm: session.distanceKm,
            isActiveNow: session.isActiveNow,
            memberRole: session.memberRole,
            onJoin: session.isParticipant
                ? null
                : () => _join(session.id, session.subject),
            onOpenChat: session.isParticipant
                ? () => context.push(
                      '${AppRoutes.chatRoom}/${session.id}',
                      extra: session.subject,
                    )
                : null,
            onReport: session.isParticipant
                ? () => _reportSession(session)
                : null,
          );
        },
      ),
    );
  }
}

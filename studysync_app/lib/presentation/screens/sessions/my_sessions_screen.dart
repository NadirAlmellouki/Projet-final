import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/study_session.dart';
import '../../providers/app_providers.dart';
import '../../widgets/studysync_widgets.dart';

class MySessionsScreen extends ConsumerStatefulWidget {
  const MySessionsScreen({super.key});

  @override
  ConsumerState<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends ConsumerState<MySessionsScreen> {
  List<StudySession>? _sessions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final sessions =
          await ref.read(sessionRepositoryProvider).getMySessions();
      if (mounted) setState(() { _sessions = sessions; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Mes sessions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _sessions == null || _sessions!.isEmpty
                  ? const Center(
                      child: Text('Vous n\'avez pas encore de sessions.',
                          style: TextStyle(color: AppColors.text2)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions!.length,
                        itemBuilder: (context, index) {
                          final s = _sessions![index];
                          return SessionCard(
                            creatorInitials: s.creatorInitials,
                            creatorName: s.creatorName,
                            subject: s.subject,
                            subtitle: [
                              if (s.topic != null) s.topic,
                              if (s.locationName != null) s.locationName,
                            ].whereType<String>().join(' · '),
                            matchScore: s.matchScore,
                            distanceKm: s.distanceKm,
                            isActiveNow: s.isActiveNow,
                            onTap: () => context.push(
                                '${AppRoutes.sessionDetail}/${s.id}',
                                extra: s),
                            onJoin: () async {
                              try {
                                await ref
                                    .read(sessionRepositoryProvider)
                                    .joinSession(s.id);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Vous avez rejoint « ${s.subject} »')),
                                );
                                context.push(
                                  '${AppRoutes.chatRoom}/${s.id}',
                                  extra: s.subject,
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $e')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

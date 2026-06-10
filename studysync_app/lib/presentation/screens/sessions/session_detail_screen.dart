import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/study_session.dart';
import '../../providers/app_providers.dart';
import '../../widgets/studysync_widgets.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    this.session,
  });

  final String sessionId;
  final StudySession? session;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  StudySession? _session;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _session = widget.session;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final s = await ref
          .read(sessionRepositoryProvider)
          .getSessionById(widget.sessionId);
      if (mounted) setState(() { _session = s; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _join() async {
    try {
      await ref
          .read(sessionRepositoryProvider)
          .joinSession(widget.sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez rejoint la session')),
      );
      context.push('${AppRoutes.chatRoom}/${widget.sessionId}',
          extra: _session?.subject);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  ChipVariant _statusVariant(String status) {
    return switch (status) {
      'active' => ChipVariant.green,
      'full' => ChipVariant.primary,
      _ => ChipVariant.gray,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Détails de la session')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                  ),
                )
              : s == null
                  ? const Center(child: Text('Session introuvable'))
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.subject,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                if (s.topic != null)
                                  Text(s.topic!,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.text2)),
                                const SizedBox(height: 16),
                                Row(children: [
                                  UserAvatar(
                                      initials: s.creatorInitials, size: 40),
                                  const SizedBox(width: 10),
                                  Text(s.creatorName,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ]),
                                const SizedBox(height: 16),
                                _infoRow(Icons.place, s.locationName ?? ''),
                                if (s.startTime != null)
                                  _infoRow(
                                      Icons.schedule,
                                      DateFormat("dd/MM/yyyy 'à' HH:mm")
                                          .format(s.startTime!)),
                                _infoRow(Icons.timer,
                                    '${s.durationMinutes} min'),
                                _infoRow(
                                    Icons.people,
                                    '${s.participantCount ?? 1} / ${s.maxParticipants} participants'),
                                const SizedBox(height: 8),
                                SessionChip(
                                    label: s.status,
                                    variant: _statusVariant(s.status)),
                                if (s.distanceKm != null) ...[
                                  const SizedBox(height: 4),
                                  SessionChip(
                                      label:
                                          '📍 ${s.distanceKm!.toStringAsFixed(1)} km',
                                      variant: ChipVariant.gray),
                                ],
                                if (s.matchScore != null) ...[
                                  const SizedBox(height: 4),
                                  MatchScoreBadge(score: s.matchScore!),
                                ],
                                if (s.description != null) ...[
                                  const SizedBox(height: 16),
                                  const Text('Description',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text3)),
                                  const SizedBox(height: 4),
                                  Text(s.description!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.text2,
                                          height: 1.6)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _join,
                                  child: const Text('Rejoindre'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => context.push(
                                      '${AppRoutes.chatRoom}/${widget.sessionId}',
                                      extra: s.subject),
                                  child: const Text('Ouvrir le Chat'),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.text3),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.text2)),
      ]),
    );
  }
}

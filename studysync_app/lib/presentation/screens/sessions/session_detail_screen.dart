import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/location_helper.dart';
import '../../../domain/entities/session_member_role.dart';
import '../../../domain/entities/study_session.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/report_sheet.dart';
import '../../widgets/studysync_widgets.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    this.initialSession,
  });

  final String sessionId;
  final StudySession? initialSession;

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  StudySession? _session;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final pos = await LocationHelper.getCurrentOrDefault();
      var session = await ref.read(sessionRepositoryProvider).getSessionById(
            widget.sessionId,
            latitude: pos.lat,
            longitude: pos.lng,
          );

      final mySessions = await ref.read(sessionRepositoryProvider).getMySessions();
      final myIds = mySessions.map((s) => s.id).toSet();
      final userId = ref.read(authProvider).user?.id;

      final enriched = enrichSessionsMembership(
        sessions: [session],
        userId: userId,
        mySessionIds: myIds,
      );
      session = enriched.first;

      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _join() async {
    final session = _session;
    if (session == null) return;
    final ok = await ref.read(homeFeedProvider.notifier).joinSession(session.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Vous avez rejoint « ${session.subject} »'
              : ref.read(homeFeedProvider).errorMessage ?? 'Impossible de rejoindre',
        ),
      ),
    );
    if (ok) await _load();
  }

  Future<void> _report() async {
    final session = _session;
    if (session == null) return;
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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd/MM/yyyy à HH:mm').format(dt);
  }

  String _statusLabel(String status) => switch (status) {
        'created' => 'Ouverte',
        'completed' => 'Terminée',
        'cancelled' => 'Annulée',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final dateFmt = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading && session == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null && session == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : session == null
                  ? const SizedBox.shrink()
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 160,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              session.subject,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            background: Container(
                              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                                ),
                              Row(
                                children: [
                                  UserAvatar(initials: session.creatorInitials, size: 52),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session.creatorName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Créateur de la session',
                                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (session.matchScore != null)
                                    MatchScoreBadge(score: session.matchScore!),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  SessionChip(
                                    label: _statusLabel(session.status),
                                    variant: ChipVariant.primary,
                                  ),
                                  if (session.isActiveNow)
                                    const SessionChip(label: 'En cours', variant: ChipVariant.green),
                                  if (session.memberRole == SessionMemberRole.creator)
                                    const SessionChip(label: 'Créateur', variant: ChipVariant.primary),
                                  if (session.memberRole == SessionMemberRole.member)
                                    const SessionChip(label: 'Membre', variant: ChipVariant.green),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _DetailSection(
                                title: 'Horaires',
                                rows: [
                                  _DetailRow(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Début',
                                    value: _formatDateTime(session.startTime),
                                  ),
                                  _DetailRow(
                                    icon: Icons.schedule_rounded,
                                    label: 'Fin',
                                    value: session.endTime != null
                                        ? _formatDateTime(session.endTime)
                                        : '—',
                                  ),
                                  _DetailRow(
                                    icon: Icons.timelapse_rounded,
                                    label: 'Durée',
                                    value: '${session.durationMinutes} minutes',
                                  ),
                                  if (session.startTime != null && session.endTime != null)
                                    _DetailRow(
                                      icon: Icons.access_time_rounded,
                                      label: 'Plage',
                                      value:
                                          '${dateFmt.format(session.startTime!)} – ${dateFmt.format(session.endTime!)}',
                                    ),
                                ],
                              ),
                              _DetailSection(
                                title: 'Lieu',
                                rows: [
                                  _DetailRow(
                                    icon: Icons.place_rounded,
                                    label: 'Adresse',
                                    value: session.locationName ?? 'Non précisé',
                                  ),
                                  if (session.distanceKm != null)
                                    _DetailRow(
                                      icon: Icons.near_me_rounded,
                                      label: 'Distance',
                                      value: '${session.distanceKm!.toStringAsFixed(1)} km',
                                    ),
                                  if (session.hasLocation)
                                    _DetailRow(
                                      icon: Icons.map_rounded,
                                      label: 'Coordonnées',
                                      value:
                                          '${session.latitude!.toStringAsFixed(4)}, ${session.longitude!.toStringAsFixed(4)}',
                                    ),
                                ],
                              ),
                              _DetailSection(
                                title: 'Session',
                                rows: [
                                  if (session.topic != null && session.topic!.isNotEmpty)
                                    _DetailRow(
                                      icon: Icons.menu_book_rounded,
                                      label: 'Sujet / chapitre',
                                      value: session.topic!,
                                    ),
                                  _DetailRow(
                                    icon: Icons.groups_rounded,
                                    label: 'Participants',
                                    value:
                                        '${session.participantCount ?? 1} / ${session.maxParticipants}',
                                  ),
                                  _DetailRow(
                                    icon: Icons.info_outline_rounded,
                                    label: 'Statut',
                                    value: _statusLabel(session.status),
                                  ),
                                ],
                              ),
                              if (session.description != null && session.description!.trim().isNotEmpty)
                                AppSurfaceCard(
                                  accentColor: AppColors.accent,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Description',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        session.description!,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.text2,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                              if (session.isParticipant) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.push(
                                      '${AppRoutes.chatRoom}/${session.id}',
                                      extra: session.subject,
                                    ),
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: const Text('Ouvrir le chat'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (session.memberRole == SessionMemberRole.member)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _report,
                                      icon: const Icon(Icons.flag_outlined),
                                      label: const Text('Signaler la session'),
                                    ),
                                  ),
                              ] else
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _join,
                                    icon: const Icon(Icons.group_add_rounded),
                                    label: const Text('Rejoindre la session'),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text1,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void openSessionDetail(BuildContext context, StudySession session) {
  context.push(
    '${AppRoutes.sessionDetail}/${session.id}',
    extra: session,
  );
}

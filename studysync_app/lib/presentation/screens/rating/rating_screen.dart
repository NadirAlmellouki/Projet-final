import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/create_rating_request.dart';
import '../../../domain/entities/session_participant.dart';
import '../../../domain/entities/session_detail.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/studysync_widgets.dart';

class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({
    super.key,
    required this.sessionId,
    this.sessionTitle,
  });

  final String sessionId;
  final String? sessionTitle;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _ParticipantRatingDraft {
  int overall = 0;
  int punctuality = 0;
  int engagement = 0;
  bool? wouldStudyAgain;
  final commentCtrl = TextEditingController();
  bool submitted = false;
  bool submitting = false;
  String? error;
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  SessionDetail? _detail;
  bool _loading = true;
  String? _loadError;
  final Map<String, _ParticipantRatingDraft> _drafts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final draft in _drafts.values) {
      draft.commentCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final detail =
          await ref.read(ratingRepositoryProvider).getSessionDetail(widget.sessionId);
      final userId = ref.read(authProvider).user?.id;
      final others = detail.participants
          .where((p) => p.userId != userId)
          .toList();

      if (!detail.session.isEnded) {
        setState(() {
          _detail = detail;
          _loading = false;
          _loadError =
              'Les évaluations sont disponibles après la fin de la session.';
        });
        return;
      }

      for (final p in others) {
        _drafts.putIfAbsent(p.userId, _ParticipantRatingDraft.new);
      }

      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _submitParticipant(SessionParticipant participant) async {
    final draft = _drafts[participant.userId];
    if (draft == null || draft.submitted || draft.submitting) return;

    if (draft.overall < 1) {
      setState(() => draft.error = 'Choisis une note globale (1 à 5 étoiles).');
      return;
    }

    setState(() {
      draft.submitting = true;
      draft.error = null;
    });

    try {
      await ref.read(ratingRepositoryProvider).submitRating(
            CreateRatingRequest(
              sessionId: widget.sessionId,
              ratedId: participant.userId,
              score: draft.overall,
              punctualityScore:
                  draft.punctuality > 0 ? draft.punctuality : null,
              engagementScore: draft.engagement > 0 ? draft.engagement : null,
              wouldStudyAgain: draft.wouldStudyAgain,
              comment: draft.commentCtrl.text,
            ),
          );
      if (!mounted) return;
      setState(() {
        draft.submitting = false;
        draft.submitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Évaluation envoyée pour ${participant.fullName}.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        draft.submitting = false;
        if (e.statusCode == 409) {
          draft.submitted = true;
          draft.error = null;
        } else {
          draft.error = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        draft.submitting = false;
        draft.error = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.sessionTitle ??
        _detail?.session.subject ??
        'Évaluation';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _loadError != null
              ? EmptyStateView(
                  icon: Icons.star_outline_rounded,
                  title: 'Évaluation indisponible',
                  message: _loadError!,
                  action: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    final userId = ref.watch(authProvider).user?.id;
    final participants =
        detail.participants.where((p) => p.userId != userId).toList();

    if (participants.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline,
        title: 'Aucun participant',
        message: 'Il n\'y a personne d\'autre à évaluer dans cette session.',
        action: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour'),
        ),
      );
    }

    final allDone = participants.every((p) => _drafts[p.userId]?.submitted == true);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session terminée',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Évalue chaque partenaire pour renforcer la confiance.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...participants.map(_buildParticipantCard),
        if (allDone) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Terminer'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildParticipantCard(SessionParticipant participant) {
    final draft = _drafts[participant.userId]!;

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      accentColor: draft.submitted ? AppColors.success : AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(initials: participant.initials, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.fullName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1,
                      ),
                    ),
                    if (participant.trustScore != null &&
                        participant.trustScore! > 0)
                      Text(
                        'Trust ${participant.trustScore!.toStringAsFixed(1)}/5',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.text3,
                        ),
                      ),
                  ],
                ),
              ),
              if (draft.submitted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successTint,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Envoyé',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!draft.submitted) ...[
            const SizedBox(height: 16),
            _RatingLabel('Note globale'),
            StarRatingRow(
              value: draft.overall,
              onChanged: (v) => setState(() => draft.overall = v),
            ),
            const SizedBox(height: 12),
            _RatingLabel('Ponctualité'),
            StarRatingRow(
              value: draft.punctuality,
              onChanged: (v) => setState(() => draft.punctuality = v),
            ),
            const SizedBox(height: 12),
            _RatingLabel('Engagement'),
            StarRatingRow(
              value: draft.engagement,
              onChanged: (v) => setState(() => draft.engagement = v),
            ),
            const SizedBox(height: 14),
            _RatingLabel('Repartir étudier ensemble ?'),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Oui'),
                  selected: draft.wouldStudyAgain == true,
                  onSelected: (_) =>
                      setState(() => draft.wouldStudyAgain = true),
                  selectedColor: AppColors.accentTint,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Non'),
                  selected: draft.wouldStudyAgain == false,
                  onSelected: (_) =>
                      setState(() => draft.wouldStudyAgain = false),
                  selectedColor: AppColors.errorTint,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.commentCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Commentaire (optionnel)',
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            if (draft.error != null) ...[
              const SizedBox(height: 8),
              Text(
                draft.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: draft.submitting
                    ? null
                    : () => _submitParticipant(participant),
                child: draft.submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Envoyer l\'évaluation'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingLabel extends StatelessWidget {
  const _RatingLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.text2,
      ),
    );
  }
}

class StarRatingRow extends StatelessWidget {
  const StarRatingRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () => onChanged(star),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? const Color(0xFFFDCB6E) : AppColors.text3,
            size: 28,
          ),
        );
      }),
    );
  }
}

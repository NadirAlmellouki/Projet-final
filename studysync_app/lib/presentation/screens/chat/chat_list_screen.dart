import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/home_provider.dart';
import '../sessions/session_detail_screen.dart';
import '../../widgets/report_sheet.dart';
import '../../widgets/studysync_widgets.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeroHeader(
              eyebrow: 'Messagerie',
              title: 'Vos conversations',
              subtitle: 'Sessions rejointes ou créées',
              icon: Icons.chat_bubble_rounded,
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : state.sessions.isEmpty
                      ? EmptyState(
                          icon: Icons.forum_outlined,
                          title: 'Aucune conversation',
                          message: state.errorMessage ??
                              'Créez une session ou rejoignez-en une pour discuter avec les participants.',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => ref.read(chatListProvider.notifier).load(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                            itemCount: state.sessions.length,
                            itemBuilder: (context, index) {
                              final s = state.sessions[index];
                              final subtitle = [
                                if (s.locationName != null && s.locationName!.isNotEmpty)
                                  s.locationName,
                                if (s.startTime != null)
                                  DateFormat('dd/MM HH:mm').format(s.startTime!),
                                '${s.participantCount ?? 1} participant(s)',
                              ].whereType<String>().join(' · ');

                              return ChatSessionTile(
                                initials: s.creatorInitials,
                                subject: s.subject,
                                subtitle: subtitle,
                                onTap: () => openSessionDetail(context, s),
                                onReport: () async {
                                  final sent = await ReportSheet.show(
                                    context,
                                    targetType: ReportTargetType.session,
                                    targetLabel: s.subject,
                                    reportedSessionId: s.id,
                                    reportedUserId: s.creatorId,
                                  );
                                  if (sent == true && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Signalement envoyé. Merci.'),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

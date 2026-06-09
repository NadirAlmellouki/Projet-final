import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/home_provider.dart';

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
      appBar: AppBar(title: const Text('Chat')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.sessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.errorMessage ??
                          'Créez une session ou rejoignez-en une pour discuter avec les participants.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.text2),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(chatListProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.sessions.length,
                    itemBuilder: (context, index) {
                      final s = state.sessions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryTint,
                            child: Text(
                              s.creatorInitials,
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                          title: Text(s.subject),
                          subtitle: Text(
                            [
                              if (s.locationName != null && s.locationName!.isNotEmpty)
                                s.locationName,
                              if (s.startTime != null)
                                DateFormat('dd/MM HH:mm').format(s.startTime!),
                              '${s.participantCount ?? 1} participant(s)',
                            ].whereType<String>().join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                            '${AppRoutes.chatRoom}/${s.id}',
                            extra: s.subject,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../../domain/entities/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
<<<<<<< HEAD
import '../../widgets/report_sheet.dart';
=======
import '../../widgets/rating_dialog.dart';
>>>>>>> 11b14c6 (nadir lah yehdik rah mashi lfront dyali hadik)

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  final String sessionId;
  final String sessionTitle;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  ChatRoomNotifier? _notifier;
  bool _sessionEnded = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier = ref.read(chatRoomProvider(widget.sessionId).notifier);
      _notifier!.load();
      _notifier!.startPolling();
      _loadSessionStatus();
    });
  }

  Future<void> _loadSessionStatus() async {
    try {
      final detail = await ref
          .read(ratingRepositoryProvider)
          .getSessionDetail(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _sessionEnded = detail.session.isEnded;
        _checkingSession = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checkingSession = false);
    }
  }

  void _openRating() {
    context.push(
      '${AppRoutes.rating}/${widget.sessionId}',
      extra: widget.sessionTitle,
    );
  }

  @override
  void dispose() {
    _notifier?.stopPolling();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

<<<<<<< HEAD
  Future<void> _reportSession() async {
    final sent = await ReportSheet.show(
      context,
      targetType: ReportTargetType.session,
      targetLabel: widget.sessionTitle,
      reportedSessionId: widget.sessionId,
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    }
  }

  Future<void> _reportMessage(ChatMessage message) async {
    final sent = await ReportSheet.show(
      context,
      targetType: ReportTargetType.message,
      targetLabel: 'Message de ${message.senderName}',
      reportedMessageId: message.id,
      reportedUserId: message.senderId,
      reportedSessionId: widget.sessionId,
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    }
=======
  void _openRatingDialog() {
    final currentUserId = ref.read(authProvider).user?.id ?? '';
    final messages = ref.read(chatRoomProvider(widget.sessionId)).messages;
    final participants = <String, String>{};
    for (final m in messages) {
      if (m.senderId != currentUserId) {
        participants[m.senderId] = m.senderName;
      }
    }
    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun autre participant à noter')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Noter un participant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...participants.entries.map((e) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(e.value),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => RatingDialog(
                        sessionId: widget.sessionId,
                        rateeId: e.key,
                        rateeName: e.value,
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
>>>>>>> 11b14c6 (nadir lah yehdik rah mashi lfront dyali hadik)
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final ok =
        await ref.read(chatRoomProvider(widget.sessionId).notifier).send(text);
    if (ok) {
      _ctrl.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomProvider(widget.sessionId));
    final userId = ref.watch(authProvider).user?.id ?? '';

    ref.listen(chatRoomProvider(widget.sessionId), (prev, next) {
      if (next.messages.length > (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF8B7CF6),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          widget.sessionTitle,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'report_session') _reportSession();
              if (value == 'rate_session') _openRating();
            },
            itemBuilder: (_) => [
              if (_sessionEnded)
                const PopupMenuItem(
                  value: 'rate_session',
                  child: Row(
                    children: [
                      Icon(Icons.star_outline_rounded,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Évaluer les participants'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'report_session',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Signaler la session'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
<<<<<<< HEAD
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
=======
            icon: const Icon(Icons.star_outline),
            tooltip: 'Noter un participant',
            onPressed: _openRatingDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
>>>>>>> 11b14c6 (nadir lah yehdik rah mashi lfront dyali hadik)
            onPressed: () =>
                ref.read(chatRoomProvider(widget.sessionId).notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_sessionEnded && !_checkingSession)
            Material(
              color: AppColors.accentTint,
              child: InkWell(
                onTap: _openRating,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.accentDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Session terminée — évalue tes partenaires',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentDark,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.accentDark),
                    ],
                  ),
                ),
              ),
            ),
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              color: AppColors.errorTint,
              padding: const EdgeInsets.all(10),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Aucun message. Écrivez le premier message de cette session.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.text2,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) {
                          final m = state.messages[i];
                          final mine = m.isMine(userId);
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress:
                                  mine ? null : () => _reportMessage(m),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.78,
                                ),
                                decoration: BoxDecoration(
                                  gradient: mine
                                      ? AppColors.chatBubbleMine
                                      : null,
                                  color: mine ? null : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(mine ? 18 : 4),
                                    bottomRight: Radius.circular(mine ? 4 : 18),
                                  ),
                                  border: mine
                                      ? null
                                      : Border.all(color: AppColors.border),
                                  boxShadow: mine
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: mine
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!mine)
                                      Text(
                                        m.senderName,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    Text(
                                      m.content,
                                      style: GoogleFonts.inter(
                                        color: mine
                                            ? Colors.white
                                            : AppColors.text1,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('HH:mm').format(m.sentAt),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: mine
                                            ? Colors.white70
                                            : AppColors.text3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: InputDecoration(
                          hintText: 'Écrire un message…',
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: state.isSending ? null : _send,
                        icon: state.isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

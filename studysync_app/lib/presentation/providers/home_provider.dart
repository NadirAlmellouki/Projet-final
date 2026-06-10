import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/app_config.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/chat_message_model.dart';
import 'auth_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/session_member_role.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/user_stats.dart';
import 'app_providers.dart';

List<StudySession> enrichSessionsMembership({
  required List<StudySession> sessions,
  required String? userId,
  required Set<String> mySessionIds,
}) {
  return sessions.map((session) {
    if (userId != null &&
        session.creatorId != null &&
        session.creatorId == userId) {
      return session.copyWith(memberRole: SessionMemberRole.creator);
    }
    if (mySessionIds.contains(session.id)) {
      return session.copyWith(memberRole: SessionMemberRole.member);
    }
    return session.copyWith(memberRole: SessionMemberRole.none);
  }).toList();
}

class HomeFeedState {
  const HomeFeedState({
    this.sessions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  final List<StudySession> sessions;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  HomeFeedState copyWith({
    List<StudySession>? sessions,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool clearError = false,
  }) {
    return HomeFeedState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class HomeFeedNotifier extends StateNotifier<HomeFeedState> {
  HomeFeedNotifier(this._ref) : super(const HomeFeedState());

  final Ref _ref;

  Future<void> loadSessions({String? subject}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessionRepo = _ref.read(sessionRepositoryProvider);
      final pos = await LocationHelper.getCurrentOrDefault();

      List<StudySession> sessions;
      try {
        sessions = await sessionRepo.getRecommendedSessions(
          latitude: pos.lat,
          longitude: pos.lng,
        );
      } catch (_) {
        sessions = await sessionRepo.listSessions(
          latitude: pos.lat,
          longitude: pos.lng,
          subject: subject,
        );
      }

      if (sessions.isEmpty) {
        sessions = await sessionRepo.listSessions(subject: subject);
      }

      if (subject != null && subject.isNotEmpty) {
        final q = subject.toLowerCase();
        sessions = sessions
            .where(
              (s) =>
                  s.subject.toLowerCase().contains(q) ||
                  (s.topic?.toLowerCase().contains(q) ?? false),
            )
            .toList();
      }

      final mySessions =
          await _ref.read(sessionRepositoryProvider).getMySessions();
      final myIds = mySessions.map((s) => s.id).toSet();
      final userId = _ref.read(authProvider).user?.id;
      sessions = enrichSessionsMembership(
        sessions: sessions,
        userId: userId,
        mySessionIds: myIds,
      );

      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> joinSession(String sessionId) async {
    try {
      await _ref.read(sessionRepositoryProvider).joinSession(sessionId);
      final updated = state.sessions.map((s) {
        if (s.id != sessionId) return s;
        return s.copyWith(memberRole: SessionMemberRole.member);
      }).toList();
      state = state.copyWith(sessions: updated, clearError: true);
      await loadSessions(subject: state.searchQuery.isEmpty ? null : state.searchQuery);
      await _ref.read(chatListProvider.notifier).load();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadSessions(subject: query.isEmpty ? null : query);
  }
}

final homeFeedProvider =
    StateNotifierProvider<HomeFeedNotifier, HomeFeedState>((ref) {
  return HomeFeedNotifier(ref);
});

class MapSessionsState {
  const MapSessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.userLat,
    this.userLng,
    this.errorMessage,
  });

  final List<StudySession> sessions;
  final bool isLoading;
  final double? userLat;
  final double? userLng;
  final String? errorMessage;
}

class MapSessionsNotifier extends StateNotifier<MapSessionsState> {
  MapSessionsNotifier(this._ref) : super(const MapSessionsState());

  final Ref _ref;

  Future<void> load() async {
    state = const MapSessionsState(isLoading: true);
    try {
      final pos = await LocationHelper.getCurrentOrDefault();
      final sessionRepo = _ref.read(sessionRepositoryProvider);
      final sessions = await sessionRepo.listSessions(
        latitude: pos.lat,
        longitude: pos.lng,
      );
      final mySessions = await sessionRepo.getMySessions();
      final myIds = mySessions.map((s) => s.id).toSet();
      final userId = _ref.read(authProvider).user?.id;
      final enriched = enrichSessionsMembership(
        sessions: sessions,
        userId: userId,
        mySessionIds: myIds,
      );
      state = MapSessionsState(
        sessions: enriched.where((s) => s.hasLocation).toList(),
        userLat: pos.lat,
        userLng: pos.lng,
      );
    } catch (e) {
      state = MapSessionsState(errorMessage: e.toString());
    }
  }
}

final mapSessionsProvider =
    StateNotifierProvider<MapSessionsNotifier, MapSessionsState>((ref) {
  return MapSessionsNotifier(ref);
});

class ChatListState {
  const ChatListState({
    this.sessions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<StudySession> sessions;
  final bool isLoading;
  final String? errorMessage;
}

class ChatListNotifier extends StateNotifier<ChatListState> {
  ChatListNotifier(this._ref) : super(const ChatListState());

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessions = await _ref.read(sessionRepositoryProvider).getMySessions();
      state = ChatListState(sessions: sessions);
    } catch (e) {
      state = ChatListState(errorMessage: e.toString());
    }
  }
}

extension on ChatListState {
  ChatListState copyWith({
    List<StudySession>? sessions,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatListState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier(ref);
});

class ChatRoomState {
  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  ChatRoomNotifier(this._ref, this.sessionId) : super(const ChatRoomState());

  final Ref _ref;
  final String sessionId;
  Timer? _pollTimer;
  io.Socket? _socket;
  bool _disposed = false;

  void startPolling() {
    _connectSocket();
  }

  void stopPolling() {
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    final s = _socket;
    _socket = null;
    s?.disconnect();
  }

  void _connectSocket() {
    try {
      final tokenStorage = _ref.read(tokenStorageProvider);
      tokenStorage.readToken().then((token) {
        if (_disposed) return;
        final socket = io.io(AppConfig.baseUrl, <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
          'auth': {'token': token},
        });
        _socket = socket;
        socket.connect();
        socket.emit('join_session', {'session_id': sessionId});
        socket.on('new_message', (data) {
          if (_disposed) return;
          if (data is Map) {
            try {
              final msg = ChatMessageModel.fromJson(
                  Map<String, dynamic>.from(data));
              if (!state.messages.any((m) => m.id == msg.id)) {
                state = ChatRoomState(messages: [...state.messages, msg]);
              }
            } catch (_) {}
          }
        });
        socket.onDisconnect((_) {
          if (_disposed) return;
          _startFallbackPolling();
        });
        socket.onConnectError((_) {
          if (_disposed) return;
          _startFallbackPolling();
        });
      });
    } catch (_) {
      if (!_disposed) _startFallbackPolling();
    }
  }

  void _startFallbackPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
          if (_disposed) {
            _pollTimer?.cancel();
            return;
          }
          load(silent: true);
        });
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> load({bool silent = false}) async {
    if (_disposed) return;
    if (!silent) {
      state = ChatRoomState(messages: state.messages, isLoading: true);
    }
    try {
      final messages =
          await _ref.read(chatRepositoryProvider).getMessages(sessionId);
      if (_disposed) return;
      state = ChatRoomState(messages: messages);
    } catch (e) {
      if (_disposed) return;
      if (!silent) {
        state = ChatRoomState(errorMessage: e.toString());
      }
    }
  }

  Future<bool> send(String content) async {
    if (_disposed) return false;
    state = ChatRoomState(messages: state.messages, isSending: true);
    try {
      final msg =
          await _ref.read(chatRepositoryProvider).sendMessage(sessionId, content);
      if (_disposed) return false;
      state = ChatRoomState(messages: [...state.messages, msg]);
      await load(silent: true);
      return true;
    } catch (e) {
      if (_disposed) return false;
      state = ChatRoomState(
        messages: state.messages,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final chatRoomProvider = StateNotifierProvider.family<ChatRoomNotifier,
    ChatRoomState, String>((ref, sessionId) {
  return ChatRoomNotifier(ref, sessionId);
});

class StatsState {
  const StatsState({
    this.stats,
    this.isLoading = false,
    this.errorMessage,
  });

  final UserStats? stats;
  final bool isLoading;
  final String? errorMessage;
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier(this._ref) : super(const StatsState());

  final Ref _ref;

  Future<void> load(String userId) async {
    state = const StatsState(isLoading: true);
    try {
      final user = _ref.read(authProvider).user;
      final stats = await _ref.read(statsRepositoryProvider).getUserStats(
            userId,
            trustScore: user?.trustScore,
          );
      state = StatsState(stats: stats);
    } catch (e) {
      state = StatsState(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref);
});

class ProfileStatsState {
  const ProfileStatsState({
    this.sessionCount = 0,
    this.partnersCount = 0,
    this.averageRating,
    this.ratingCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final int sessionCount;
  final int partnersCount;
  final double? averageRating;
  final int ratingCount;
  final bool isLoading;
  final String? errorMessage;
}

class ProfileStatsNotifier extends StateNotifier<ProfileStatsState> {
  ProfileStatsNotifier(this._ref) : super(const ProfileStatsState());

  final Ref _ref;

  Future<void> load() async {
    state = const ProfileStatsState(isLoading: true);
    try {
      final userId = _ref.read(authProvider).user?.id;
      if (userId == null) {
        state = const ProfileStatsState();
        return;
      }
      final user = _ref.read(authProvider).user;
      final stats = await _ref.read(statsRepositoryProvider).getUserStats(
            userId,
            trustScore: user?.trustScore,
          );
      state = ProfileStatsState(
        sessionCount: stats.sessionCount,
        partnersCount: stats.partnersCount,
        averageRating: stats.averageRating,
        ratingCount: stats.ratingCount,
        isLoading: false,
      );
    } catch (e) {
      state = ProfileStatsState(errorMessage: e.toString());
    }
  }
}

final profileStatsProvider =
    StateNotifierProvider<ProfileStatsNotifier, ProfileStatsState>((ref) {
  return ProfileStatsNotifier(ref);
});

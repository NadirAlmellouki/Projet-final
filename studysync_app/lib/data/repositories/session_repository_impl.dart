import '../../application/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/chat_message_model.dart';
import '../models/study_session_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/create_session_request.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({required ApiService api}) : _api = api;

  final ApiService _api;

  List<StudySession> _parseSessions(dynamic data) {
    if (data is! Map) return [];
    final list = data['sessions'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => StudySessionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  StudySession _parseOne(dynamic data) {
    if (data is Map && data['session'] is Map) {
      return StudySessionModel.fromJson(
        Map<String, dynamic>.from(data['session'] as Map),
      );
    }
    if (data is Map) {
      return StudySessionModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Session invalide');
  }

  @override
  Future<List<StudySession>> getRecommendedSessions({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) async {
    final response = await _api.get(
      ApiEndpoints.matchesRecommend,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusKm,
      },
    );
    return _parseSessions(response.data);
  }

  @override
  Future<List<StudySession>> listSessions({
    double? latitude,
    double? longitude,
    String? subject,
  }) async {
    final response = await _api.get(
      ApiEndpoints.sessions,
      queryParameters: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
      },
    );
    return _parseSessions(response.data);
  }

  @override
  Future<List<StudySession>> getMySessions() async {
    final response = await _api.get(ApiEndpoints.sessionsMine);
    return _parseSessions(response.data);
  }

  @override
  Future<StudySession> getSessionById(
    String sessionId, {
    double? latitude,
    double? longitude,
  }) async {
    final response = await _api.get(
      ApiEndpoints.sessionById(sessionId),
      queryParameters: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    final data = response.data;
    if (data is! Map) throw Exception('Session invalide');

    final map = Map<String, dynamic>.from(data);
    StudySession session;
    if (map['session'] is Map) {
      session = StudySessionModel.fromJson(
        Map<String, dynamic>.from(map['session'] as Map),
      );
    } else {
      session = StudySessionModel.fromJson(map);
    }

    final matchScore = double.tryParse('${map['match_score']}');
    if (matchScore != null) {
      session = session.copyWith(matchScore: matchScore);
    }

    final participants = map['participants'];
    if (participants is List && participants.isNotEmpty) {
      session = session.copyWith(participantCount: participants.length);
    }

    return session;
  }

  @override
  Future<StudySession> createSession(CreateSessionRequest request) async {
    final response = await _api.post(
      ApiEndpoints.sessions,
      data: request.toJson(),
    );
    return _parseOne(response.data);
  }

  @override
  Future<void> joinSession(String sessionId, {String? message}) async {
    await _api.post(
      ApiEndpoints.sessionJoin(sessionId),
      data: {if (message != null) 'message': message},
    );
  }

  @override
  Future<List<StudySession>> getNearbySessions({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.get(
      ApiEndpoints.matchesNearby,
      queryParameters: {'latitude': latitude, 'longitude': longitude},
    );
    return _parseSessions(response.data);
  }
}

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ApiService api}) : _api = api;

  final ApiService _api;

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final response = await _api.get(ApiEndpoints.sessionMessages(sessionId));
    final data = response.data;
    if (data is! Map) return [];
    final list = data['messages'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(String sessionId, String content) async {
    final response = await _api.post(
      ApiEndpoints.sessionMessages(sessionId),
      data: {'content': content},
    );
    final data = response.data;
    if (data is Map && data['message'] is Map) {
      return ChatMessageModel.fromJson(
        Map<String, dynamic>.from(data['message'] as Map),
      );
    }
    throw Exception('Réponse message invalide');
  }
}

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl({required ApiService api}) : _api = api;

  final ApiService _api;

  @override
  Future<UserStats> getUserStats(String userId, {double? trustScore}) async {
    final sessions = await SessionRepositoryImpl(api: _api).getMySessions();

    double? avg;
    var count = 0;
    try {
      final ratingsRes = await _api.get(ApiEndpoints.userRatings(userId));
      final ratingsData = ratingsRes.data;
      if (ratingsData is Map) {
        avg = double.tryParse('${ratingsData['average_score']}');
        count = int.tryParse('${ratingsData['ratings_count']}') ?? 0;
        if ((avg == null || avg == 0) && trustScore != null && trustScore > 0) {
          avg = trustScore;
        }
      }
    } catch (_) {
      if (trustScore != null && trustScore > 0) {
        avg = trustScore;
      }
    }

    var partners = 0;
    for (final s in sessions) {
      final n = s.participantCount ?? 1;
      partners += n > 1 ? n - 1 : 0;
    }

    return UserStats(
      sessionCount: sessions.length,
      averageRating: avg,
      ratingCount: count,
      trustScore: trustScore,
      partnersCount: partners,
    );
  }
}

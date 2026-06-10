import '../entities/chat_message.dart';
import '../entities/create_session_request.dart';
import '../entities/study_session.dart';
import '../entities/user_stats.dart';

abstract class SessionRepository {
  Future<List<StudySession>> getRecommendedSessions({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  });

  Future<List<StudySession>> listSessions({
    double? latitude,
    double? longitude,
    String? subject,
  });

  Future<List<StudySession>> getMySessions();
  Future<StudySession> getSessionById(
    String sessionId, {
    double? latitude,
    double? longitude,
  });
  Future<StudySession> createSession(CreateSessionRequest request);
  Future<void> joinSession(String sessionId, {String? message});
  Future<List<StudySession>> getNearbySessions({
    required double latitude,
    required double longitude,
  });
}

abstract class ChatRepository {
  Future<List<ChatMessage>> getMessages(String sessionId);
  Future<ChatMessage> sendMessage(String sessionId, String content);
}

abstract class StatsRepository {
  Future<UserStats> getUserStats(String userId, {double? trustScore});
}

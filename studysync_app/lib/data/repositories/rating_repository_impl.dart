import '../../application/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/session_participant_model.dart';
import '../../data/models/study_session_model.dart';
import '../../domain/entities/create_rating_request.dart';
import '../../domain/entities/rating_summary.dart';
import '../../domain/entities/session_detail.dart';
import '../../domain/repositories/rating_repository.dart';

class RatingRepositoryImpl implements RatingRepository {
  RatingRepositoryImpl({required ApiService api}) : _api = api;

  final ApiService _api;

  @override
  Future<SessionDetail> getSessionDetail(String sessionId) async {
    final response = await _api.get(ApiEndpoints.sessionById(sessionId));
    final data = response.data;
    if (data is! Map) throw ApiException(message: 'Session invalide');

    final sessionJson = data['session'];
    if (sessionJson is! Map) {
      throw ApiException(message: 'Session introuvable');
    }

    final session = StudySessionModel.fromJson(
      Map<String, dynamic>.from(sessionJson),
    );

    final participantsRaw = data['participants'];
    final participants = participantsRaw is List
        ? participantsRaw
            .whereType<Map>()
            .map(
              (e) => SessionParticipantModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .where((p) => p.userId.isNotEmpty)
            .toList()
        : <SessionParticipantModel>[];

    return SessionDetail(session: session, participants: participants);
  }

  @override
  Future<double?> submitRating(CreateRatingRequest request) async {
    try {
      final response = await _api.post(
        ApiEndpoints.ratings,
        data: request.toJson(),
      );
      final data = response.data;
      if (data is Map && data['new_trust_score'] != null) {
        return double.tryParse('${data['new_trust_score']}');
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw ApiException(
          message: 'Vous avez déjà noté ce participant pour cette session.',
          statusCode: 409,
        );
      }
      rethrow;
    }
  }

  @override
  Future<RatingSummary> getUserRatings(String userId) async {
    final response = await _api.get(ApiEndpoints.userRatings(userId));
    final data = response.data;
    if (data is! Map) {
      return RatingSummary(userId: userId, averageScore: 0, ratingsCount: 0);
    }

    return RatingSummary(
      userId: userId,
      averageScore: double.tryParse('${data['average_score']}') ?? 0,
      ratingsCount: int.tryParse('${data['ratings_count']}') ?? 0,
    );
  }
}
